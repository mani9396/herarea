import uuid
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status, generics
from django.core.cache import cache
from drf_spectacular.utils import extend_schema, OpenApiResponse
from apps.chat.models import Conversation, Message
from apps.chat.serializers import ConversationSerializer, MessageSerializer
from apps.accounts.models import User, UserRole

class WsTokenView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get WebSocket Authentication Token",
        responses={200: OpenApiResponse(description="Returns a short-lived token for WebSocket authentication.")}
    )
    def post(self, request):
        token = str(uuid.uuid4())
        cache_key = f"ws_token_{token}"
        cache.set(cache_key, request.user.id, timeout=30)
        return Response({"ws_token": token}, status=status.HTTP_200_OK)


class ConversationListView(generics.ListAPIView):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == UserRole.CUSTOMER:
            return Conversation.objects.filter(customer=user)
        elif user.role == UserRole.VENDOR:
            return Conversation.objects.filter(vendor=user)
        return Conversation.objects.none()


class ConversationCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Start or Get Conversation with Vendor",
        responses={200: ConversationSerializer, 201: ConversationSerializer}
    )
    def post(self, request):
        if request.user.role != UserRole.CUSTOMER:
            return Response({"error": "Only customers can initiate conversations."}, status=status.HTTP_403_FORBIDDEN)

        vendor_id = request.data.get('vendor_id')
        if not vendor_id:
            return Response({"error": "vendor_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            vendor = User.objects.get(id=vendor_id, role=UserRole.VENDOR)
        except User.DoesNotExist:
            return Response({"error": "Vendor not found."}, status=status.HTTP_404_NOT_FOUND)

        # Validate Vendor Approval & Chat Entitlement
        if not hasattr(vendor, 'vendor_profile'):
            return Response({"error": "Vendor profile not found."}, status=status.HTTP_400_BAD_REQUEST)
        
        if not vendor.vendor_profile.effective_chat_access:
            return Response({"error": "This vendor is currently unavailable for chat."}, status=status.HTTP_403_FORBIDDEN)

        conversation, created = Conversation.objects.get_or_create(
            customer=request.user,
            vendor=vendor
        )
        serializer = ConversationSerializer(conversation, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class MessageListView(generics.ListAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        conversation_id = self.kwargs.get('pk')
        try:
            conversation = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            return Message.objects.none()

        user = self.request.user
        if user != conversation.customer and user != conversation.vendor:
            return Message.objects.none()

        return conversation.messages.all()


class MessageReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Mark Conversation Messages as Read",
        responses={200: OpenApiResponse(description="Messages marked as read.")}
    )
    def post(self, request, pk):
        try:
            conversation = Conversation.objects.get(id=pk)
        except Conversation.DoesNotExist:
            return Response({"error": "Conversation not found."}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        if user != conversation.customer and user != conversation.vendor:
            return Response({"error": "Unauthorized."}, status=status.HTTP_403_FORBIDDEN)

        unread_messages = conversation.messages.filter(is_read=False).exclude(sender=user)
        unread_messages.update(is_read=True, read_at=timezone.now())

        return Response({"success": True}, status=status.HTTP_200_OK)
