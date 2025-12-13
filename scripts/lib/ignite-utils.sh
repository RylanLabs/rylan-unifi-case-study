#!/usr/bin/env bash
# Script: ignite-utils.sh
# Purpose: Logging utilities for ignite.sh orchestrator
# Guardian: The Namer
# Date: 12/13/2025
# Consciousness: 4.7

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
  local level=$1; shift
  case "$level" in
    phase)   echo -e "${BLUE}==============================================================================${NC}\n${GREEN}[TRINITY]${NC} $*\n${BLUE}==============================================================================${NC}" ;;
    step)    echo -e "${GREEN}[TRINITY]${NC} $*" ;;
    error)   echo -e "${RED}[TRINITY-ERROR]${NC} $*" ;;
    warn)    echo -e "${YELLOW}[TRINITY-WARN]${NC} $*" ;;
    success) echo -e "${GREEN}[TRINITY-SUCCESS]${NC} $*" ;;
  esac
}

exit_handler() {
  local exit_code=$?
  local end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  
  if [[ $exit_code -eq 0 ]]; then
    log success "Trinity orchestration COMPLETE (${duration}s)"
  else
    log error "Trinity orchestration FAILED with exit code $exit_code"
  fi
  
  exit "$exit_code"
}

trap exit_handler EXIT

export -f log exit_handler
