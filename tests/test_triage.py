import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient

# Absolute import – works on Windows + Linux
from _03_ai_helpdesk.triage_engine.main import app

client = TestClient(app)

@patch('ollama.chat')
@patch('presidio_analyzer.AnalyzerEngine.analyze')
def test_auto_close(mock_analyze, mock_ollama):
    mock_analyze.return_value = []
    mock_ollama.return_value = {
        'message': {
            'content': '{"confidence": 0.96, "action": "auto-close", "summary": "Reboot access point"}'
        }
    }
    response = client.post('/triage', json={
        'text': 'WiFi down',
        'vlan_source': '30',
        'user_role': 'employee'
    })
    assert response.status_code == 200
    assert response.json()['action'] == 'auto-close'

@patch('ollama.chat')
@patch('presidio_analyzer.AnalyzerEngine.analyze')
def test_escalate(mock_analyze, mock_ollama):
    mock_analyze.return_value = []
    mock_ollama.return_value = {
        'message': {
            'content': '{"confidence": 0.82, "action": "escalate"}'
        }
    }
    response = client.post('/triage', json={
        'text': 'Printer offline',
        'vlan_source': '90',
        'user_role': 'guest'
    })
    assert response.status_code == 418