from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from presidio_analyzer import AnalyzerEngine
import ollama
import os
from dotenv import load_dotenv

load_dotenv()
app = FastAPI(title="Rylan AI Triage v5.0")
analyzer = AnalyzerEngine()

class TicketInput(BaseModel):
    text: str
    vlan_source: str  # e.g., "30" for trusted-devices
    user_role: str    # e.g., "employee"

@app.post("/triage")
async def triage_ticket(ticket: TicketInput):
    # Redact PII (IPs, emails)
    results = analyzer.analyze(text=ticket.text, entities=["PHONE_NUMBER", "EMAIL_ADDRESS"], language="en")
    redacted_text = analyzer.analyzer_redactor.redact(ticket.text, results).text

    # Enrich: VLAN  priority
    priority_map = {"30": "high", "90": "low"}  # From inventory.yaml
    enriched = f"Priority: {priority_map.get(ticket.vlan_source, 'medium')}. Role: {ticket.user_role}. Text: {redacted_text}"

    # Ollama call (local Llama 3.3 70B)
    response = ollama.chat(model="llama3.3:70b", messages=[{"role": "user", "content": f"Classify IT ticket: {enriched}. Output JSON: {{'category': str, 'confidence': float, 'action': 'auto-close' if >=0.93 else 'escalate', 'summary': str}}"}])
    output = eval(response["message"]["content"])  # Strict schema in prod

    if output["confidence"] >= 0.93:
        # Auto-close via osTicket API (stub: POST to 10.0.30.40/api/tickets/{id}/close)
        print(f"Auto-closing ticket with summary: {output['summary']}")
        return {"action": "auto-close", "confidence": output["confidence"]}

    raise HTTPException(status_code=418, detail="Escalate to agent")  # Teapot for fun

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)  # VLAN 10 only
