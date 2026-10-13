import 'dart:math';
import 'package:flutter/material.dart';
import 'ludo_engine.dart';

class LudoBoardPainter extends CustomPainter {
  final LudoGameEngine engine;

  LudoBoardPainter(this.engine);

  // Modern vibrant palette
  static const Color redColor = Color(0xFFE53935);
  static const Color greenColor = Color(0xFF2E7D32);
  static const Color yellowColor = Color(0xFFF9A825);
  static const Color blueColor = Color(0xFF1565C0);

  static const Color trackBorder = Color(0xFFB0BEC5);
  static const Color cellBg = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15.0;

    // Draw board background
    final Paint bgPaint = Paint()..color = const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final Paint borderPaint = Paint()
      ..color = trackBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Draw track cells background
    final Paint whiteCellPaint = Paint()..color = cellBg;
    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        // Only draw if track or home stretch or safe area
        if (_isTrackOrStretchCell(c, r)) {
          Rect cell = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
          canvas.drawRect(cell, whiteCellPaint);
        }
      }
    }

    // 2. Fill home stretch tracks
    final Paint redPaint = Paint()..color = redColor;
    final Paint greenPaint = Paint()..color = greenColor;
    final Paint yellowPaint = Paint()..color = yellowColor;
    final Paint bluePaint = Paint()..color = blueColor;

    // Red home stretch (cols 1..5, row 7)
    for (int c = 1; c <= 5; c++) {
      canvas.drawRect(Rect.fromLTWH(c * cellSize, 7 * cellSize, cellSize, cellSize), redPaint);
    }
    // Green home stretch (col 7, rows 1..5)
    for (int r = 1; r <= 5; r++) {
      canvas.drawRect(Rect.fromLTWH(7 * cellSize, r * cellSize, cellSize, cellSize), greenPaint);
    }
    // Yellow home stretch (cols 9..13, row 7)
    for (int c = 9; c <= 13; c++) {
      canvas.drawRect(Rect.fromLTWH(c * cellSize, 7 * cellSize, cellSize, cellSize), yellowPaint);
    }
    // Blue home stretch (col 7, rows 9..13)
    for (int r = 9; r <= 13; r++) {
      canvas.drawRect(Rect.fromLTWH(7 * cellSize, r * cellSize, cellSize, cellSize), bluePaint);
    }

    // Starting Safe Cells
    canvas.drawRect(Rect.fromLTWH(1 * cellSize, 6 * cellSize, cellSize, cellSize), redPaint); // Red start
    canvas.drawRect(Rect.fromLTWH(8 * cellSize, 1 * cellSize, cellSize, cellSize), greenPaint); // Green start
    canvas.drawRect(Rect.fromLTWH(13 * cellSize, 8 * cellSize, cellSize, cellSize), yellowPaint); // Yellow start
    canvas.drawRect(Rect.fromLTWH(6 * cellSize, 13 * cellSize, cellSize, cellSize), bluePaint); // Blue start

    // 3. Draw Track Grid lines
    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        if (_isTrackOrStretchCell(c, r)) {
          Rect cell = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
          canvas.drawRect(cell, borderPaint);
        }
      }
    }

    // 4. Draw Stars on Safe Squares
    // Safe Squares:
    // (1,6) Red start, (6,2), (8,1) Green start, (12,6), (13,8) Yellow start, (8,12), (6,13) Blue start, (2,8)
    _drawStar(canvas, 1, 6, cellSize, Colors.white);
    _drawStar(canvas, 6, 2, cellSize, const Color(0xFFD4AF37)); // Gold on white cell
    _drawStar(canvas, 8, 1, cellSize, Colors.white);
    _drawStar(canvas, 12, 6, cellSize, const Color(0xFFD4AF37));
    _drawStar(canvas, 13, 8, cellSize, Colors.white);
    _drawStar(canvas, 8, 12, cellSize, const Color(0xFFD4AF37));
    _drawStar(canvas, 6, 13, cellSize, Colors.white);
    _drawStar(canvas, 2, 8, cellSize, const Color(0xFFD4AF37));

    // 5. Draw Directional Arrows into Home Stretches
    _drawHomeArrow(canvas, 0, 7, cellSize, redColor, ArrowDirection.right);
    _drawHomeArrow(canvas, 7, 0, cellSize, greenColor, ArrowDirection.down);
    _drawHomeArrow(canvas, 14, 7, cellSize, yellowColor, ArrowDirection.left);
    _drawHomeArrow(canvas, 7, 14, cellSize, blueColor, ArrowDirection.up);

    // 6. Draw Bases (Corner 6x6 boxes)
    _drawBase(canvas, 0, 0, cellSize, redColor, const [
      Point(1.5, 1.5), Point(3.5, 1.5), Point(1.5, 3.5), Point(3.5, 3.5),
    ]);
    _drawBase(canvas, 9, 0, cellSize, greenColor, const [
      Point(10.5, 1.5), Point(12.5, 1.5), Point(10.5, 3.5), Point(12.5, 3.5),
    ]);
    _drawBase(canvas, 9, 9, cellSize, yellowColor, const [
      Point(10.5, 10.5), Point(12.5, 10.5), Point(10.5, 12.5), Point(12.5, 12.5),
    ]);
    _drawBase(canvas, 0, 9, cellSize, blueColor, const [
      Point(1.5, 10.5), Point(3.5, 10.5), Point(1.5, 12.5), Point(3.5, 12.5),
    ]);

    // 7. Draw Center Home Triangles
    _drawCenterTriangles(canvas, cellSize);

    // 8. Outer Board Border
    final Paint outerBorder = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outerBorder);
  }

  bool _isTrackOrStretchCell(int c, int r) {
    bool inRedBase = c < 6 && r < 6;
    bool inGreenBase = c > 8 && r < 6;
    bool inYellowBase = c > 8 && r > 8;
    bool inBlueBase = c < 6 && r > 8;
    bool inCenter = c >= 6 && c <= 8 && r >= 6 && r <= 8;
    return !(inRedBase || inGreenBase || inYellowBase || inBlueBase || inCenter);
  }

  void _drawBase(
    Canvas canvas,
    double col,
    double row,
    double cellSize,
    Color baseColor,
    List<Point<double>> tokenNests,
  ) {
    final double left = col * cellSize;
    final double top = row * cellSize;
    final double size = 6 * cellSize;

    // Outer colored square
    final Paint basePaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(left, top, size, size), basePaint);

    // Inner rounded white container
    final double pad = 0.7 * cellSize;
    final Rect innerRect = Rect.fromLTWH(left + pad, top + pad, size - 2 * pad, size - 2 * pad);
    final RRect innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(cellSize * 0.5));

    final Paint whitePodPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(innerRRect, whitePodPaint);

    final Paint podBorder = Paint()
      ..color = baseColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(innerRRect, podBorder);

    // 4 circular recessed token nests
    for (var nest in tokenNests) {
      final Offset center = Offset(nest.x * cellSize, nest.y * cellSize);
      final double nestRadius = 0.55 * cellSize;

      // Soft shadow
      canvas.drawCircle(
        center.translate(0, 1),
        nestRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );

      // Light tint fill
      canvas.drawCircle(
        center,
        nestRadius,
        Paint()..color = baseColor.withValues(alpha: 0.12),
      );

      // Colored circular border
      canvas.drawCircle(
        center,
        nestRadius,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawCenterTriangles(Canvas canvas, double cellSize) {
    final double cX = 7.5 * cellSize;
    final double cY = 7.5 * cellSize;

    final Paint greenPaint = Paint()..color = greenColor;
    final Paint yellowPaint = Paint()..color = yellowColor;
    final Paint bluePaint = Paint()..color = blueColor;
    final Paint redPaint = Paint()..color = redColor;

    // Green (Top)
    Path topP = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(9 * cellSize, 6 * cellSize)
      ..lineTo(cX, cY)
      ..close();
    canvas.drawPath(topP, greenPaint);

    // Yellow (Right)
    Path rightP = Path()
      ..moveTo(9 * cellSize, 6 * cellSize)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..lineTo(cX, cY)
      ..close();
    canvas.drawPath(rightP, yellowPaint);

    // Blue (Bottom)
    Path bottomP = Path()
      ..moveTo(9 * cellSize, 9 * cellSize)
      ..lineTo(6 * cellSize, 9 * cellSize)
      ..lineTo(cX, cY)
      ..close();
    canvas.drawPath(bottomP, bluePaint);

    // Red (Left)
    Path leftP = Path()
      ..moveTo(6 * cellSize, 9 * cellSize)
      ..lineTo(6 * cellSize, 6 * cellSize)
      ..lineTo(cX, cY)
      ..close();
    canvas.drawPath(leftP, redPaint);

    // Triangle dividing borders
    final Paint divPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(6 * cellSize, 6 * cellSize), Offset(9 * cellSize, 9 * cellSize), divPaint);
    canvas.drawLine(Offset(9 * cellSize, 6 * cellSize), Offset(6 * cellSize, 9 * cellSize), divPaint);

    // Center Golden Finish Emblem
    canvas.drawCircle(
      Offset(cX, cY),
      cellSize * 0.45,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(
      Offset(cX, cY),
      cellSize * 0.45,
      Paint()
        ..color = const Color(0xFFB78103)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawStarAt(canvas, cX, cY, cellSize * 0.35, Colors.white);
  }

  void _drawStar(Canvas canvas, int col, int row, double cellSize, Color color) {
    final double cX = (col + 0.5) * cellSize;
    final double cY = (row + 0.5) * cellSize;
    _drawStarAt(canvas, cX, cY, cellSize * 0.38, color);
  }

  void _drawStarAt(Canvas canvas, double cX, double cY, double radius, Color color) {
    final Path star = Path();
    final double innerRadius = radius * 0.42;

    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? radius : innerRadius;
      final double angle = -pi / 2 + (i * pi / 5);
      final double x = cX + r * cos(angle);
      final double y = cY + r * sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();

    // Subtle dark shadow outline
    canvas.drawPath(
      star,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Fill star
    canvas.drawPath(star, Paint()..color = color);
  }

  void _drawHomeArrow(
    Canvas canvas,
    int col,
    int row,
    double cellSize,
    Color color,
    ArrowDirection dir,
  ) {
    final double x = col * cellSize;
    final double y = row * cellSize;
    final Path arrow = Path();

    switch (dir) {
      case ArrowDirection.right:
        arrow.moveTo(x + cellSize * 0.2, y + cellSize * 0.2);
        arrow.lineTo(x + cellSize * 0.8, y + cellSize * 0.5);
        arrow.lineTo(x + cellSize * 0.2, y + cellSize * 0.8);
        break;
      case ArrowDirection.down:
        arrow.moveTo(x + cellSize * 0.2, y + cellSize * 0.2);
        arrow.lineTo(x + cellSize * 0.5, y + cellSize * 0.8);
        arrow.lineTo(x + cellSize * 0.8, y + cellSize * 0.2);
        break;
      case ArrowDirection.left:
        arrow.moveTo(x + cellSize * 0.8, y + cellSize * 0.2);
        arrow.lineTo(x + cellSize * 0.2, y + cellSize * 0.5);
        arrow.lineTo(x + cellSize * 0.8, y + cellSize * 0.8);
        break;
      case ArrowDirection.up:
        arrow.moveTo(x + cellSize * 0.2, y + cellSize * 0.8);
        arrow.lineTo(x + cellSize * 0.5, y + cellSize * 0.2);
        arrow.lineTo(x + cellSize * 0.8, y + cellSize * 0.8);
        break;
    }
    arrow.close();

    canvas.drawPath(arrow, Paint()..color = color.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum ArrowDirection { right, down, left, up }
