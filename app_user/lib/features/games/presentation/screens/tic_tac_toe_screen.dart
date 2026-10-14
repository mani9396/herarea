import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

enum GameMode {
  passAndPlay('2 Players', Icons.people_alt_rounded),
  vsComputer('vs Computer', Icons.smart_toy_rounded);

  final String label;
  final IconData icon;
  const GameMode(this.label, this.icon);
}

class TicTacToeScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const TicTacToeScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen>
    with SingleTickerProviderStateMixin {
  late List<String?> _board;
  GameMode _mode = GameMode.passAndPlay;
  bool _isPlayerXTurn = true;
  String? _winner; // 'X', 'O', or null
  bool _isDraw = false;
  List<int>? _winningLine;
  bool _isAiThinking = false;
  bool _isSubmitting = false;

  int _xWins = 0;
  int _oWins = 0;
  int _ties = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _resetBoard();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resetBoard() {
    setState(() {
      _board = List.filled(9, null);
      _isPlayerXTurn = true;
      _winner = null;
      _isDraw = false;
      _winningLine = null;
      _isAiThinking = false;
    });
  }

  void _resetFullMatch() {
    setState(() {
      _xWins = 0;
      _oWins = 0;
      _ties = 0;
    });
    _resetBoard();
  }

  Future<void> _submitScore(bool isWinner, int score) async {
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
        'score': score,
        'is_winner': isWinner,
      });
    } catch (_) {
      // Non-critical background save failure
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _makeMove(int index) {
    if (_board[index] != null || _winner != null || _isDraw || _isAiThinking) return;

    final currentMark = _isPlayerXTurn ? 'X' : 'O';

    setState(() {
      _board[index] = currentMark;
      _isPlayerXTurn = !_isPlayerXTurn;
    });

    final winLine = _findWinningLine(currentMark);
    if (winLine != null) {
      setState(() {
        _winner = currentMark;
        _winningLine = winLine;
        if (currentMark == 'X') {
          _xWins++;
        } else {
          _oWins++;
        }
      });
      _submitScore(currentMark == 'X', 100);
      return;
    }

    if (_checkDraw()) {
      setState(() {
        _isDraw = true;
        _ties++;
      });
      _submitScore(false, 50);
      return;
    }

    // AI Turn in vsComputer mode
    if (_mode == GameMode.vsComputer && !_isPlayerXTurn) {
      setState(() => _isAiThinking = true);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        _executeAiMove();
      });
    }
  }

  void _executeAiMove() {
    if (_winner != null || _isDraw) return;

    // Smart AI: 1. Win if possible, 2. Block X, 3. Take center, 4. Corners, 5. Random
    int? bestMove = _findWinningMove('O');
    bestMove ??= _findWinningMove('X'); // Block
    if (bestMove == null && _board[4] == null) {
      bestMove = 4; // Center
    }
    if (bestMove == null) {
      final corners = [0, 2, 6, 8].where((i) => _board[i] == null).toList();
      if (corners.isNotEmpty) {
        corners.shuffle();
        bestMove = corners.first;
      }
    }
    if (bestMove == null) {
      final available = <int>[];
      for (int i = 0; i < 9; i++) {
        if (_board[i] == null) available.add(i);
      }
      if (available.isNotEmpty) {
        available.shuffle();
        bestMove = available.first;
      }
    }

    if (bestMove != null) {
      setState(() {
        _board[bestMove!] = 'O';
        _isPlayerXTurn = true;
        _isAiThinking = false;
      });

      final winLine = _findWinningLine('O');
      if (winLine != null) {
        setState(() {
          _winner = 'O';
          _winningLine = winLine;
          _oWins++;
        });
        _submitScore(false, 0);
        return;
      }

      if (_checkDraw()) {
        setState(() {
          _isDraw = true;
          _ties++;
        });
        _submitScore(false, 50);
        return;
      }
    } else {
      setState(() => _isAiThinking = false);
    }
  }

  int? _findWinningMove(String mark) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (final line in lines) {
      final a = _board[line[0]];
      final b = _board[line[1]];
      final c = _board[line[2]];
      if (a == mark && b == mark && c == null) return line[2];
      if (a == mark && c == mark && b == null) return line[1];
      if (b == mark && c == mark && a == null) return line[0];
    }
    return null;
  }

  List<int>? _findWinningLine(String mark) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];
    for (final line in lines) {
      if (_board[line[0]] == mark &&
          _board[line[1]] == mark &&
          _board[line[2]] == mark) {
        return line;
      }
    }
    return null;
  }

  bool _checkDraw() {
    return !_board.contains(null);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double maxBoardWidth = min(screenWidth - 40, 360.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isSubmitting)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primaryRuby,
                ),

              // Mode Selector (Person to Person vs AI)
              _buildModeSelector(),

              const SizedBox(height: 14),

              // Luxury Scoreboard
              _buildScoreboard(),

              const SizedBox(height: 16),

              // Turn Status Badge
              _buildTurnStatusBadge(),

              const SizedBox(height: 18),

              // Game Arena Board
              _buildArenaBoard(maxBoardWidth),

              const SizedBox(height: 20),

              // Post-Round Action / Bottom Controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: GameMode.values.map((mode) {
          final isSelected = _mode == mode;
          return GestureDetector(
            onTap: () {
              if (_mode != mode) {
                setState(() => _mode = mode);
                _resetFullMatch();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    mode.icon,
                    size: 16,
                    color: isSelected ? AppColors.primaryRuby : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryRuby : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreboard() {
    final bool isXActive = _isPlayerXTurn && _winner == null && !_isDraw;
    final bool isOActive = !_isPlayerXTurn && _winner == null && !_isDraw;

    final String player2Label = _mode == GameMode.passAndPlay ? 'Player 2' : 'Computer';

    return Row(
      children: [
        // Player X Card
        Expanded(
          child: _buildPlayerCard(
            title: _mode == GameMode.passAndPlay ? 'Player 1' : 'Player (X)',
            symbol: 'X',
            score: _xWins,
            symbolColor: const Color(0xFFE11D48),
            symbolGradient: const [Color(0xFFFB7185), Color(0xFFE11D48)],
            isActive: isXActive,
          ),
        ),
        const SizedBox(width: 8),

        // Ties Card
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DRAWS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_ties',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Player O Card
        Expanded(
          child: _buildPlayerCard(
            title: player2Label,
            symbol: 'O',
            score: _oWins,
            symbolColor: const Color(0xFF0284C7),
            symbolGradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
            isActive: isOActive,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String title,
    required String symbol,
    required int score,
    required Color symbolColor,
    required List<Color> symbolGradient,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? symbolColor : const Color(0xFFE2E8F0),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? symbolColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isActive ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: symbolGradient),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: symbolColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnStatusBadge() {
    String message;
    Color badgeColor;
    IconData badgeIcon;

    if (_winner != null) {
      if (_winner == 'X') {
        message = _mode == GameMode.passAndPlay ? '🎉 Player 1 (X) Wins!' : '🎉 You Won!';
        badgeColor = const Color(0xFFE11D48);
        badgeIcon = Icons.emoji_events_rounded;
      } else {
        message = _mode == GameMode.passAndPlay ? '🎉 Player 2 (O) Wins!' : '🤖 Computer Won!';
        badgeColor = const Color(0xFF0284C7);
        badgeIcon = Icons.emoji_events_rounded;
      }
    } else if (_isDraw) {
      message = '🤝 It\'s a Draw!';
      badgeColor = const Color(0xFF64748B);
      badgeIcon = Icons.handshake_rounded;
    } else if (_isAiThinking) {
      message = '🤖 Computer is thinking...';
      badgeColor = const Color(0xFF0284C7);
      badgeIcon = Icons.hourglass_top_rounded;
    } else if (_isPlayerXTurn) {
      message = _mode == GameMode.passAndPlay ? 'Player 1\'s Turn (X)' : 'Your Turn (X)';
      badgeColor = const Color(0xFFE11D48);
      badgeIcon = Icons.touch_app_rounded;
    } else {
      message = 'Player 2\'s Turn (O)';
      badgeColor = const Color(0xFF0284C7);
      badgeIcon = Icons.touch_app_rounded;
    }

    final bool isFinished = _winner != null || _isDraw;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isFinished ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 16, color: badgeColor),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: badgeColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArenaBoard(double boardSize) {
    return Container(
      width: boardSize,
      height: boardSize,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0F172A), // Slate 900
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryRuby.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final mark = _board[index];
          final isWinningTile = _winningLine != null && _winningLine!.contains(index);

          return _buildGridTile(index, mark, isWinningTile);
        },
      ),
    );
  }

  Widget _buildGridTile(int index, String? mark, bool isWinningTile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makeMove(index),
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primaryRuby.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isWinningTile
                ? const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isWinningTile
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFF475569).withValues(alpha: 0.6),
              width: isWinningTile ? 2.5 : 1.2,
            ),
            boxShadow: [
              if (isWinningTile)
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(
            child: mark == null
                ? const SizedBox.shrink()
                : _buildMarkGlyph(mark, isWinningTile),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkGlyph(String mark, bool isWinningTile) {
    if (mark == 'X') {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Icon(
          Icons.close_rounded,
          size: 58,
          color: isWinningTile ? Colors.white : const Color(0xFFFB7185),
          shadows: [
            Shadow(
              color: isWinningTile
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFFE11D48).withValues(alpha: 0.8),
              blurRadius: 12,
            ),
          ],
        ),
      );
    } else {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Icon(
          Icons.radio_button_unchecked_rounded,
          size: 50,
          color: isWinningTile ? Colors.white : const Color(0xFF38BDF8),
          shadows: [
            Shadow(
              color: isWinningTile
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFF0284C7).withValues(alpha: 0.8),
              blurRadius: 12,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBottomControls() {
    final bool isGameOver = _winner != null || _isDraw;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isGameOver)
          ElevatedButton.icon(
            onPressed: _resetBoard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRuby,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: const Text(
              'NEXT ROUND',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _resetBoard,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear Grid', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: _resetFullMatch,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Reset Match', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
