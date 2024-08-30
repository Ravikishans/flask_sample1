import pytest
from flask import Flask

# Create a basic Flask application for testing
@pytest.fixture
def app():
    app = Flask(__name__)
    
    @app.route('/')
    def home():
        return "Hello, World!"
    
    return app

@pytest.fixture
def client(app):
    return app.test_client()

def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.data == b'Hello, World!'