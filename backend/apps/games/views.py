from rest_framework import viewsets, permissions, status, decorators
from rest_framework.response import Response
from django.utils import timezone
from .models import GameSession, GameParticipant, SavedProgress, PlayerStatistic, GameType, SessionStatus, ParticipantStatus
from .serializers import GameSessionSerializer, GameParticipantSerializer, SavedProgressSerializer, PlayerStatisticSerializer
from django.db import transaction, models

class GameCatalogueView(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        games = [
            {'id': choice[0], 'name': choice[1]}
            for choice in GameType.choices
        ]
        return Response(games)

class GameSessionViewSet(viewsets.ModelViewSet):
    serializer_class = GameSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Users can see sessions they created or joined, and any WAITING multiplayer sessions
        user = self.request.user
        return GameSession.objects.filter(
            models.Q(host=user) | 
            models.Q(participants__user=user) | 
            models.Q(is_multiplayer=True, status=SessionStatus.WAITING)
        ).distinct()

    def perform_create(self, serializer):
        with transaction.atomic():
            session = serializer.save(host=self.request.user)
            GameParticipant.objects.create(session=session, user=self.request.user)

    @decorators.action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        session = self.get_object()
        if not session.is_multiplayer:
            return Response({'detail': 'This is not a multiplayer session.'}, status=status.HTTP_400_BAD_REQUEST)
        if session.status != SessionStatus.WAITING:
            return Response({'detail': 'Session is already in progress or completed.'}, status=status.HTTP_400_BAD_REQUEST)
        
        participant, created = GameParticipant.objects.get_or_create(session=session, user=request.user)
        if created:
            return Response({'detail': 'Joined successfully.'}, status=status.HTTP_200_OK)
        return Response({'detail': 'Already joined.'}, status=status.HTTP_200_OK)

    @decorators.action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        session = self.get_object()
        try:
            participant = GameParticipant.objects.get(session=session, user=request.user)
            participant.status = ParticipantStatus.LEFT
            participant.save()
            # If host leaves, maybe abandon session?
            if session.host == request.user and session.status == SessionStatus.WAITING:
                session.status = SessionStatus.ABANDONED
                session.save()
            return Response({'detail': 'Left successfully.'}, status=status.HTTP_200_OK)
        except GameParticipant.DoesNotExist:
            return Response({'detail': 'Not a participant.'}, status=status.HTTP_400_BAD_REQUEST)

    @decorators.action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        session = self.get_object()
        # Verify user is host or participant
        if not GameParticipant.objects.filter(session=session, user=request.user).exists():
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            score = int(request.data.get('score', 0))
        except (ValueError, TypeError):
            score = 0
            
        is_winner = request.data.get('is_winner', False)
        # Parse is_winner strictly to bool if needed, but truthy is usually fine.
        if isinstance(is_winner, str):
            is_winner = is_winner.lower() == 'true'

        with transaction.atomic():
            participant = GameParticipant.objects.get(session=session, user=request.user)
            
            # Prevent duplicate submissions
            if participant.status == ParticipantStatus.COMPLETED:
                return Response({'detail': 'Session already completed by this user.'}, status=status.HTTP_400_BAD_REQUEST)

            participant.score = score
            participant.is_winner = is_winner
            participant.status = ParticipantStatus.COMPLETED
            participant.completed_at = timezone.now()
            participant.save()

            if session.status != SessionStatus.COMPLETED:
                # Basic implementation: complete session if any participant finishes.
                session.status = SessionStatus.COMPLETED
                if 'state_data' in request.data and isinstance(request.data['state_data'], dict):
                    session.state_data.update(request.data['state_data'])
                session.save()
            elif 'state_data' in request.data and isinstance(request.data['state_data'], dict):
                session.state_data.update(request.data['state_data'])
                session.save()

            # Update stats
            stat, _ = PlayerStatistic.objects.get_or_create(user=request.user, game_type=session.game_type)
            stat.games_played += 1
            if is_winner:
                stat.total_wins += 1
            if score > stat.highest_score:
                stat.highest_score = score
            stat.save()

        return Response({'detail': 'Session completed.'}, status=status.HTTP_200_OK)

class SavedProgressViewSet(viewsets.ModelViewSet):
    serializer_class = SavedProgressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SavedProgress.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        game_type = serializer.validated_data.get('game_type')
        # Update if exists
        progress, created = SavedProgress.objects.update_or_create(
            user=self.request.user,
            game_type=game_type,
            defaults={'progress_data': serializer.validated_data.get('progress_data', {})}
        )

class PlayerStatisticViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PlayerStatisticSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PlayerStatistic.objects.filter(user=self.request.user)

class GameHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = GameSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Returns only completed sessions for the user
        return GameSession.objects.filter(
            participants__user=self.request.user,
            status=SessionStatus.COMPLETED
        ).distinct()
