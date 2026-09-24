from django.db import models
from django.conf import settings
from apps.common.models import AbstractBaseModel
import uuid

class Conversation(AbstractBaseModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='customer_conversations')
    vendor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='vendor_conversations')
    last_message_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('customer', 'vendor')
        ordering = ['-last_message_at']

    def __str__(self):
        return f"Chat: {self.customer.email} <-> {self.vendor.email}"


class Message(AbstractBaseModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages')
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Message by {self.sender.email} in {self.conversation.id}"
