import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'ludo/ludo_engine.dart';
import 'ludo/ludo_board_painter.dart';
import 'ludo/ludo_dice_widget.dart';
import 'ludo/ludo_setup_screen.dart';

class LudoScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const LudoScreen({super.key, required this.sessionId});

  @override
  ConsumerState<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends ConsumerState<LudoScreen> with SingleTickerProviderStateMixin {
  LudoGameEngine? _engine;
  bool _inSetup = true;
  bool _isSubmitting = false;
  bool _isRolling = false;
  bool _isProcessingMove = false;
  String _statusMessage = 'Your turn! Tap your dice to roll.';
  Timer? _botTimer;

  // Individual dice values tracked for each player
  final Map<int, int?> _playerLastDice = {};

  // Pulse animation for selectable tokens and active player's dice
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStartGameFromSetup(LudoGameEngine engine) {
    _botTimer?.cancel();
    setState(() {
      _engine = engine;
      _inSetup = false;
      _isRolling = false;
      _isProcessingMove = false;
      _playerLastDice.clear();
      for (var p in engine.players) {
        _playerLastDice[p.id] = null;
      }
      _updateStatusForCurrentTurn();
    });

    _checkComputerTurn();
  }

  void _updateStatusForCurrentTurn() {
    if (_engine == null) return;
    final current = _engine!.currentPlayer;
    if (_engine!.isGameOver) {
      _statusMessage = 'Game Over!';
    } else if (current.isComputer) {
      _statusMessage = '${current.name} is rolling...';
    } else {
      _statusMessage = '${current.name} • Tap your dice to roll';
    }
  }

  void _onRollDice() {
    if (_engine == null ||
        _engine!.isGameOver ||
        _engine!.currentDice != null ||
        _isRolling ||
        _isProcessingMove) {
      return;
    }

    final current = _engine!.currentPlayer;
    if (current.isComputer) return; // Only human can tap to roll

    setState(() {
      _isRolling = true;
      _statusMessage = '${current.name} is rolling...';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _engine == null) return;

      setState(() {
        _isRolling = false;
        _engine!.rollDice();
        final int rolled = _engine!.currentDice ?? 1;
        _playerLastDice[current.id] = rolled;

        final validMoves = _engine!.getValidMoves();
        if (validMoves.isEmpty) {
          _statusMessage = '${current.name} rolled $rolled • No legal moves';
          _isProcessingMove = true;
          Future.delayed(const Duration(milliseconds: 950), () {
            if (!mounted || _engine == null) return;
            setState(() {
              _engine!.passTurn();
              _isProcessingMove = false;
              _updateStatusForCurrentTurn();
            });
            _checkComputerTurn();
          });
        } else {
          _statusMessage = '${current.name} rolled $rolled • Tap a glowing token to move';
        }
      });
    });
  }

  void _onTokenTapped(LudoToken token) {
    if (_engine == null ||
        _engine!.isGameOver ||
        _engine!.currentDice == null ||
        _isRolling ||
        _isProcessingMove) {
      return;
    }

    final current = _engine!.currentPlayer;
    if (current.isComputer) return;

    setState(() {
      _isProcessingMove = true;
      bool moved = _engine!.moveToken(token);
      if (moved) {
        if (_engine!.isGameOver) {
          _statusMessage = 'Game Over!';
          _isProcessingMove = false;
          _submitGame();
        } else if (_engine!.currentPlayer == current && _engine!.currentDice == null) {
          // Extra turn granted!
          _statusMessage = 'Extra turn for ${current.name}! Tap your dice to roll again.';
          _isProcessingMove = false;
        } else {
          _isProcessingMove = false;
          _updateStatusForCurrentTurn();
          _checkComputerTurn();
        }
      } else {
        _isProcessingMove = false;
      }
    });
  }

  void _checkComputerTurn() {
    if (_engine == null || _engine!.isGameOver || !mounted) return;

    final current = _engine!.currentPlayer;
    if (!current.isComputer) return;

    setState(() {
      _statusMessage = '${current.name} is thinking...';
    });

    _botTimer = Timer(const Duration(milliseconds: 550), () {
      if (!mounted || _engine == null || !_engine!.currentPlayer.isComputer) return;

      setState(() {
        _isRolling = true;
        _statusMessage = '${current.name} is rolling...';
      });

      _botTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _engine == null || !_engine!.currentPlayer.isComputer) return;

        setState(() {
          _isRolling = false;
          _engine!.rollDice();
        });

        final int rolled = _engine!.currentDice ?? 1;
        _playerLastDice[current.id] = rolled;
        final bestToken = _engine!.getBestComputerMove();

        if (bestToken == null) {
          setState(() {
            _statusMessage = '${current.name} rolled $rolled • No legal moves';
          });

          _botTimer = Timer(const Duration(milliseconds: 850), () {
            if (!mounted || _engine == null) return;
            setState(() {
              _engine!.passTurn();
              _updateStatusForCurrentTurn();
            });
            _checkComputerTurn();
          });
        } else {
          setState(() {
            _statusMessage = '${current.name} rolled $rolled • Moving token...';
          });

          _botTimer = Timer(const Duration(milliseconds: 700), () {
            if (!mounted || _engine == null) return;
            setState(() {
              _engine!.moveToken(bestToken);
              if (_engine!.isGameOver) {
                _statusMessage = 'Game Over!';
                _submitGame();
              } else {
                _updateStatusForCurrentTurn();
                _checkComputerTurn();
              }
            });
          });
        }
      });
    });
  }

  Future<void> _submitGame() async {
    if (_isSubmitting || _engine == null) return;
    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final bool isWinner = _engine!.winners.isNotEmpty && !_engine!.winners.first.isComputer;
      final int score = isWinner ? 100 : 0;

      await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
        'score': score,
        'is_winner': isWinner,
        'state_data': {
          'mode': _engine!.gameMode.name,
          'player_count': _engine!.players.length,
          'capture_rule': _engine!.captureRule.name,
          'winner': _engine!.winners.first.name,
        },
      });
    } catch (_) {
      // Continue without interrupting victory display
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _restartCurrentGame() {
    _botTimer?.cancel();
    if (_engine == null) return;
    setState(() {
      _engine = LudoGameEngine.custom(
        players: _engine!.players,
        gameMode: _engine!.gameMode,
        captureRule: _engine!.captureRule,
      );
      _isRolling = false;
      _isProcessingMove = false;
      _playerLastDice.clear();
      for (var p in _engine!.players) {
        _playerLastDice[p.id] = null;
      }
      _updateStatusForCurrentTurn();
    });
    _checkComputerTurn();
  }

  bool get _isGameInProgress =>
      !_inSetup && _engine != null && !_engine!.isGameOver;

  Future<bool> _showExitConfirmationDialog({
    String title = 'Exit Game?',
    String message =
        'Are you sure you want to exit? A game is currently in progress. If you leave now, your current match progress will be lost.',
    String confirmLabel = 'Exit Game',
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Resume Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showRulesDialog() {
    if (_engine == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: Color(0xFFC2185B)),
                  const SizedBox(width: 10),
                  const Text(
                    'Active Game Rules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              _buildRuleInfoRow(
                'Game Mode',
                _engine!.gameMode == LudoGameMode.vsComputer
                    ? 'Play Against Computer (${_engine!.players.length} Players)'
                    : 'Pass & Play (${_engine!.players.length} Players on 1 device)',
              ),
              _buildRuleInfoRow(
                'Individual Dice',
                'Each player has their own individual dice located at their board corner.',
              ),
              _buildRuleInfoRow(
                'Capture Rule',
                _engine!.captureRule == LudoCaptureRule.captureAndSendHome
                    ? 'Capture and Send Home (Safe squares protected, capture grants extra turn)'
                    : 'No Capture (Multiple tokens share squares peacefully)',
              ),
              _buildRuleInfoRow('Exit Base', 'Requires rolling a 6 to enter the track.'),
              _buildRuleInfoRow(
                'Extra Turn',
                'Granted on rolling a 6${_engine!.captureRule == LudoCaptureRule.captureAndSendHome ? ' or capturing an opponent.' : '.'}',
              ),
              _buildRuleInfoRow('Finishing', 'Exact roll required to reach the center home.'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Point<int> _getTrackCoordinate(int pos) {
    const track = [
      Point(1, 6), Point(2, 6), Point(3, 6), Point(4, 6), Point(5, 6),
      Point(6, 5), Point(6, 4), Point(6, 3), Point(6, 2), Point(6, 1), Point(6, 0),
      Point(7, 0), Point(8, 0),
      Point(8, 1), Point(8, 2), Point(8, 3), Point(8, 4), Point(8, 5),
      Point(9, 6), Point(10, 6), Point(11, 6), Point(12, 6), Point(13, 6), Point(14, 6),
      Point(14, 7), Point(14, 8),
      Point(13, 8), Point(12, 8), Point(11, 8), Point(10, 8), Point(9, 8),
      Point(8, 9), Point(8, 10), Point(8, 11), Point(8, 12), Point(8, 13), Point(8, 14),
      Point(7, 14), Point(6, 14),
      Point(6, 13), Point(6, 12), Point(6, 11), Point(6, 10), Point(6, 9),
      Point(5, 8), Point(4, 8), Point(3, 8), Point(2, 8), Point(1, 8),
      Point(0, 8), Point(0, 7), Point(0, 6)
    ];
    return track[pos % 52];
  }

  Point<int> _getHomeStretchCoordinate(LudoColor color, int pos) {
    if (pos >= 5) return const Point(7, 7);
    switch (color) {
      case LudoColor.red:
        return Point(1 + pos, 7);
      case LudoColor.green:
        return Point(7, 1 + pos);
      case LudoColor.yellow:
        return Point(13 - pos, 7);
      case LudoColor.blue:
        return Point(7, 13 - pos);
    }
  }

  Point<double> _getBaseCoordinate(LudoColor color, int index) {
    double bx = 0, by = 0;
    switch (color) {
      case LudoColor.red:
        bx = 0;
        by = 0;
        break;
      case LudoColor.green:
        bx = 9;
        by = 0;
        break;
      case LudoColor.yellow:
        bx = 9;
        by = 9;
        break;
      case LudoColor.blue:
        bx = 0;
        by = 9;
        break;
    }
    double dx = index % 2 == 0 ? 1.5 : 3.5;
    double dy = index < 2 ? 1.5 : 3.5;
    return Point(bx + dx, by + dy);
  }

  Color _getFlutterColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Color(0xFFE53935);
      case LudoColor.green:
        return const Color(0xFF2E7D32);
      case LudoColor.yellow:
        return const Color(0xFFF9A825);
      case LudoColor.blue:
        return const Color(0xFF1565C0);
    }
  }

  int _getTokensHomeCount(LudoColor color) {
    if (_engine == null) return 0;
    return _engine!.tokens.where((t) => t.color == color && t.state == TokenState.home).length;
  }

  LudoPlayer? _getPlayerByColor(LudoColor color) {
    if (_engine == null) return null;
    for (var p in _engine!.players) {
      if (p.color == color) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_inSetup || _engine == null) {
      return LudoSetupScreen(onStartGame: _onStartGameFromSetup);
    }

    final currentPlayer = _engine!.currentPlayer;
    final activeColor = _getFlutterColor(currentPlayer.color);

    // In Vs Computer mode, orient the game so the Human player is ALWAYS at the bottom!
    final bool isVsComputer = _engine!.gameMode == LudoGameMode.vsComputer;
    final humanPlayer = _engine!.players.firstWhere(
      (p) => !p.isComputer,
      orElse: () => _engine!.players.first,
    );

    // If human chose Red (top-left) or Green (top-right), invert the board by 180° (2 quarter turns)
    // so the human's quadrant base and dice pod are situated at the bottom.
    final bool shouldInvert = isVsComputer &&
        (humanPlayer.color == LudoColor.red || humanPlayer.color == LudoColor.green);
    final int boardQuarterTurns = shouldInvert ? 2 : 0;

    // Corner mapping after possible 180° rotation:
    // When inverted (180°): Top-Left is Yellow, Top-Right is Blue, Bottom-Left is Green, Bottom-Right is Red.
    // When normal (0°):     Top-Left is Red,    Top-Right is Green, Bottom-Left is Blue,  Bottom-Right is Yellow.
    final topLeftPlayer = _getPlayerByColor(shouldInvert ? LudoColor.yellow : LudoColor.red);
    final topRightPlayer = _getPlayerByColor(shouldInvert ? LudoColor.blue : LudoColor.green);
    final bottomLeftPlayer = _getPlayerByColor(shouldInvert ? LudoColor.green : LudoColor.blue);
    final bottomRightPlayer = _getPlayerByColor(shouldInvert ? LudoColor.red : LudoColor.yellow);

    return PopScope(
      canPop: !_isGameInProgress,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final bool shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && mounted) {
          navigator.pop();
        }
      },
      child: Container(
        color: const Color(0xFFF7F8FA),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2185B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _engine!.gameMode == LudoGameMode.vsComputer
                            ? 'Vs Computer • ${_engine!.players.length}P'
                            : 'Pass & Play • ${_engine!.players.length}P',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC2185B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _engine!.captureRule == LudoCaptureRule.captureAndSendHome
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _engine!.captureRule == LudoCaptureRule.captureAndSendHome ? 'Capture' : 'No Capture',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _engine!.captureRule == LudoCaptureRule.captureAndSendHome
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'Rules',
                      onPressed: _showRulesDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Restart',
                      onPressed: () async {
                        if (_isGameInProgress) {
                          final shouldRestart = await _showExitConfirmationDialog(
                            title: 'Restart Game?',
                            message: 'A game is currently in progress. Are you sure you want to restart? Current progress will be lost.',
                            confirmLabel: 'Restart',
                          );
                          if (!shouldRestart || !mounted) return;
                        }
                        _restartCurrentGame();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      tooltip: 'Change Setup',
                      onPressed: () async {
                        if (_isGameInProgress) {
                          final shouldChange = await _showExitConfirmationDialog(
                            title: 'Change Setup?',
                            message: 'A game is currently in progress. Changing setup will abandon the current game.',
                            confirmLabel: 'Change Setup',
                          );
                          if (!shouldChange || !mounted) return;
                        }
                        _botTimer?.cancel();
                        setState(() => _inSetup = true);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // 2. Status Ribbon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: activeColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activeColor.computeLuminance() > 0.5 ? Colors.black87 : activeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Top Player Stations Row (Opponents / Bots)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  topLeftPlayer != null
                      ? _buildPlayerStationPod(topLeftPlayer, isLeftAligned: true)
                      : const SizedBox.shrink(),
                  topRightPlayer != null
                      ? _buildPlayerStationPod(topRightPlayer, isLeftAligned: false)
                      : const SizedBox.shrink(),
                ],
              ),
            ),

            // 4. Central Square Ludo Board
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableWidth = constraints.maxWidth;
                  final double availableHeight = constraints.maxHeight;
                  final double boardSize = min(availableWidth - 16, availableHeight - 12).clamp(0.0, 560.0);
                  if (boardSize <= 0) return const SizedBox.shrink();

                  final double cellSize = boardSize / 15.0;

                  // Group tokens by cell coordinate to prevent overlap in No Capture mode
                  final Map<String, List<LudoToken>> cellTokensMap = {};
                  for (var token in _engine!.tokens) {
                    double cx = 0, cy = 0;
                    if (token.state == TokenState.base) {
                      final p = _getBaseCoordinate(token.color, token.id % 4);
                      cx = p.x - 0.5;
                      cy = p.y - 0.5;
                    } else if (token.state == TokenState.track) {
                      final p = _getTrackCoordinate(token.position);
                      cx = p.x.toDouble();
                      cy = p.y.toDouble();
                    } else if (token.state == TokenState.homeStretch || token.state == TokenState.home) {
                      final int pos = token.state == TokenState.home ? 5 : token.position;
                      final p = _getHomeStretchCoordinate(token.color, pos);
                      cx = p.x.toDouble();
                      cy = p.y.toDouble();
                    }
                    final key = '${cx.toStringAsFixed(1)},${cy.toStringAsFixed(1)}';
                    cellTokensMap.putIfAbsent(key, () => []).add(token);
                  }

                  final List<Widget> tokenWidgets = [];

                  cellTokensMap.forEach((key, tokenGroup) {
                    final parts = key.split(',');
                    final double baseCellX = double.parse(parts[0]) * cellSize;
                    final double baseCellY = double.parse(parts[1]) * cellSize;
                    final int count = tokenGroup.length;

                    for (int i = 0; i < count; i++) {
                      final token = tokenGroup[i];
                      double offsetX = 0;
                      double offsetY = 0;
                      double tokenScale = 0.76;

                      if (count == 1) {
                        offsetX = cellSize * 0.12;
                        offsetY = cellSize * 0.12;
                      } else if (count == 2) {
                        tokenScale = 0.54;
                        if (i == 0) {
                          offsetX = cellSize * 0.05;
                          offsetY = cellSize * 0.05;
                        } else {
                          offsetX = cellSize * 0.42;
                          offsetY = cellSize * 0.42;
                        }
                      } else if (count == 3) {
                        tokenScale = 0.48;
                        if (i == 0) {
                          offsetX = cellSize * 0.26;
                          offsetY = cellSize * 0.05;
                        } else if (i == 1) {
                          offsetX = cellSize * 0.05;
                          offsetY = cellSize * 0.48;
                        } else {
                          offsetX = cellSize * 0.48;
                          offsetY = cellSize * 0.48;
                        }
                      } else {
                        tokenScale = 0.46;
                        if (i % 4 == 0) {
                          offsetX = cellSize * 0.04;
                          offsetY = cellSize * 0.04;
                        } else if (i % 4 == 1) {
                          offsetX = cellSize * 0.50;
                          offsetY = cellSize * 0.04;
                        } else if (i % 4 == 2) {
                          offsetX = cellSize * 0.04;
                          offsetY = cellSize * 0.50;
                        } else {
                          offsetX = cellSize * 0.50;
                          offsetY = cellSize * 0.50;
                        }
                      }

                      final bool isHumanTurn = !_engine!.currentPlayer.isComputer;
                      final bool isSelectable = isHumanTurn &&
                          _engine!.currentDice != null &&
                          !_isRolling &&
                          !_isProcessingMove &&
                          _engine!.getValidMoves().any((t) => t.id == token.id);

                      final Color tokenFlutterColor = _getFlutterColor(token.color);

                      tokenWidgets.add(
                        AnimatedPositioned(
                          key: ValueKey('token_${token.id}'),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutBack,
                          left: baseCellX + offsetX,
                          top: baseCellY + offsetY,
                          width: cellSize * tokenScale,
                          height: cellSize * tokenScale,
                          child: GestureDetector(
                            onTap: isSelectable ? () => _onTokenTapped(token) : null,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                final double scale = isSelectable ? _pulseAnimation.value : 1.0;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.3, -0.3),
                                        radius: 0.8,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.9),
                                          tokenFlutterColor,
                                          tokenFlutterColor.withValues(alpha: 0.85),
                                        ],
                                        stops: const [0.0, 0.45, 1.0],
                                      ),
                                      border: Border.all(
                                        color: isSelectable ? Colors.amber : Colors.white,
                                        width: isSelectable ? 2.5 : 1.8,
                                      ),
                                      boxShadow: isSelectable
                                          ? [
                                              BoxShadow(
                                                color: Colors.amber.withValues(alpha: 0.9),
                                                blurRadius: 10,
                                                spreadRadius: 3,
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.35),
                                                blurRadius: 3,
                                                offset: const Offset(1, 2),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.35),
                                                blurRadius: 3,
                                                offset: const Offset(1, 1),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: cellSize * tokenScale * 0.4,
                                        height: cellSize * tokenScale * 0.4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                        child: Icon(
                                          Icons.circle,
                                          size: cellSize * tokenScale * 0.24,
                                          color: tokenFlutterColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  });

                  return Center(
                    child: RotatedBox(
                      quarterTurns: boardQuarterTurns,
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: Size(boardSize, boardSize),
                              painter: LudoBoardPainter(_engine!),
                            ),
                            ...tokenWidgets,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 5. Bottom Player Stations Row (Human Player Always Here)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  bottomLeftPlayer != null
                      ? _buildPlayerStationPod(bottomLeftPlayer, isLeftAligned: true)
                      : const SizedBox.shrink(),
                  bottomRightPlayer != null
                      ? _buildPlayerStationPod(bottomRightPlayer, isLeftAligned: false)
                      : const SizedBox.shrink(),
                ],
              ),
            ),

            // 6. Victory Overlay if Game Over
            if (_engine!.isGameOver)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: (_engine!.winners.isNotEmpty && !_engine!.winners.first.isComputer)
                    ? Colors.green.shade600
                    : Colors.deepOrange.shade600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _engine!.winners.isNotEmpty && !_engine!.winners.first.isComputer
                          ? '🎉 ${_engine!.winners.first.name} Won!'
                          : '🏆 ${_engine!.winners.first.name} Won!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _inSetup = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  // Individual Player Station with their Own Dedicated Dice!
  Widget _buildPlayerStationPod(LudoPlayer player, {required bool isLeftAligned}) {
    final bool isSmallScreen = MediaQuery.sizeOf(context).width < 380;
    final double maxNameWidth = isSmallScreen ? 60.0 : 80.0;
    final double diceSize = isSmallScreen ? 40.0 : 46.0;

    final bool isCurrentTurn = _engine!.currentPlayer.id == player.id && !_engine!.isGameOver;
    final Color playerColor = _getFlutterColor(player.color);
    final int homeCount = _getTokensHomeCount(player.color);
    final bool isHuman = !player.isComputer;
    final bool canRollThisDice = isCurrentTurn && isHuman && _engine!.currentDice == null && !_isRolling && !_isProcessingMove;
    final bool isThisDiceRolling = _isRolling && isCurrentTurn;

    final infoWidget = Column(
      crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLeftAligned) ...[
              Icon(
                player.isComputer ? Icons.smart_toy_outlined : Icons.person_outline,
                size: 13,
                color: isCurrentTurn ? playerColor : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxNameWidth),
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrentTurn ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrentTurn ? playerColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isLeftAligned) ...[
              const SizedBox(width: 4),
              Icon(
                player.isComputer ? Icons.smart_toy_outlined : Icons.person_outline,
                size: 13,
                color: isCurrentTurn ? playerColor : Colors.grey.shade700,
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: playerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Home: $homeCount/4',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    final diceWidget = LudoDiceWidget(
      value: _playerLastDice[player.id],
      isRolling: isThisDiceRolling,
      canRoll: canRollThisDice,
      onTap: canRollThisDice ? _onRollDice : null,
      activeColor: playerColor,
      size: diceSize,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTurn ? playerColor.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTurn ? playerColor : Colors.grey.shade300,
          width: isCurrentTurn ? 2.2 : 1.0,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: playerColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeftAligned
            ? [
                infoWidget,
                const SizedBox(width: 10),
                diceWidget,
              ]
            : [
                diceWidget,
                const SizedBox(width: 10),
                infoWidget,
              ],
      ),
    );
  }
}
