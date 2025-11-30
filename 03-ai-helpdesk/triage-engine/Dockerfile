# AI Helpdesk Triage Engine - Docker Image
# Target: <120 MB (production requirement)
# Multi-stage build for minimal size

# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Download spaCy model
RUN python -m spacy download en_core_web_sm

# Stage 2: Runtime
FROM python:3.11-slim

LABEL maintainer="hellodeolu-era systems architecture"
LABEL version="5.0"
LABEL description="AI-augmented helpdesk triage engine with Llama 3.3 70B + Presidio PII redaction"

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY main.py .

# Set PATH for pip-installed binaries
ENV PATH=/root/.local/bin:$PATH

# Environment variables (override at runtime)
ENV OLLAMA_HOST=http://host.docker.internal:11434
ENV OLLAMA_MODEL=llama3.3:70b
ENV OSTICKET_URL=http://10.0.30.40
ENV AUTO_CLOSE_THRESHOLD=0.93
ENV PYTHONUNBUFFERED=1

# Expose FastAPI port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health').raise_for_status()"

# Run FastAPI with Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
