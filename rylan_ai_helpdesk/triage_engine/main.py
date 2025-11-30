from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import ollama
from presidio_analyzer import AnalyzerEngine
import json

app = FastAPI()

class TicketRequest(BaseModel):
    text: str
    vlan_source: str
    user_role: str

analyzer = AnalyzerEngine()

@app.post("/triage")
async def triage_ticket(ticket: TicketRequest):
    pii_results = analyzer.analyze(text=ticket.text, language='en')
    
    context = {
        "ticket_text": ticket.text,
        "vlan": ticket.vlan_source,
        "role": ticket.user_role,
        "has_pii": len(pii_results) > 0
    }
    
    prompt = f"""Analyze this IT ticket and respond with JSON only:
Ticket: {ticket.text}
VLAN: {ticket.vlan_source}
Role: {ticket.user_role}

Respond with: {{"confidence": 0.0-1.0, "action": "auto-close" or "escalate", "summary": "brief action"}}"""
    
    response = ollama.chat(
        model='llama3.2',
        messages=[{'role': 'user', 'content': prompt}]
    )
    
    try:
        decision = json.loads(response['message']['content'])
        
        if decision['action'] == 'escalate':
            raise HTTPException(status_code=418, detail="Escalation required")
        
        return {
            "action": decision['action'],
            "confidence": decision['confidence'],
            "summary": decision.get('summary', 'Auto-resolved')
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="LLM response parsing failed")

@app.get("/health")
async def health():
    return {"status": "ok"}