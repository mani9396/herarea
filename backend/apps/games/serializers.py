from rest_framework import serializers
from .models import GameSession, GameParticipant, SavedProgress, PlayerStatistic, GameType
from apps.accounts.serializers import UserSerializer

class GameParticipantSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = GameParticipant
        fields = ['id', 'user', 'score', 'is_winner', 'status', 'joined_at', 'completed_at']

class GameSessionSerializer(serializers.ModelSerializer):
    participants = GameParticipantSerializer(many=True, read_only=True)
    host = UserSerializer(read_only=True)

    class Meta:
        model = GameSession
        fields = ['id', 'game_type', 'host', 'status', 'state_data', 'is_multiplayer', 'created_at', 'updated_at', 'participants']
        read_only_fields = ['id', 'host', 'created_at', 'updated_at']

class SavedProgressSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedProgress
        fields = ['game_type', 'progress_data', 'last_saved']
        read_only_fields = ['last_saved']

class PlayerStatisticSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayerStatistic
        fields = ['game_type', 'games_played', 'highest_score', 'total_wins', 'total_play_time_seconds', 'last_played']
        read_only_fields = ['games_played', 'highest_score', 'total_wins', 'total_play_time_seconds', 'last_played']
