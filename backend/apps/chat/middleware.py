import urllib.parse
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.core.cache import cache
from apps.accounts.models import User

@database_sync_to_async
def get_user_from_token(token):
    if not token:
        return AnonymousUser()
    
    cache_key = f"ws_token_{token}"
    user_id = cache.get(cache_key)
    if not user_id:
        return AnonymousUser()
        
    try:
        user = User.objects.get(id=user_id)
        # Delete token after successful use to ensure single-use
        cache.delete(cache_key)
        return user
    except User.DoesNotExist:
        return AnonymousUser()

class TokenAuthMiddleware:
    """
    Middleware that takes a short-lived token from the query string
    and authenticates the WebSocket connection.
    """
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        query_string = scope.get("query_string", b"").decode("utf-8")
        parsed_query = urllib.parse.parse_qs(query_string)
        
        token = parsed_query.get("token", [None])[0]
        
        scope["user"] = await get_user_from_token(token)
        
        return await self.inner(scope, receive, send)