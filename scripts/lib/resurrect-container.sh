#!/usr/bin/env bash
# Script: resurrect-container.sh
# Purpose: Container startup and health verification (Phases 2-4)
# Guardian: The Archivist
#!/usr/bin/env bash
# Script: resurrect-container.sh
# Purpose: Container startup and health verification (Phases 2-4)
# Guardian: The Archivist
# Date: 12/13/2025
# Consciousness: 4.7

run_container_resurrection() {
  log_info "Phase 2: Container Resurrection (5 min)"

  cd "$WORK_DIR" || exit

  log_info "Pulling latest jacobalberty/unifi:latest image..."
  if ! docker pull jacobalberty/unifi:latest; then
    log_error "Failed to pull image. Check Docker daemon and network."
  fi
  log_success "Image pulled successfully"

  log_info "Starting container (docker compose up -d)..."
  if ! docker compose up -d; then
    log_error "Failed to start container"
  fi
  log_success "Container started"

  log_info "Waiting for container to initialize (up to ${MAX_RETRIES}s)..."
  ATTEMPT=0
  while ((ATTEMPT < MAX_RETRIES)); do
    CONTAINER_STATE=$(docker container inspect unifi-controller --format='{{.State.Running}}' 2>/dev/null || echo "false")

    if [[ "$CONTAINER_STATE" == "true" ]]; then
      log_success "Container is running"
      break
    fi

    log_warn "Container starting... ($ATTEMPT/$MAX_RETRIES)"
    sleep "$RETRY_DELAY"
    ((ATTEMPT++))
  done

  if [[ "$CONTAINER_STATE" != "true" ]]; then
    log_error "Container failed to start after ${MAX_RETRIES}s"
  fi
}

run_health_verification() {
  log_info "Phase 3: Health Verification (5 min)"

  log_info "Waiting for port $CONTROLLER_PORT to be open..."
  ATTEMPT=0
  while ((ATTEMPT < MAX_RETRIES)); do
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$CONTROLLER_IP/$CONTROLLER_PORT" 2>/dev/null; then
      log_success "Port $CONTROLLER_PORT is open"
      break
    fi

    log_warn "Port not open yet... ($ATTEMPT/$MAX_RETRIES)"
    sleep "$RETRY_DELAY"
    ((ATTEMPT++))
  done

  if ! timeout 2 bash -c "cat < /dev/null > /dev/tcp/$CONTROLLER_IP/$CONTROLLER_PORT" 2>/dev/null; then
    log_warn "Port $CONTROLLER_PORT still not open, but checking /status endpoint anyway..."
  fi

  log_info "Verifying controller /status endpoint..."
  ATTEMPT=0
  while ((ATTEMPT < MAX_RETRIES)); do
    if curl -sf -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status" &>/dev/null; then
      STATUS_RESPONSE=$(curl -s -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status")
      log_success "Controller is healthy"
      echo "   Response: $STATUS_RESPONSE"
      break
    fi

    log_warn "Endpoint not responding yet... ($ATTEMPT/$MAX_RETRIES)"
    sleep "$RETRY_DELAY"
    ((ATTEMPT++))
  done

  if ! curl -sf -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status" &>/dev/null; then
    log_warn "Endpoint not responding yet, but container is running"
  fi
}

run_final_verification() {
  log_info "Phase 4: Final Verification"

  CONTAINER_STATE=$(docker inspect unifi-controller --format='{{.State.Running}}' 2>/dev/null || echo "false")
  CONTAINER_HEALTH=$(docker inspect unifi-controller --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")

  log_success "Container state: $CONTAINER_STATE"
  log_success "Container health: $CONTAINER_HEALTH"

  if docker exec unifi-controller ss -tlnp 2>/dev/null | grep -q ":8443"; then
    log_success "Port 8443 is listening inside container"
  fi

  log_info "Last 5 log lines:"
  docker logs --tail 5 unifi-controller | sed 's/^/  /'
}

export -f run_container_resurrection run_health_verification run_final_verification
