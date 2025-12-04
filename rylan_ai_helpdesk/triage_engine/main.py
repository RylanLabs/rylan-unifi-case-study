
from fastapi import FastAPI, HTTPException

from pydantic import BaseModel

import ollama

import json



try:

    from presidio_analyzer import AnalyzerEngine  # type: ignore

    PRESIDIO_AVAILABLE = True

except Exception:  # pragma: no cover - optional in CI

    AnalyzerEngine = None  # type: ignore

    PRESIDIO_AVAILABLE = False



app = FastAPI()





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

    

    prompt = f"""Analyze this IT ticket and respond with JSON only:

Ticket: {ticket.text}

VLAN: {ticket.vlan_source}

Role: {ticket.user_role}



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

