from fastapi import FastAPI, HTTPException

from pydantic import BaseModel

import ollama

import json

import logging


try:
    from presidio_analyzer import AnalyzerEngine  # type: ignore

    PRESIDIO_AVAILABLE = True

except Exception:  # pragma: no cover - optional in CI
    AnalyzerEngine = None  # type: ignore

    PRESIDIO_AVAILABLE = False


from rylan_ai_helpdesk.triage_engine.rag.retriever import RAGRetriever


logger = logging.getLogger(__name__)
app = FastAPI()

# Initialize RAG retriever once
_retriever = None


def get_retriever():
    """Lazy-load RAG retriever on first call."""
    global _retriever
    if _retriever is None:
        logger.info("Initializing RAGRetriever")
        _retriever = RAGRetriever()
    return _retriever


class TicketRequest(BaseModel):
    text: str

    vlan_source: str

    user_role: str


def get_analyzer():
    """Lazy-load Presidio analyzer only when needed."""

    if not PRESIDIO_AVAILABLE:
        return None

    try:
        return AnalyzerEngine()

    except Exception:
        return None


@app.post("/triage")
async def triage_ticket(ticket: TicketRequest):
    # Lazy-load analyzer only if PII detection is needed

    # analyzer = get_analyzer()

    retriever = get_retriever()

    # Retrieve context from knowledge base

    context = retriever.inject_context(
        query=ticket.text,
        base_prompt="",
        limit=3,
        vlan_filter=ticket.vlan_source,
    )

    prompt = f"""Analyze this IT ticket and respond with JSON only:

Ticket: {ticket.text}

VLAN: {ticket.vlan_source}

Role: {ticket.user_role}

{context}

Respond with: {{"confidence": 0.0-1.0, "action": "auto-close" or "escalate", "summary": "brief action"}}"""

    response = ollama.chat(
        model="llama3.2", messages=[{"role": "user", "content": prompt}]
    )

    try:
        decision = json.loads(response["message"]["content"])

        if decision["action"] == "escalate":
            raise HTTPException(status_code=418, detail="Escalation required")

        return {
            "action": decision["action"],
            "confidence": decision["confidence"],
            "summary": decision.get("summary", "Auto-resolved"),
        }

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="LLM response parsing failed")


@app.get("/health")
async def health():
    return {"status": "ok"}
