import 'dart:math';

enum LudoColor { red, green, yellow, blue }

enum TokenState { base, track, homeStretch, home }

enum LudoGameMode { vsComputer, passAndPlay }

enum LudoCaptureRule { captureAndSendHome, noCapture }

class LudoPlayer {
  final int id;
  final LudoColor color;
  final String name;
  final bool isComputer;

  const LudoPlayer({
    required this.id,
    required this.color,
    required this.name,
    this.isComputer = false,
  });

  LudoPlayer copyWith({
    int? id,
    LudoColor? color,
    String? name,
    bool? isComputer,
  }) {
    return LudoPlayer(
      id: id ?? this.id,
      color: color ?? this.color,
      name: name ?? this.name,
      isComputer: isComputer ?? this.isComputer,
    );
  }
}

class LudoToken {
  final int id;
  final LudoColor color;
  TokenState state;
  int position; // 0-51 for track, 0-5 for homeStretch. Ignored for base and home.

  LudoToken({required this.id, required this.color, this.state = TokenState.base, this.position = -1});

  LudoToken clone() {
    return LudoToken(id: id, color: color, state: state, position: position);
  }
}

class LudoGameEngine {
  final Random _random = Random();
  final LudoGameMode gameMode;
  final LudoCaptureRule captureRule;
  final List<LudoPlayer> players;

  late List<LudoToken> tokens;
  late int currentTurnIndex; // index in players list (0..players.length - 1)
  int? currentDice;
  bool isGameOver = false;
  List<LudoPlayer> winners = [];

  static const List<int> safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];
  static const Map<LudoColor, int> startPositions = {
    LudoColor.red: 0,
    LudoColor.green: 13,
    LudoColor.yellow: 26,
    LudoColor.blue: 39,
  };
  static const Map<LudoColor, int> endPositions = {
    LudoColor.red: 50,
    LudoColor.green: 11,
    LudoColor.yellow: 24,
    LudoColor.blue: 37,
  };

  LudoPlayer get currentPlayer => players[currentTurnIndex];
  int get currentTurn => currentPlayer.color.index; // For backward compatibility with painters

  // Default constructor for standard 4-player vs Computer
  LudoGameEngine()
      : gameMode = LudoGameMode.vsComputer,
        captureRule = LudoCaptureRule.captureAndSendHome,
        players = const [
          LudoPlayer(id: 0, color: LudoColor.red, name: 'You (Red)', isComputer: false),
          LudoPlayer(id: 1, color: LudoColor.green, name: 'Bot 1 (Green)', isComputer: true),
          LudoPlayer(id: 2, color: LudoColor.yellow, name: 'Bot 2 (Yellow)', isComputer: true),
          LudoPlayer(id: 3, color: LudoColor.blue, name: 'Bot 3 (Blue)', isComputer: true),
        ] {
    _initGame();
  }

  // Custom setup constructor
  LudoGameEngine.custom({
    required this.players,
    this.gameMode = LudoGameMode.vsComputer,
    this.captureRule = LudoCaptureRule.captureAndSendHome,
  }) {
    assert(players.length >= 2 && players.length <= 4, 'Must have 2, 3, or 4 players');
    _initGame();
  }

  void _initGame() {
    tokens = [];
    for (int p = 0; p < players.length; p++) {
      final player = players[p];
      for (int j = 0; j < 4; j++) {
        tokens.add(LudoToken(id: p * 4 + j, color: player.color));
      }
    }
    currentTurnIndex = 0;
    currentDice = null;
    isGameOver = false;
    winners = [];
  }

  void rollDice() {
    if (isGameOver || currentDice != null) return;
    currentDice = _random.nextInt(6) + 1;
  }

  void passTurn() {
    if (isGameOver) return;
    _nextTurn();
  }

  List<LudoToken> getValidMoves() {
    if (currentDice == null || isGameOver) return [];

    final LudoColor turnColor = currentPlayer.color;
    final List<LudoToken> validTokens = [];

    for (var token in tokens.where((t) => t.color == turnColor)) {
      if (token.state == TokenState.base) {
        if (currentDice == 6) validTokens.add(token);
      } else if (token.state == TokenState.track) {
        int stepsToHome = _calculateStepsToHome(token);
        if (currentDice! <= stepsToHome + 6) {
          validTokens.add(token);
        }
      } else if (token.state == TokenState.homeStretch) {
        if (token.position + currentDice! <= 5) {
          validTokens.add(token);
        }
      }
    }

    return validTokens;
  }

  int _calculateStepsTaken(LudoToken token) {
    if (token.state == TokenState.base) return 0;
    if (token.state == TokenState.homeStretch) return 51 + token.position + 1;
    if (token.state == TokenState.home) return 57;

    int start = startPositions[token.color]!;
    if (token.position >= start) {
      return token.position - start;
    } else {
      return (52 - start) + token.position;
    }
  }

  int _calculateStepsToHome(LudoToken token) {
    return 50 - _calculateStepsTaken(token);
  }

  bool moveToken(LudoToken tokenToMove) {
    if (currentDice == null || isGameOver) return false;
    if (!getValidMoves().any((t) => t.id == tokenToMove.id)) return false;

    bool grantedExtraTurn = currentDice == 6;

    if (tokenToMove.state == TokenState.base) {
      tokenToMove.state = TokenState.track;
      tokenToMove.position = startPositions[tokenToMove.color]!;
    } else if (tokenToMove.state == TokenState.homeStretch) {
      tokenToMove.position += currentDice!;
      if (tokenToMove.position == 5) {
        tokenToMove.state = TokenState.home;
      }
    } else if (tokenToMove.state == TokenState.track) {
      int stepsTaken = _calculateStepsTaken(tokenToMove);
      if (stepsTaken + currentDice! > 50) {
        // Entering home stretch
        tokenToMove.state = TokenState.homeStretch;
        tokenToMove.position = (stepsTaken + currentDice!) - 51;
        if (tokenToMove.position == 5) {
          tokenToMove.state = TokenState.home;
        }
      } else {
        // Moving along track
        tokenToMove.position = (tokenToMove.position + currentDice!) % 52;

        // Capture logic if rule is captureAndSendHome
        if (captureRule == LudoCaptureRule.captureAndSendHome &&
            !safeSquares.contains(tokenToMove.position)) {
          for (var other in tokens) {
            if (other.color != tokenToMove.color &&
                other.state == TokenState.track &&
                other.position == tokenToMove.position) {
              other.state = TokenState.base;
              other.position = -1;
              grantedExtraTurn = true;
            }
          }
        }
        // If captureRule == noCapture, tokens simply share the track position!
      }
    }

    _checkWin();

    if (!isGameOver) {
      if (!grantedExtraTurn) {
        _nextTurn();
      } else {
        currentDice = null; // Reset for extra turn
      }
    }

    return true;
  }

  void _nextTurn() {
    currentDice = null;
    if (isGameOver) return;
    do {
      currentTurnIndex = (currentTurnIndex + 1) % players.length;
    } while (winners.contains(players[currentTurnIndex]) && !isGameOver);
  }

  void _checkWin() {
    for (var player in players) {
      if (!winners.contains(player)) {
        bool allHome = tokens.where((t) => t.color == player.color).every((t) => t.state == TokenState.home);
        if (allHome) {
          winners.add(player);
        }
      }
    }
    // In a 2-player game, 1 winner finishes the game. In 3 or 4, game finishes when all but 1 are home.
    final int requiredWinners = players.length == 2 ? 1 : players.length - 1;
    if (winners.length >= requiredWinners) {
      isGameOver = true;
      currentDice = null;
    }
  }

  LudoToken? getBestComputerMove() {
    var validMoves = getValidMoves();
    if (validMoves.isEmpty) return null;

    LudoToken? bestToken;

    // In Capture and Send Home: prioritize capture
    if (captureRule == LudoCaptureRule.captureAndSendHome) {
      for (var token in validMoves) {
        if (token.state == TokenState.track) {
          int nextPos = (token.position + currentDice!) % 52;
          if (!safeSquares.contains(nextPos) &&
              tokens.any((t) => t.color != token.color && t.state == TokenState.track && t.position == nextPos)) {
            bestToken = token;
            break;
          }
        }
      }
    }

    // Next prioritize entering home stretch or home
    if (bestToken == null) {
      for (var token in validMoves) {
        if (token.state == TokenState.homeStretch) {
          bestToken = token;
          break;
        }
      }
    }

    // Next prioritize base exit on rolling a 6
    if (bestToken == null) {
      for (var token in validMoves) {
        if (token.state == TokenState.base) {
          bestToken = token;
          break;
        }
      }
    }

    // Default to the first valid move (furthest along)
    return bestToken ?? validMoves.first;
  }

  void playComputerTurn() {
    if (currentDice == null) rollDice();
    if (currentDice == null) return;

    var bestToken = getBestComputerMove();
    if (bestToken != null) {
      moveToken(bestToken);
    } else {
      passTurn();
    }
  }
}
