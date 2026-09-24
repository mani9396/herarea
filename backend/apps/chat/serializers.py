from rest_framework import serializers
from apps.chat.models import Conversation, Message
from apps.accounts.models import User

class ParticipantSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number', 'role']


class ConversationSerializer(serializers.ModelSerializer):
    customer = ParticipantSerializer(read_only=True)
    vendor = ParticipantSerializer(read_only=True)
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ['id', 'customer', 'vendor', 'last_message_at', 'created_at', 'updated_at', 'unread_count']

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'conversation', 'sender', 'message', 'is_read', 'read_at', 'created_at']
        read_only_fields = ['id', 'sender', 'is_read', 'read_at', 'created_at']