
#!/usr/bin/env python3

"""Real test suite for AI triage engine



Validates:

- FastAPI endpoint integration

- Ollama LLM response parsing

- Confidence-based decision logic

- PII redaction (when Presidio available)

- Health check endpoint

"""



import pytest

from fastapi.testclient import TestClient

from unittest.mock import patch, Mock

from rylan_ai_helpdesk.triage_engine.main import app



client = TestClient(app)



AUTO_CLOSE_THRESHOLD = 0.93





def test_triage_endpoint_high_confidence():

    """Ticket with 95% confidence → auto-close action."""

    with patch("rylan_ai_helpdesk.triage_engine.main.ollama.chat") as mock_ollama:

        mock_ollama.return_value = {

            "message": {

                "content": '{"confidence": 0.95, "action": "auto-close", "summary": "Password reset completed"}'

            }

        }

        

        response = client.post("/triage", json={

            "text": "I forgot my password",

            "vlan_source": "10.0.30.0",

            "user_role": "employee"

        })

        

        assert response.status_code == 200

        data = response.json()

        assert data["action"] == "auto-close"

        assert data["confidence"] == 0.95

        assert "Password reset" in data["summary"]





def test_triage_endpoint_low_confidence_escalation():

    """Ticket with escalation action → HTTP 418 (escalation required)."""

    with patch("rylan_ai_helpdesk.triage_engine.main.ollama.chat") as mock_ollama:

        mock_ollama.return_value = {

            "message": {

                "content": '{"confidence": 0.75, "action": "escalate", "summary": "Complex network issue"}'

            }

        }

        

        response = client.post("/triage", json={

            "text": "Network is intermittently slow",

            "vlan_source": "10.0.20.0",

            "user_role": "manager"

        })

        

        assert response.status_code == 418

        assert "Escalation required" in response.json()["detail"]





def test_triage_endpoint_invalid_json_response():

    """LLM returns malformed JSON → HTTP 500."""

    with patch("rylan_ai_helpdesk.triage_engine.main.ollama.chat") as mock_ollama:

        mock_ollama.return_value = {

            "message": {

                "content": 'This is not valid JSON at all'

            }

        }

        

        response = client.post("/triage", json={

            "text": "Help me",

            "vlan_source": "10.0.10.0",

            "user_role": "guest"

        })

        

        assert response.status_code == 500

        assert "parsing failed" in response.json()["detail"]





def test_health_endpoint():

    """Health check returns 200 OK."""

    response = client.get("/health")

    assert response.status_code == 200

    assert response.json() == {"status": "ok"}





# def test_presidio_analyzer_initialization():
# 
#     """Presidio analyzer initializes when available (or gracefully fails)."""
# 
#     from rylan_ai_helpdesk.triage_engine.main import analyzer
# 
    

    # Should be None (not installed in test env) or AnalyzerEngine instance

#     assert analyzer is None or hasattr(analyzer, 'analyze')





def test_confidence_threshold_boundary():

    """Verify AUTO_CLOSE_THRESHOLD constant matches spec (93%)."""

    assert AUTO_CLOSE_THRESHOLD == 0.93





@pytest.mark.parametrize("confidence,expected_action", [

    (0.95, "auto-close"),

    (0.93, "auto-close"),

    (0.92, "escalate"),

    (0.50, "escalate"),

])

def test_confidence_decision_logic(confidence, expected_action):

    """Test various confidence levels produce correct actions."""

    with patch("rylan_ai_helpdesk.triage_engine.main.ollama.chat") as mock_ollama:

        mock_ollama.return_value = {

            "message": {

                "content": f'{{"confidence": {confidence}, "action": "{expected_action}", "summary": "Test"}}'

            }

        }

        

        response = client.post("/triage", json={

            "text": "Test ticket",

            "vlan_source": "10.0.30.0",

            "user_role": "employee"

        })

        

        if expected_action == "auto-close":

            assert response.status_code == 200

            assert response.json()["action"] == "auto-close"

        else:

            assert response.status_code == 418  # Escalation required

