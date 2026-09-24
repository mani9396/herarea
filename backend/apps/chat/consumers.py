import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from apps.chat.models import Conversation, Message
from apps.accounts.models import UserRole
import uuid

MAX_MESSAGE_LENGTH = 2000

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f"chat_{self.conversation_id}"

        if not self.user.is_authenticated:
            await self.close(code=4001)
            return

        has_access = await self.check_conversation_access()
        if not has_access:
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message = text_data_json.get('message', '').strip()
        except json.JSONDecodeError:
            return

        if not message:
            return

        if len(message) > MAX_MESSAGE_LENGTH:
            await self.send(text_data=json.dumps({
                'error': f'Message exceeds maximum length of {MAX_MESSAGE_LENGTH} characters.'
            }))
            return

        can_send = await self.check_effective_chat_access()
        if not can_send:
            await self.send(text_data=json.dumps({
                'error': 'Chat is currently unavailable for this vendor.'
            }))
            return

        saved_msg = await self.save_message(message)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': saved_msg
            }
        )

    async def chat_message(self, event):
        message = event['message']
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message': message
        }))

    @database_sync_to_async
    def check_conversation_access(self):
        try:
            conv = Conversation.objects.select_related('customer', 'vendor').get(id=self.conversation_id)
            self.conversation = conv
            if self.user == conv.customer or self.user == conv.vendor:
                return True
            return False
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def check_effective_chat_access(self):
        vendor = self.conversation.vendor
        if not hasattr(vendor, 'vendor_profile'):
            return False
        return vendor.vendor_profile.effective_chat_access

    @database_sync_to_async
    def save_message(self, text):
        msg = Message.objects.create(
            conversation=self.conversation,
            sender=self.user,
            message=text
        )
        self.conversation.last_message_at = msg.created_at
        self.conversation.save(update_fields=['last_message_at'])
        return {
            'id': str(msg.id),
            'conversation_id': str(self.conversation.id),
            'sender_id': str(self.user.id),
            'message': msg.message,
            'created_at': msg.created_at.isoformat(),
            'is_read': msg.is_read
        }