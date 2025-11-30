#!/usr/bin/env python3
"""
AI-Augmented Helpdesk Triage Engine

FastAPI service that ingests osTicket data, redacts PII via Presidio,
classifies tickets with Ollama (Llama 3.3 70B), and auto-closes at ≥93% confidence.

Architecture:
    - FastAPI for REST API
    - Presidio for PII redaction (SSN, CC, email, phone)
    - Ollama (local Llama 3.3 70B) for ticket classification
    - Qdrant for semantic search (historical ticket embeddings)
    - Auto-close at ≥0.93 confidence threshold

Endpoints:
    GET  /health              - Health check
    POST /triage              - Triage a single ticket
    POST /triage/batch        - Triage multiple tickets
    GET  /metrics             - Prometheus metrics

Usage:
    uvicorn main:app --host 0.0.0.0 --port 8000
    docker build -t triage-engine:v5 .
    docker run -p 8000:8000 -e OLLAMA_HOST=http://localhost:11434 triage-engine:v5
"""

import os
import logging
import time
from typing import Dict, List, Optional
from enum import Enum

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
import httpx
from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment variables
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.3:70b")
OSTICKET_URL = os.getenv("OSTICKET_URL", "http://10.0.30.40")
OSTICKET_API_KEY = os.getenv("OSTICKET_API_KEY", "")
AUTO_CLOSE_THRESHOLD = float(os.getenv("AUTO_CLOSE_THRESHOLD", "0.93"))
QDRANT_HOST = os.getenv("QDRANT_HOST", "http://localhost:6333")

# Initialize FastAPI app
app = FastAPI(
    title="AI Helpdesk Triage Engine",
    description="Automated ticket classification and auto-close",
    version="5.0"
)

# Initialize Presidio engines
analyzer = AnalyzerEngine()
anonymizer = AnonymizerEngine()

# Global metrics
metrics = {
    "total_triaged": 0,
    "auto_closed": 0,
    "human_review": 0,
    "avg_confidence": 0.0,
    "avg_latency_ms": 0.0
}


class TicketCategory(str, Enum):
    """Predefined ticket categories"""
    PASSWORD_RESET = "password_reset"
    ACCOUNT_UNLOCK = "account_unlock"
    SOFTWARE_INSTALL = "software_install"
    NETWORK_ISSUE = "network_issue"
    HARDWARE_ISSUE = "hardware_issue"
    EMAIL_ISSUE = "email_issue"
    PRINTER_ISSUE = "printer_issue"
    OTHER = "other"


class TicketRequest(BaseModel):
    """Incoming ticket data"""
    ticket_id: str = Field(..., description="osTicket ticket ID")
    subject: str = Field(..., description="Ticket subject line")
    body: str = Field(..., description="Ticket body content")
    priority: Optional[str] = Field("normal", description="Ticket priority")
    user_email: Optional[str] = Field(None, description="User email")


class TriageResult(BaseModel):
    """Triage classification result"""
    ticket_id: str
    category: TicketCategory
    confidence: float = Field(..., ge=0.0, le=1.0)
    action: str = Field(..., description="auto_close or human_review")
    reasoning: Optional[str] = None
    redacted: bool = Field(False, description="Whether PII was redacted")
    latency_ms: float


def redact_pii(text: str) -> tuple[str, bool]:
    """
    Redact PII using Microsoft Presidio.
    
    Returns:
        (redacted_text, was_redacted)
    """
    try:
        # Analyze text for PII entities
        results = analyzer.analyze(
            text=text,
            language='en',
            entities=["CREDIT_CARD", "CRYPTO", "EMAIL_ADDRESS", "IBAN_CODE",
                     "IP_ADDRESS", "NRP", "LOCATION", "PERSON", "PHONE_NUMBER",
                     "MEDICAL_LICENSE", "US_SSN", "US_BANK_NUMBER", "US_PASSPORT"]
        )
        
        if not results:
            return text, False
        
        # Anonymize detected entities
        anonymized = anonymizer.anonymize(
            text=text,
            analyzer_results=results,
            operators={
                "CREDIT_CARD": {"type": "replace", "new_value": "REDACTED_CC"},
                "US_SSN": {"type": "replace", "new_value": "REDACTED_SSN"},
                "EMAIL_ADDRESS": {"type": "replace", "new_value": "REDACTED_EMAIL"},
                "PHONE_NUMBER": {"type": "replace", "new_value": "REDACTED_PHONE"},
                "PERSON": {"type": "replace", "new_value": "REDACTED_NAME"},
                "DEFAULT": {"type": "replace", "new_value": "REDACTED"}
            }
        )
        
        return anonymized.text, True
        
    except Exception as e:
        logger.error(f"PII redaction failed: {e}")
        return text, False


async def classify_ticket_ollama(redacted_text: str, subject: str) -> tuple[TicketCategory, float, str]:
    """
    Classify ticket using Ollama (Llama 3.3 70B).
    
    Returns:
        (category, confidence, reasoning)
    """
    prompt = f"""You are a helpdesk ticket classifier. Analyze the following ticket and:
1. Classify it into ONE of these categories: password_reset, account_unlock, software_install, network_issue, hardware_issue, email_issue, printer_issue, other
2. Provide a confidence score (0.0-1.0)
3. Briefly explain your reasoning

Ticket Subject: {subject}
Ticket Body: {redacted_text}

Respond in JSON format:
{{
  "category": "category_name",
  "confidence": 0.95,
  "reasoning": "Brief explanation"
}}
"""
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{OLLAMA_HOST}/api/generate",
                json={
                    "model": OLLAMA_MODEL,
                    "prompt": prompt,
                    "stream": False,
                    "format": "json"
                }
            )
            response.raise_for_status()
            
            result = response.json()
            response_text = result.get("response", "{}")
            
            # Parse JSON response
            import json
            parsed = json.loads(response_text)
            
            category = TicketCategory(parsed.get("category", "other"))
            confidence = float(parsed.get("confidence", 0.0))
            reasoning = parsed.get("reasoning", "")
            
            return category, confidence, reasoning
            
    except Exception as e:
        logger.error(f"Ollama classification failed: {e}")
        # Fallback to low confidence
        return TicketCategory.OTHER, 0.0, f"Classification error: {str(e)}"


async def close_ticket_osticket(ticket_id: str, category: str, reasoning: str):
    """Close ticket in osTicket via API"""
    if not OSTICKET_API_KEY:
        logger.warning("OSTICKET_API_KEY not set, skipping auto-close")
        return
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{OSTICKET_URL}/api/tickets/{ticket_id}/close",
                headers={
                    "X-API-Key": OSTICKET_API_KEY,
                    "Content-Type": "application/json"
                },
                json={
                    "status": "closed",
                    "reason": f"Auto-closed by AI Triage (Category: {category})",
                    "note": reasoning
                }
            )
            response.raise_for_status()
            logger.info(f"Ticket {ticket_id} auto-closed")
            
    except Exception as e:
        logger.error(f"Failed to close ticket {ticket_id}: {e}")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    # Verify Ollama connectivity
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{OLLAMA_HOST}/api/tags")
            ollama_healthy = response.status_code == 200
    except:
        ollama_healthy = False
    
    return {
        "status": "healthy" if ollama_healthy else "degraded",
        "ollama_connected": ollama_healthy,
        "ollama_host": OLLAMA_HOST,
        "model": OLLAMA_MODEL,
        "auto_close_threshold": AUTO_CLOSE_THRESHOLD
    }


@app.post("/triage", response_model=TriageResult)
async def triage_ticket(ticket: TicketRequest, background_tasks: BackgroundTasks):
    """
    Triage a single ticket.
    
    Process:
        1. Redact PII with Presidio
        2. Classify with Ollama
        3. Auto-close if confidence ≥ threshold
        4. Return result
    """
    start_time = time.time()
    
    logger.info(f"Triaging ticket {ticket.ticket_id}")
    
    # Step 1: Redact PII
    combined_text = f"{ticket.subject}\n\n{ticket.body}"
    redacted_text, was_redacted = redact_pii(combined_text)
    
    if was_redacted:
        logger.info(f"Ticket {ticket.ticket_id}: PII redacted")
    
    # Step 2: Classify with Ollama
    category, confidence, reasoning = await classify_ticket_ollama(redacted_text, ticket.subject)
    
    logger.info(f"Ticket {ticket.ticket_id}: {category.value} (confidence: {confidence:.2f})")
    
    # Step 3: Determine action
    if confidence >= AUTO_CLOSE_THRESHOLD:
        action = "auto_close"
        metrics["auto_closed"] += 1
        
        # Close ticket in background
        background_tasks.add_task(close_ticket_osticket, ticket.ticket_id, category.value, reasoning)
    else:
        action = "human_review"
        metrics["human_review"] += 1
    
    # Update metrics
    metrics["total_triaged"] += 1
    latency_ms = (time.time() - start_time) * 1000
    metrics["avg_latency_ms"] = (
        (metrics["avg_latency_ms"] * (metrics["total_triaged"] - 1) + latency_ms) /
        metrics["total_triaged"]
    )
    metrics["avg_confidence"] = (
        (metrics["avg_confidence"] * (metrics["total_triaged"] - 1) + confidence) /
        metrics["total_triaged"]
    )
    
    return TriageResult(
        ticket_id=ticket.ticket_id,
        category=category,
        confidence=confidence,
        action=action,
        reasoning=reasoning,
        redacted=was_redacted,
        latency_ms=latency_ms
    )


@app.post("/triage/batch", response_model=List[TriageResult])
async def triage_batch(tickets: List[TicketRequest], background_tasks: BackgroundTasks):
    """Triage multiple tickets in batch"""
    results = []
    for ticket in tickets:
        result = await triage_ticket(ticket, background_tasks)
        results.append(result)
    return results


@app.get("/metrics")
async def get_metrics():
    """Prometheus-compatible metrics"""
    return {
        "total_triaged": metrics["total_triaged"],
        "auto_closed": metrics["auto_closed"],
        "human_review": metrics["human_review"],
        "auto_close_rate": metrics["auto_closed"] / max(metrics["total_triaged"], 1),
        "avg_confidence": metrics["avg_confidence"],
        "avg_latency_ms": metrics["avg_latency_ms"],
        "threshold": AUTO_CLOSE_THRESHOLD
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
