from django.urls import path
from apps.chat.views import (
    WsTokenView,
    ConversationListView,
    ConversationCreateView,
    MessageListView,
    MessageReadView
)

urlpatterns = [
    path('ws-token/', WsTokenView.as_view(), name='ws_token'),
    path('conversations/', ConversationListView.as_view(), name='conversation_list'),
    path('conversations/start/', ConversationCreateView.as_view(), name='conversation_start'),
    path('conversations/<uuid:pk>/messages/', MessageListView.as_view(), name='message_list'),
    path('conversations/<uuid:pk>/read/', MessageReadView.as_view(), name='message_read'),
]