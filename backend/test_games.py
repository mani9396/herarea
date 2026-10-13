import sys
import os
import django

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

User = get_user_model()

def run_tests():
    print("Running Tests...")
    
    # Create or get user
    user, created = User.objects.get_or_create(email='test_games@example.com', defaults={'phone_number': '5554443333', 'full_name': 'Test Player'})
    
    client = APIClient()
    client.force_authenticate(user=user)
    
    # Test Catalogue
    response = client.get('/api/v1/games/catalogue/')
    print(f"Catalogue Status Code: {response.status_code}")
    print(f"Catalogue Data: {response.data[:2]} ... (total {len(response.data)})")
    
    # Test Create Session
    response = client.post('/api/v1/games/sessions/', {'game_type': 'ludo', 'is_multiplayer': True}, format='json')
    print(f"Create Session Status Code: {response.status_code}")
    print(f"Create Session Data: {response.data}")
    
    session_id = response.data['id']
    
    # Test Join Session
    response = client.post(f'/api/v1/games/sessions/{session_id}/join/')
    print(f"Join Session Status Code: {response.status_code}")
    print(f"Join Session Data: {response.data}")

if __name__ == '__main__':
    run_tests()
