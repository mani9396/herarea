import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/games/presentation/screens/ludo/ludo_engine.dart';

void main() {
  group('LudoGameEngine', () {
    test('Initializes correctly with 16 tokens for default 4 players', () {
      final engine = LudoGameEngine();
      expect(engine.tokens.length, 16);
      expect(engine.currentTurn, 0);
      expect(engine.isGameOver, false);
      expect(engine.tokens.where((t) => t.state == TokenState.base).length, 16);
    });

    test('Initializes correctly with 2 players (8 tokens)', () {
      final engine = LudoGameEngine.custom(
        players: const [
          LudoPlayer(id: 0, color: LudoColor.red, name: 'You', isComputer: false),
          LudoPlayer(id: 1, color: LudoColor.yellow, name: 'Computer', isComputer: true),
        ],
        gameMode: LudoGameMode.vsComputer,
      );
      expect(engine.tokens.length, 8);
      expect(engine.players.length, 2);
      expect(engine.currentPlayer.color, LudoColor.red);

      // Roll and move token out
      engine.currentDice = 6;
      final token = engine.getValidMoves().first;
      engine.moveToken(token); // Extra turn granted on 6
      expect(engine.currentPlayer.color, LudoColor.red);

      // Move again with 3 (no capture, not 6) -> turn passes to yellow
      engine.currentDice = 3;
      engine.moveToken(token);
      expect(engine.currentPlayer.color, LudoColor.yellow);
    });

    test('Initializes correctly with 3 players (12 tokens) for Pass & Play', () {
      final engine = LudoGameEngine.custom(
        players: const [
          LudoPlayer(id: 0, color: LudoColor.red, name: 'Player 1', isComputer: false),
          LudoPlayer(id: 1, color: LudoColor.green, name: 'Player 2', isComputer: false),
          LudoPlayer(id: 2, color: LudoColor.blue, name: 'Player 3', isComputer: false),
        ],
        gameMode: LudoGameMode.passAndPlay,
      );
      expect(engine.tokens.length, 12);
      expect(engine.players.length, 3);
      expect(engine.currentPlayer.name, 'Player 1');

      // Pass turn: player 1 -> player 2 -> player 3 -> player 1
      engine.passTurn();
      expect(engine.currentPlayer.name, 'Player 2');
      engine.passTurn();
      expect(engine.currentPlayer.name, 'Player 3');
      engine.passTurn();
      expect(engine.currentPlayer.name, 'Player 1');
    });

    test('Requires a 6 to leave base', () {
      final engine = LudoGameEngine();
      engine.currentDice = 5;
      expect(engine.getValidMoves().isEmpty, true);

      engine.currentDice = 6;
      expect(engine.getValidMoves().length, 4); // All 4 tokens in base can move
    });

    test('Moves token out of base properly', () {
      final engine = LudoGameEngine();
      engine.currentDice = 6;

      final token = engine.getValidMoves().first;
      bool moved = engine.moveToken(token);

      expect(moved, true);
      expect(token.state, TokenState.track);
      expect(token.position, 0); // Red start position
    });

    test('Token moves along the track properly', () {
      final engine = LudoGameEngine();
      var token = engine.tokens.first;
      token.state = TokenState.track;
      token.position = 0;

      engine.currentDice = 4;
      bool moved = engine.moveToken(token);

      expect(moved, true);
      expect(token.position, 4);
    });

    test('Captures opponent token correctly in Capture and Send Home mode', () {
      final engine = LudoGameEngine.custom(
        players: const [
          LudoPlayer(id: 0, color: LudoColor.red, name: 'You', isComputer: false),
          LudoPlayer(id: 1, color: LudoColor.green, name: 'Bot', isComputer: true),
        ],
        captureRule: LudoCaptureRule.captureAndSendHome,
      );

      var redToken = engine.tokens[0];
      redToken.state = TokenState.track;
      redToken.position = 5; // Red token at 5

      var greenToken = engine.tokens[4];
      greenToken.state = TokenState.track;
      greenToken.position = 9; // Green token at 9

      engine.currentDice = 4; // 5 + 4 = 9 (capture)

      bool moved = engine.moveToken(redToken);

      expect(moved, true);
      expect(redToken.position, 9);
      expect(greenToken.state, TokenState.base); // Green token sent to base
    });

    test('No Capture mode allows tokens to share square without sending home', () {
      final engine = LudoGameEngine.custom(
        players: const [
          LudoPlayer(id: 0, color: LudoColor.red, name: 'You', isComputer: false),
          LudoPlayer(id: 1, color: LudoColor.green, name: 'Bot', isComputer: true),
        ],
        captureRule: LudoCaptureRule.noCapture,
      );

      var redToken = engine.tokens[0];
      redToken.state = TokenState.track;
      redToken.position = 5;

      var greenToken = engine.tokens[4];
      greenToken.state = TokenState.track;
      greenToken.position = 9;

      engine.currentDice = 4; // 5 + 4 = 9

      bool moved = engine.moveToken(redToken);

      expect(moved, true);
      expect(redToken.position, 9);
      expect(greenToken.state, TokenState.track); // Green token is NOT sent to base
      expect(greenToken.position, 9); // Both share square 9
    });

    test('Safe squares prevent capture even in Capture mode', () {
      final engine = LudoGameEngine();

      var redToken = engine.tokens[0];
      redToken.state = TokenState.track;
      redToken.position = 4;

      var greenToken = engine.tokens[4];
      greenToken.state = TokenState.track;
      greenToken.position = 8; // 8 is a safe square

      engine.currentDice = 4; // 4 + 4 = 8

      engine.moveToken(redToken);

      expect(redToken.position, 8);
      expect(greenToken.state, TokenState.track); // Green token is safe
      expect(greenToken.position, 8); // Both share square
    });

    test('Tokens enter home stretch properly', () {
      final engine = LudoGameEngine();

      var redToken = engine.tokens[0];
      redToken.state = TokenState.track;
      redToken.position = 48; // Near home

      engine.currentDice = 4; // 48 + 4 = 52. 52-51 = 1 (home stretch)

      engine.moveToken(redToken);

      expect(redToken.state, TokenState.homeStretch);
      expect(redToken.position, 1);
    });

    test('Token requires exact roll to reach home', () {
      final engine = LudoGameEngine();

      var redToken = engine.tokens[0];
      redToken.state = TokenState.homeStretch;
      redToken.position = 4; // 1 away from 5 (home)

      engine.currentDice = 2; // Too high

      expect(engine.getValidMoves().contains(redToken), false);

      engine.currentDice = 1; // Exact match
      expect(engine.getValidMoves().contains(redToken), true);

      engine.moveToken(redToken);

      expect(redToken.state, TokenState.home);
    });
  });
}
