import os
import sys
import django
import asyncio
import uuid

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from apps.games.models import GameSession, GameType, GameParticipant
from config.asgi import application
from django.core.cache import cache

User = get_user_model()

async def test_tictactoe():
    print("Testing TicTacToe Multiplayer...")
    
    # Setup users
    user1 = await User.objects.aget_or_create(email='player1@test.com', defaults={'phone_number': '11111'})
    user1 = user1[0]
    user2 = await User.objects.aget_or_create(email='player2@test.com', defaults={'phone_number': '22222'})
    user2 = user2[0]
    
    # Create Game Session
    session = await GameSession.objects.acreate(game_type=GameType.TIC_TAC_TOE, is_multiplayer=True, host=user1)
    await GameParticipant.objects.acreate(session=session, user=user1)
    await GameParticipant.objects.acreate(session=session, user=user2)
    
    # Generate tokens
    token1 = str(uuid.uuid4())
    token2 = str(uuid.uuid4())
    cache.set(f"ws_token_{token1}", user1.id, 60)
    cache.set(f"ws_token_{token2}", user2.id, 60)
    
    print(f"Session ID: {session.id}")
    
    # Connect user1
    communicator1 = WebsocketCommunicator(application, f"/ws/games/tic-tac-toe/{session.id}/?token={token1}")
    connected1, _ = await communicator1.connect()
    print(f"User 1 connected: {connected1}")
    assert connected1
    
    state1 = await communicator1.receive_json_from()
    print(f"User 1 initial state: {state1}")
    
    # Connect user2
    communicator2 = WebsocketCommunicator(application, f"/ws/games/tic-tac-toe/{session.id}/?token={token2}")
    connected2, _ = await communicator2.connect()
    print(f"User 2 connected: {connected2}")
    assert connected2
    
    state2 = await communicator2.receive_json_from()
    print(f"User 2 initial state: {state2}")
    
    # Turn sequence: user1(0), user2(1), user1(3), user2(4), user1(6) -> user1 wins
    print("Sending move for user1 at pos 0")
    await communicator1.send_json_to({'action': 'make_move', 'position': 0})
    u1_update = await communicator1.receive_json_from()
    u2_update = await communicator2.receive_json_from()
    print(f"Update after P1 moves: {u1_update}")
    
    print("Sending move for user2 at pos 1")
    await communicator2.send_json_to({'action': 'make_move', 'position': 1})
    await communicator1.receive_json_from()
    await communicator2.receive_json_from()
    
    print("Sending move for user1 at pos 3")
    await communicator1.send_json_to({'action': 'make_move', 'position': 3})
    await communicator1.receive_json_from()
    await communicator2.receive_json_from()
    
    print("Sending move for user2 at pos 4")
    await communicator2.send_json_to({'action': 'make_move', 'position': 4})
    await communicator1.receive_json_from()
    await communicator2.receive_json_from()
    
    print("Sending move for user1 at pos 6 (Winning move)")
    await communicator1.send_json_to({'action': 'make_move', 'position': 6})
    final_u1 = await communicator1.receive_json_from()
    final_u2 = await communicator2.receive_json_from()
    
    print(f"Final state: {final_u1}")
    assert final_u1['state']['winner'] == str(user1.id)
    
    await communicator1.disconnect()
    await communicator2.disconnect()
    print("Test passed successfully!")

if __name__ == '__main__':
    asyncio.run(test_tictactoe())
