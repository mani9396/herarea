import uuid
from django.db import models
from django.conf import settings

class GameType(models.TextChoices):
    LUDO = 'ludo', 'Ludo'
    TAMBOLA = 'tambola', 'Tambola'
    JIGSAW = 'jigsaw', 'Jigsaw Puzzle'
    SUDOKU = 'sudoku', 'Sudoku'
    MEMORY_MATCH = 'memory_match', 'Memory Match'
    TWENTY_FORTY_EIGHT = '2048', '2048 Number Puzzle'
    TIC_TAC_TOE = 'tic_tac_toe', 'Tic-Tac-Toe'
    WORD_SEARCH = 'word_search', 'Word Search'
    QUIZ = 'quiz', 'Quiz Challenge'
    SNAKE = 'snake', 'Snake'

class SessionStatus(models.TextChoices):
    WAITING = 'waiting', 'Waiting for Players'
    IN_PROGRESS = 'in_progress', 'In Progress'
    COMPLETED = 'completed', 'Completed'
    ABANDONED = 'abandoned', 'Abandoned'

class GameSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    game_type = models.CharField(max_length=50, choices=GameType.choices)
    host = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='hosted_game_sessions')
    status = models.CharField(max_length=20, choices=SessionStatus.choices, default=SessionStatus.WAITING)
    state_data = models.JSONField(default=dict, blank=True, help_text="Stores game-specific state like board layout, moves, drawn numbers, etc.")
    is_multiplayer = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_game_type_display()} Session - {self.id}"

class ParticipantStatus(models.TextChoices):
    ACTIVE = 'active', 'Active'
    LEFT = 'left', 'Left'
    COMPLETED = 'completed', 'Completed'

class GameParticipant(models.Model):
    session = models.ForeignKey(GameSession, on_delete=models.CASCADE, related_name='participants')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='game_participations')
    score = models.IntegerField(default=0)
    is_winner = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=ParticipantStatus.choices, default=ParticipantStatus.ACTIVE)
    joined_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('session', 'user')
        ordering = ['joined_at']

    def __str__(self):
        return f"{self.user} in {self.session.id}"

class SavedProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='saved_game_progress')
    game_type = models.CharField(max_length=50, choices=GameType.choices)
    progress_data = models.JSONField(default=dict)
    last_saved = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'game_type')

    def __str__(self):
        return f"{self.user} - {self.get_game_type_display()} Progress"

class PlayerStatistic(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='game_statistics')
    game_type = models.CharField(max_length=50, choices=GameType.choices)
    games_played = models.PositiveIntegerField(default=0)
    highest_score = models.IntegerField(default=0)
    total_wins = models.PositiveIntegerField(default=0)
    total_play_time_seconds = models.PositiveIntegerField(default=0)
    last_played = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'game_type')

    def __str__(self):
        return f"{self.user} - {self.get_game_type_display()} Stats"
