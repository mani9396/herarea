import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

enum SnakeSpeed {
  casual('Casual', 200),
  classic('Classic', 150),
  pro('Pro', 100);

  final String label;
  final int tickMs;
  const SnakeSpeed(this.label, this.tickMs);
}

class SnakeScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SnakeScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends ConsumerState<SnakeScreen> with SingleTickerProviderStateMixin {
  static const int columns = 18;
  static const int rows = 18;

  List<Point<int>> _snake = [
    const Point(9, 10),
    const Point(9, 11),
    const Point(9, 12),
  ];
  Point<int>? _food;
  Point<int> _direction = const Point(0, -1);
  Point<int> _nextDirection = const Point(0, -1);

  Timer? _timer;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _gameOver = false;
  bool _isSubmitting = false;
  int _score = 0;
  int _highScore = 0;
  SnakeSpeed _speed = SnakeSpeed.classic;

  late AnimationController _foodPulseController;
  late Animation<double> _foodPulseAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _foodPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _foodPulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _foodPulseController, curve: Curves.easeInOut),
    );

    _spawnFood();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _foodPulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(columns), random.nextInt(rows));
    } while (_snake.contains(newFood));

    setState(() => _food = newFood);
  }

  void _startGame() {
    _focusNode.requestFocus();
    setState(() {
      _snake = [
        const Point(9, 9),
        const Point(9, 10),
        const Point(9, 11),
      ];
      _direction = const Point(0, -1);
      _nextDirection = const Point(0, -1);
      _score = 0;
      _isPlaying = true;
      _isPaused = false;
      _gameOver = false;
    });
    _spawnFood();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _speed.tickMs), (_) => _tick());
  }

  void _togglePause() {
    if (!_isPlaying || _gameOver) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
      } else {
        _startTimer();
      }
    });
  }

  void _setDirection(Point<int> dir) {
    if (_isPaused || !_isPlaying || _gameOver) return;
    // Disallow 180° reverse turns into own body
    if ((dir.x == -_direction.x && dir.x != 0) || (dir.y == -_direction.y && dir.y != 0)) {
      return;
    }
    _nextDirection = dir;
  }

  void _tick() {
    if (!mounted || _isPaused) return;

    _direction = _nextDirection;
    final head = _snake.first;
    final newHead = Point(head.x + _direction.x, head.y + _direction.y);

    // Wall collision
    if (newHead.x < 0 || newHead.x >= columns || newHead.y < 0 || newHead.y >= rows) {
      _endGame();
      return;
    }

    // Self collision
    if (_snake.contains(newHead)) {
      _endGame();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        if (_score > _highScore) _highScore = _score;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _gameOver = true;
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/api/v1/games/sessions/${widget.sessionId}/complete/',
        body: {
          'score': _score,
          'is_winner': _score >= 50,
        },
      );
    } catch (_) {
      // Gracefully continue even if offline
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
        _setDirection(const Point(0, -1));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
        _setDirection(const Point(0, 1));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
        _setDirection(const Point(-1, 0));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
        _setDirection(const Point(1, 0));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        if (!_isPlaying) {
          _startGame();
        } else {
          _togglePause();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: const Color(0xFF0F172A), // Luxury Midnight Slate
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          if (_isSubmitting)
                            const LinearProgressIndicator(
                              color: AppColors.accentGold,
                              backgroundColor: Colors.transparent,
                              minHeight: 2,
                            ),

                          // 1. TOP LUXURY DASHBOARD HUD
                          _buildTopHud(),
                          const SizedBox(height: 12),

                          // 2. MAIN SNAKE ARENA (CUSTOM CANVAS)
                          _buildArena(constraints),
                          const SizedBox(height: 14),

                          // 3. CONTROLS BAR & ON-SCREEN D-PAD
                          _buildControlPanel(),
                          const SizedBox(height: 8),
                        ],
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

  Widget _buildTopHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SCORE',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Speed Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SnakeSpeed>(
                value: _speed,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.speed_rounded, color: AppColors.accentGold, size: 16),
                items: SnakeSpeed.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _isPlaying
                    ? null
                    : (val) {
                        if (val != null) setState(() => _speed = val);
                      },
              ),
            ),
          ),

          // High Score
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'BEST',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGoldLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$_highScore',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArena(BoxConstraints parentConstraints) {
    // Keep arena responsive: clamp to viewport height while maintaining 1:1 aspect ratio
    final double maxAvailable = min(parentConstraints.maxWidth - 32, 420.0);
    final double arenaSize = max(240.0, maxAvailable);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 5) {
          _setDirection(const Point(0, 1));
        } else if (details.delta.dy < -5) {
          _setDirection(const Point(0, -1));
        }
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 5) {
          _setDirection(const Point(1, 0));
        } else if (details.delta.dx < -5) {
          _setDirection(const Point(-1, 0));
        }
      },
      child: Center(
        child: Container(
          width: arenaSize,
          height: arenaSize,
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPlaying ? AppColors.accentGold : const Color(0xFF334155),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPlaying
                    ? AppColors.accentGold.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // Animated Custom Canvas Board
                AnimatedBuilder(
                  animation: _foodPulseAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(arenaSize, arenaSize),
                      painter: _SnakeBoardPainter(
                        columns: columns,
                        rows: rows,
                        snake: _snake,
                        direction: _direction,
                        food: _food,
                        foodPulse: _foodPulseAnimation.value,
                      ),
                    );
                  },
                ),

                // Game Over Overlay
                if (_gameOver)
                  Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE11D48), width: 2),
                            ),
                            child: const Icon(Icons.sentiment_very_dissatisfied_rounded,
                                color: Color(0xFFF43F5E), size: 44),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'GAME OVER',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFont,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Final Score: $_score',
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentGoldLight,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC2185B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Paused Overlay
                if (_isPaused && _isPlaying && !_gameOver)
                  Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pause_circle_filled_rounded,
                              color: AppColors.accentGold, size: 54),
                          const SizedBox(height: 8),
                          const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFont,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _togglePause,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.accentGold, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('RESUME'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Not Started Overlay
                if (!_isPlaying && !_gameOver)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC2185B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'START GAME',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Column(
      children: [
        // Action Bar (Pause / Restart)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPlaying && !_gameOver)
              OutlinedButton.icon(
                onPressed: _togglePause,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                label: Text(_isPaused ? 'Resume' : 'Pause'),
              ),
            if (_isPlaying && !_gameOver) const SizedBox(width: 14),
            OutlinedButton.icon(
              onPressed: _startGame,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('New Game'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ergonomic Mobile Glassmorphic D-Pad
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: SizedBox(
            width: 180,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // UP
                Positioned(
                  top: 0,
                  child: _buildDpadButton(
                    Icons.keyboard_arrow_up_rounded,
                    () => _setDirection(const Point(0, -1)),
                  ),
                ),
                // LEFT
                Positioned(
                  left: 10,
                  child: _buildDpadButton(
                    Icons.keyboard_arrow_left_rounded,
                    () => _setDirection(const Point(-1, 0)),
                  ),
                ),
                // CENTER EMBLEM
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_esports_rounded, color: AppColors.accentGold, size: 16),
                  ),
                ),
                // RIGHT
                Positioned(
                  right: 10,
                  child: _buildDpadButton(
                    Icons.keyboard_arrow_right_rounded,
                    () => _setDirection(const Point(1, 0)),
                  ),
                ),
                // DOWN
                Positioned(
                  bottom: 0,
                  child: _buildDpadButton(
                    Icons.keyboard_arrow_down_rounded,
                    () => _setDirection(const Point(0, 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDpadButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF334155), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF475569), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// High-Performance Custom Canvas Painter for the Snake Arena
class _SnakeBoardPainter extends CustomPainter {
  final int columns;
  final int rows;
  final List<Point<int>> snake;
  final Point<int> direction;
  final Point<int>? food;
  final double foodPulse;

  _SnakeBoardPainter({
    required this.columns,
    required this.rows,
    required this.snake,
    required this.direction,
    required this.food,
    required this.foodPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / columns;
    final double cellHeight = size.height / rows;

    // 1. Draw Checkered Luxury Lawn Tiles
    final tilePaint1 = Paint()..color = const Color(0xFF0F1E36);
    final tilePaint2 = Paint()..color = const Color(0xFF0D192D);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final rect = Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight);
        canvas.drawRect(rect, (r + c) % 2 == 0 ? tilePaint1 : tilePaint2);
      }
    }

    // 2. Draw Food (Pulsing Ruby Apple / Jewel with Leaf)
    if (food != null) {
      final double foodCenterX = (food!.x + 0.5) * cellWidth;
      final double foodCenterY = (food!.y + 0.5) * cellHeight;
      final double baseRadius = (min(cellWidth, cellHeight) * 0.42) * foodPulse;

      // Glow behind food
      final glowPaint = Paint()
        ..color = const Color(0xFFE11D48).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(foodCenterX, foodCenterY), baseRadius * 1.3, glowPaint);

      // Ruby Jewel Body
      final foodGradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [
          Color(0xFFFB7185), // Soft pink highlight
          Color(0xFFE11D48), // Ruby red
          Color(0xFF881337), // Deep shadow ruby
        ],
      );
      final foodPaint = Paint()
        ..shader = foodGradient.createShader(
          Rect.fromCircle(center: Offset(foodCenterX, foodCenterY), radius: baseRadius),
        );
      canvas.drawCircle(Offset(foodCenterX, foodCenterY), baseRadius, foodPaint);

      // Gold Sparkle Top Highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(foodCenterX - baseRadius * 0.35, foodCenterY - baseRadius * 0.35),
        baseRadius * 0.28,
        highlightPaint,
      );

      // Emerald Leaf on top
      final leafPaint = Paint()..color = const Color(0xFF10B981);
      final leafPath = Path();
      leafPath.moveTo(foodCenterX, foodCenterY - baseRadius * 0.8);
      leafPath.quadraticBezierTo(
        foodCenterX + baseRadius * 0.6,
        foodCenterY - baseRadius * 1.4,
        foodCenterX + baseRadius * 0.2,
        foodCenterY - baseRadius * 0.6,
      );
      canvas.drawPath(leafPath, leafPaint);
    }

    // 3. Draw Snake Body & Tail (Connected segments)
    if (snake.isEmpty) return;

    final int len = snake.length;
    for (int i = len - 1; i >= 1; i--) {
      final pt = snake[i];
      final double cx = (pt.x + 0.5) * cellWidth;
      final double cy = (pt.y + 0.5) * cellHeight;

      // Progress ratio from 0.0 (tail) to 1.0 (near head)
      final double progress = i / len;
      final double radius = (min(cellWidth, cellHeight) * 0.44) * (0.75 + (1 - progress) * 0.25);

      final Color bodyColor = Color.lerp(
        const Color(0xFF059669), // Emerald
        const Color(0xFF10B981), // Light Jade
        1 - progress,
      )!;

      final bodyPaint = Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill;

      // Draw segment pill with soft shadow
      final segRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      canvas.drawRRect(RRect.fromRectAndRadius(segRect, Radius.circular(radius * 0.6)), bodyPaint);

      // Shimmer gold line along spinal ridge
      final spinePaint = Paint()
        ..color = AppColors.accentGold.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), radius * 0.45, spinePaint);
    }

    // 4. Draw Snake Head with Expressive Eyes
    final headPt = snake.first;
    final double headX = (headPt.x + 0.5) * cellWidth;
    final double headY = (headPt.y + 0.5) * cellHeight;
    final double headRadius = min(cellWidth, cellHeight) * 0.48;

    // Glowing head shader
    final headGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      colors: const [
        Color(0xFF34D399), // Mint glow
        Color(0xFF059669), // Emerald
        Color(0xFF065F46), // Deep forest
      ],
    );
    final headPaint = Paint()
      ..shader = headGradient.createShader(
        Rect.fromCircle(center: Offset(headX, headY), radius: headRadius),
      );

    final headRect = Rect.fromCircle(center: Offset(headX, headY), radius: headRadius);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(headRadius * 0.7)), headPaint);

    // Gold Crown / Brow Rim
    final browPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(headRadius * 0.7)), browPaint);

    // Calculate Eye Positions based on movement direction
    final double perpX = -direction.y.toDouble();
    final double perpY = direction.x.toDouble();
    final double eyeOffsetForward = headRadius * 0.3;
    final double eyeOffsetSide = headRadius * 0.42;

    final Offset leftEyePos = Offset(
      headX + (direction.x * eyeOffsetForward) + (perpX * eyeOffsetSide),
      headY + (direction.y * eyeOffsetForward) + (perpY * eyeOffsetSide),
    );
    final Offset rightEyePos = Offset(
      headX + (direction.x * eyeOffsetForward) - (perpX * eyeOffsetSide),
      headY + (direction.y * eyeOffsetForward) - (perpY * eyeOffsetSide),
    );

    // Sclera (White of eyes)
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(leftEyePos, headRadius * 0.22, eyeWhitePaint);
    canvas.drawCircle(rightEyePos, headRadius * 0.22, eyeWhitePaint);

    // Pupils looking ahead
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    final double pupilForward = headRadius * 0.08;
    final Offset leftPupilPos = Offset(
      leftEyePos.dx + (direction.x * pupilForward),
      leftEyePos.dy + (direction.y * pupilForward),
    );
    final Offset rightPupilPos = Offset(
      rightEyePos.dx + (direction.x * pupilForward),
      rightEyePos.dy + (direction.y * pupilForward),
    );
    canvas.drawCircle(leftPupilPos, headRadius * 0.12, pupilPaint);
    canvas.drawCircle(rightPupilPos, headRadius * 0.12, pupilPaint);

    // Eye catchlights (gloss)
    final eyeCatchPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(leftPupilPos.dx - 1, leftPupilPos.dy - 1),
      headRadius * 0.05,
      eyeCatchPaint,
    );
    canvas.drawCircle(
      Offset(rightPupilPos.dx - 1, rightPupilPos.dy - 1),
      headRadius * 0.05,
      eyeCatchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) {
    return true;
  }
}

