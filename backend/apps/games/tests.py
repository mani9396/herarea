from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.games.models import GameSession, GameParticipant, PlayerStatistic, SessionStatus, ParticipantStatus

User = get_user_model()

class GamesBackendPersistenceTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(phone_number='+1234567890', password='password123')
        self.client.force_authenticate(user=self.user)
        self.session_url = reverse('game-sessions-list')

    def test_session_creation(self):
        # 1. Game session creation and authenticated user ownership.
        response = self.client.post(self.session_url, {'game_type': 'quiz', 'is_multiplayer': False})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(GameSession.objects.count(), 1)
        
        session = GameSession.objects.first()
        self.assertEqual(session.host, self.user)
        self.assertEqual(session.game_type, 'quiz')

    def test_score_submission_and_persistence(self):
        # Create session
        response = self.client.post(self.session_url, {'game_type': 'sudoku', 'is_multiplayer': False})
        session_id = response.data['id']
        complete_url = reverse('game-sessions-complete', args=[session_id])
        
        # 2. Score submission and completion endpoint behavior.
        # 3. PostgreSQL persistence of completed game results.
        complete_response = self.client.post(complete_url, {'score': 500, 'is_winner': True})
        self.assertEqual(complete_response.status_code, status.HTTP_200_OK)
        
        # Verify persistence
        participant = GameParticipant.objects.get(session_id=session_id, user=self.user)
        self.assertEqual(participant.score, 500)
        self.assertTrue(participant.is_winner)
        self.assertEqual(participant.status, ParticipantStatus.COMPLETED)
        
        # Verify Stats
        stat = PlayerStatistic.objects.get(user=self.user, game_type='sudoku')
        self.assertEqual(stat.games_played, 1)
        self.assertEqual(stat.total_wins, 1)
        self.assertEqual(stat.highest_score, 500)

    def test_duplicate_submission_prevention(self):
        # 6. Prevention of duplicate submissions
        response = self.client.post(self.session_url, {'game_type': 'snake', 'is_multiplayer': False})
        session_id = response.data['id']
        complete_url = reverse('game-sessions-complete', args=[session_id])
        
        # First completion
        self.client.post(complete_url, {'score': 100, 'is_winner': True})
        stat = PlayerStatistic.objects.get(user=self.user, game_type='snake')
        self.assertEqual(stat.games_played, 1)
        
        # Duplicate completion should be blocked (HTTP 400)
        duplicate_response = self.client.post(complete_url, {'score': 200, 'is_winner': True})
        self.assertEqual(duplicate_response.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Stats should remain unchanged
        stat.refresh_from_db()
        self.assertEqual(stat.games_played, 1)
        self.assertEqual(stat.highest_score, 100)

    def test_history_and_statistics_retrieval(self):
        # 4. Statistics and game history retrieval
        response = self.client.post(self.session_url, {'game_type': '2048', 'is_multiplayer': False})
        session_id = response.data['id']
        self.client.post(reverse('game-sessions-complete', args=[session_id]), {'score': 2048, 'is_winner': True})
        
        # Test Statistics Endpoint
        stats_response = self.client.get(reverse('game-statistics-list'))
        self.assertEqual(stats_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(stats_response.data), 1)
        self.assertEqual(stats_response.data[0]['highest_score'], 2048)
        
        # Test History Endpoint
        history_response = self.client.get(reverse('game-history-list'))
        self.assertEqual(history_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(history_response.data), 1)
        self.assertEqual(history_response.data[0]['game_type'], '2048')

    def test_unauthorized_access(self):
        # 6. Prevention of unauthorized access to another user's records
        response = self.client.post(self.session_url, {'game_type': 'jigsaw', 'is_multiplayer': False})
        session_id = response.data['id']
        self.client.post(reverse('game-sessions-complete', args=[session_id]), {'score': 100, 'is_winner': True})
        
        # Create different user
        other_user = User.objects.create_user(phone_number='+0987654321', password='password123')
        other_client = APIClient()
        other_client.force_authenticate(user=other_user)
        
        # Other user should not see first user's history
        history_response = other_client.get(reverse('game-history-list'))
        self.assertEqual(history_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(history_response.data), 0)
        
        # Other user should not be able to complete first user's session (should be 404 because get_queryset filters by user's sessions)
        complete_response = other_client.post(reverse('game-sessions-complete', args=[session_id]), {'score': 500, 'is_winner': True})
        self.assertEqual(complete_response.status_code, status.HTTP_404_NOT_FOUND)
