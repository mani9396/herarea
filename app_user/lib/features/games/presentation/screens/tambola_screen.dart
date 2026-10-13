import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'tambola/tambola_engine.dart';
import 'tambola/tambola_nicknames.dart';
import 'tambola/tambola_board_dialog.dart';
import 'tambola/tambola_ticket_widget.dart';
import 'tambola/tambola_claims_panel.dart';

class TambolaScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const TambolaScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TambolaScreen> createState() => _TambolaScreenState();
}

class _TambolaScreenState extends ConsumerState<TambolaScreen> with SingleTickerProviderStateMixin {
  late TambolaEngine _engine;
  int? _currentBall;
  Timer? _callerTimer;

  bool _isAutoCalling = true;
  Duration _callSpeed = const Duration(milliseconds: 3500);

  int _score = 0;
  bool _gameOver = false;
  bool _isSubmitting = false;
  String _statusMessage = 'Welcome to HER AREA Tambola! Tap your numbers as they appear.';

  late AnimationController _ballAnimController;
  late Animation<double> _ballScaleAnimation;

  @override
  void initState() {
    super.initState();
    _engine = TambolaEngine();
    _ballAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ballScaleAnimation = CurvedAnimation(
      parent: _ballAnimController,
      curve: Curves.elasticOut,
    );

    _startCaller();
  }

  @override
  void dispose() {
    _callerTimer?.cancel();
    _ballAnimController.dispose();
    super.dispose();
  }

  bool get _isGameInProgress => !_gameOver && _engine.calledNumbers.isNotEmpty;

  void _startCaller() {
    _callerTimer?.cancel();
    if (!_isAutoCalling || _gameOver) return;

    _callerTimer = Timer.periodic(_callSpeed, (timer) {
      if (!mounted || _gameOver) return;
      _drawNextBall();
    });
  }

  void _toggleAutoCall() {
    setState(() {
      _isAutoCalling = !_isAutoCalling;
      if (_isAutoCalling) {
        _statusMessage = 'Auto-calling resumed.';
        _startCaller();
      } else {
        _callerTimer?.cancel();
        _statusMessage = 'Auto-calling paused. Tap "Call Next" when ready.';
      }
    });
  }

  void _cycleSpeed() {
    setState(() {
      if (_callSpeed.inMilliseconds == 3500) {
        _callSpeed = const Duration(milliseconds: 2200); // Fast
      } else if (_callSpeed.inMilliseconds == 2200) {
        _callSpeed = const Duration(milliseconds: 5000); // Slow
      } else {
        _callSpeed = const Duration(milliseconds: 3500); // Normal
      }
    });
    if (_isAutoCalling) {
      _startCaller();
    }
  }

  String get _speedLabel {
    if (_callSpeed.inMilliseconds == 2200) return 'Fast (2s)';
    if (_callSpeed.inMilliseconds == 5000) return 'Slow (5s)';
    return 'Normal (3.5s)';
  }

  void _drawNextBall() {
    if (_gameOver) return;
    final int? next = _engine.callNextNumber();
    if (next == null) {
      _finishGame(won: false, reason: 'All 90 numbers have been called!');
      return;
    }

    _ballAnimController.forward(from: 0.0);

    setState(() {
      _currentBall = next;
      final nickname = getTambolaNickname(next);
      _statusMessage = '$nickname!';
    });

    // Automatically check if any pattern became achievable
    for (var prize in kTambolaPrizes) {
      if (!_engine.claimedPatterns.contains(prize.pattern) &&
          _engine.isPatternAchieved(prize.pattern)) {
        // Subtle hint in status
        _statusMessage = '${prize.title} is ready! Tap CLAIM below!';
        break;
      }
    }
  }

  void _onNumberTapped(int number) {
    if (_gameOver) return;

    final result = _engine.markNumber(number);
    if (result == 1) {
      // Successfully marked
      setState(() {
        _score += 15;
        _statusMessage = 'Struck $number! (+15 pts)';
      });

      // Check if Full House is achieved
      if (_engine.isPatternAchieved(TambolaPattern.fullHouse) &&
          !_engine.claimedPatterns.contains(TambolaPattern.fullHouse)) {
        _handleClaimPattern(TambolaPattern.fullHouse);
      }
    } else if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$number is already marked!'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == -1) {
      // Penalty/Warning for tapping uncalled number
      setState(() {
        if (_score >= 5) _score -= 5;
        _statusMessage = 'Warning: $number has not been called yet! (-5 pts)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$number has NOT been called yet! Watch the caller.'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleClaimPattern(TambolaPattern pattern) {
    if (_gameOver) return;

    final prize = kTambolaPrizes.firstWhere((p) => p.pattern == pattern);

    if (_engine.claimedPatterns.contains(pattern)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${prize.title} was already claimed!'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_engine.isPatternAchieved(pattern)) {
      final success = _engine.claimPattern(pattern);
      if (success) {
        setState(() {
          _score += prize.points;
          _statusMessage = '🎉 CLAIMED ${prize.title}! (+${prize.points} pts)';
        });

        _showClaimSuccessDialog(prize);

        // If Full House claimed, game won!
        if (pattern == TambolaPattern.fullHouse) {
          _finishGame(won: true, reason: 'FULL HOUSE! You completed the entire ticket!');
        }
      }
    } else {
      // Bogey / False claim penalty
      setState(() {
        if (_score >= 20) _score -= 20;
        _statusMessage = '❌ BOGEY! ${prize.title} is not finished yet. (-20 pts)';
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 26),
              SizedBox(width: 8),
              Text('Bogey Claim!'),
            ],
          ),
          content: Text(
            'You haven\'t completed all the required numbers for "${prize.title}" yet. Keep watching the caller balls!',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  void _showClaimSuccessDialog(TambolaPatternInfo prize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${prize.title} Won!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You successfully completed ${prize.title}.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    '+${prize.points} Bonus Points Added',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2185B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Playing'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishGame({required bool won, required String reason}) async {
    _callerTimer?.cancel();
    setState(() {
      _gameOver = true;
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
        'score': _score,
        'is_winner': won,
        'state_data': {
          'prizes_claimed': _engine.claimedPatterns.map((p) => p.name).toList(),
          'numbers_called': _engine.calledNumbers.length,
          'numbers_marked': _engine.markedNumbers.length,
        },
      });
    } catch (_) {
      // Keep going even if offline or session error
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (mounted) {
      _showGameOverDialog(won: won, reason: reason);
    }
  }

  void _showGameOverDialog({required bool won, required String reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              won ? Icons.workspace_premium_rounded : Icons.flag_rounded,
              color: won ? Colors.amber : const Color(0xFFC2185B),
              size: 32,
            ),
            const SizedBox(width: 10),
            Text(
              won ? 'TAMBOLA VICTORY!' : 'Game Completed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Final Score:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '$_score Points',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC2185B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Prizes Claimed: ${_engine.claimedPatterns.length}/6',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(
              'Marked Numbers: ${_engine.markedNumbers.length}/15',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to games screen
            },
            child: const Text('Back to Games'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2185B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    _callerTimer?.cancel();
    setState(() {
      _engine = TambolaEngine();
      _currentBall = null;
      _score = 0;
      _gameOver = false;
      _statusMessage = 'New game started! Watch the caller.';
      _isAutoCalling = true;
    });
    _startCaller();
  }

  Future<bool> _showExitConfirmationDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Exit Tambola?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'A game is currently in progress. If you exit now, your current score and ticket will be lost.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Resume Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Exit Game'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showRulesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: Color(0xFFC2185B)),
                  const SizedBox(width: 8),
                  const Text('HOW TO PLAY TAMBOLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const Divider(),
              const SizedBox(height: 6),
              const Text(
                'Tambola (also known as Housie or Indian Bingo) is a game of probability. Numbers 1 to 90 are drawn randomly one by one.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text('PRIZES & WINNING PATTERNS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...kTambolaPrizes.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              children: [
                                TextSpan(text: '${p.title} (+${p.points} pts): ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: p.description),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              const Text('IMPORTANT RULES:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              const Text(
                '• Struck number: Tapping a called number gives +15 points.\n'
                '• Bogey penalty: False prize claim deducts -20 points.\n'
                '• Uncalled penalty: Tapping an uncalled number deducts -5 points.\n'
                '• Master Board: Open the grid anytime to verify called numbers.',
                style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBallColor(int number) {
    if (number <= 18) return const Color(0xFFE53935); // Red
    if (number <= 36) return const Color(0xFF1E88E5); // Blue
    if (number <= 54) return const Color(0xFF43A047); // Green
    if (number <= 72) return const Color(0xFFFB8C00); // Orange
    return const Color(0xFF8E24AA); // Purple
  }

  @override
  Widget build(BuildContext context) {
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
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: Column(
            children: [
              if (_isSubmitting) const LinearProgressIndicator(),
              // 1. Top Professional Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    // Live Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF880E4F), Color(0xFFC2185B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Score: $_score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Called count pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Called: ${_engine.calledNumbers.length}/90',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Master Board Button
                    IconButton(
                      icon: const Icon(Icons.grid_on_rounded, size: 20),
                      tooltip: 'Master Board (1-90)',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => TambolaBoardDialog(
                            calledNumbers: _engine.calledNumbers,
                            currentNumber: _currentBall,
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),

                    // Rules Button
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'Rules & Prizes',
                      onPressed: _showRulesDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),

                    // Reset / New Ticket Button
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'New Ticket',
                      onPressed: () async {
                        if (_isGameInProgress) {
                          final shouldRestart = await _showExitConfirmationDialog();
                          if (!shouldRestart || !mounted) return;
                        }
                        _restartGame();
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
                color: const Color(0xFFC2185B).withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC2185B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF880E4F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Scrollable Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Column(
                        children: [
                          // CALLER STAGE
                          _buildCallerStage(),
                          const SizedBox(height: 14),

                          // TICKET SECTION
                          TambolaTicketWidget(
                            ticket: _engine.ticket,
                            markedNumbers: _engine.markedNumbers,
                            calledNumbers: _engine.calledNumbers,
                            currentCalledNumber: _currentBall,
                            onNumberTapped: _onNumberTapped,
                          ),
                          const SizedBox(height: 16),

                          // PRIZE CLAIMS PANEL
                          TambolaClaimsPanel(
                            engine: _engine,
                            onClaimPattern: _handleClaimPattern,
                          ),
                          const SizedBox(height: 16),

                          // End Game Early button
                          if (!_gameOver)
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await _showExitConfirmationDialog();
                                if (confirm) {
                                  _finishGame(won: false, reason: 'Game ended early by player.');
                                }
                              },
                              icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.grey),
                              label: const Text(
                                'End Game Early',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Realistic Tambola Caller Display
  Widget _buildCallerStage() {
    final recentBalls = _engine.calledNumbers.length > 1
        ? _engine.calledNumbers.sublist(0, _engine.calledNumbers.length - 1).reversed.take(4).toList()
        : <int>[];

    final Color ballColor = _currentBall != null ? _getBallColor(_currentBall!) : const Color(0xFFC2185B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // BIG CALLER BALL WITH 3D SHADING
              ScaleTransition(
                scale: _ballScaleAnimation,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      radius: 0.9,
                      colors: [
                        Colors.white,
                        ballColor,
                        ballColor.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ballColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentBall != null ? _currentBall.toString() : '--',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // BALL INFO & RECENT TRAY
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentBall != null ? getTambolaNickname(_currentBall!) : 'Ready to Call',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ballColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Recent Drawn Balls
                    Row(
                      children: [
                        Text(
                          'Recent: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                        if (recentBalls.isEmpty)
                          Text('None yet', style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
                        else
                          ...recentBalls.map((b) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getBallColor(b),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  b.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // CALLER CONTROLS ROW
          Row(
            children: [
              // Auto / Pause toggle
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleAutoCall,
                  icon: Icon(
                    _isAutoCalling ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 15,
                  ),
                  label: Text(_isAutoCalling ? 'Pause' : 'Auto', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAutoCalling ? Colors.orange.shade800 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Speed selector
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cycleSpeed,
                  icon: const Icon(Icons.speed_rounded, size: 14),
                  label: Text(_speedLabel, style: const TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Manual Call Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drawNextBall,
                  icon: const Icon(Icons.skip_next_rounded, size: 15),
                  label: const Text('Next', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
