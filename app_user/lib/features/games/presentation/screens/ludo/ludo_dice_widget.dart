import 'dart:math';
import 'package:flutter/material.dart';

class LudoDiceWidget extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onTap;
  final Color activeColor;
  final double size;

  const LudoDiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = false,
    this.onTap,
    this.activeColor = const Color(0xFFE53935),
    this.size = 64.0,
  });

  @override
  State<LudoDiceWidget> createState() => _LudoDiceWidgetState();
}

class _LudoDiceWidgetState extends State<LudoDiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Random _random = Random();
  int _displayValue = 1;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value ?? 1;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animController.addListener(() {
      if (widget.isRolling && mounted) {
        setState(() {
          _displayValue = _random.nextInt(6) + 1;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LudoDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _animController.repeat();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _animController.stop();
      _animController.reset();
      setState(() {
        _displayValue = widget.value ?? 1;
      });
    } else if (widget.value != null && widget.value != oldWidget.value && !widget.isRolling) {
      setState(() {
        _displayValue = widget.value!;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final int val = widget.isRolling ? _displayValue : (widget.value ?? _displayValue);

    Widget diceBody = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF0F2F5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
          if (widget.canRoll)
            BoxShadow(
              color: widget.activeColor.withValues(alpha: 0.6),
              blurRadius: 14,
              spreadRadius: 3,
            ),
        ],
        border: Border.all(
          color: widget.canRoll ? widget.activeColor : const Color(0xFFD0D7DE),
          width: widget.canRoll ? 2.5 : 1.5,
        ),
      ),
      child: CustomPaint(
        painter: _DiceFacePainter(
          value: val,
          pipColor: widget.activeColor,
        ),
      ),
    );

    if (widget.isRolling) {
      diceBody = AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final double t = _animController.value;
          final double wobble = sin(t * 8 * pi) * 0.15;
          final double scale = 1.0 + 0.08 * sin(t * 6 * pi);
          return Transform.rotate(
            angle: wobble,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: diceBody,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.canRoll ? widget.onTap : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              diceBody,
              if (widget.canRoll && !widget.isRolling && widget.value == null)
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      'TAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiceFacePainter extends CustomPainter {
  final int value;
  final Color pipColor;

  _DiceFacePainter({required this.value, required this.pipColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double radius = s * 0.09;

    final Paint pipPaint = Paint()
      ..color = pipColor
      ..style = PaintingStyle.fill;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    void drawPip(double x, double y) {
      // Soft 3D indentation
      canvas.drawCircle(Offset(x + 0.8, y + 1.0), radius, shadowPaint);
      canvas.drawCircle(Offset(x, y), radius, pipPaint);
    }

    final double c = s * 0.5;
    final double l = s * 0.28;
    final double r = s * 0.72;
    final double t = s * 0.28;
    final double b = s * 0.72;

    switch (value.clamp(1, 6)) {
      case 1:
        drawPip(c, c);
        break;
      case 2:
        drawPip(l, t);
        drawPip(r, b);
        break;
      case 3:
        drawPip(l, t);
        drawPip(c, c);
        drawPip(r, b);
        break;
      case 4:
        drawPip(l, t);
        drawPip(r, t);
        drawPip(l, b);
        drawPip(r, b);
        break;
      case 5:
        drawPip(l, t);
        drawPip(r, t);
        drawPip(c, c);
        drawPip(l, b);
        drawPip(r, b);
        break;
      case 6:
        drawPip(l, t);
        drawPip(r, t);
        drawPip(l, c);
        drawPip(r, c);
        drawPip(l, b);
        drawPip(r, b);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.pipColor != pipColor;
  }
}
