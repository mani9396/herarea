import 'package:flutter/material.dart';

class TambolaBoardDialog extends StatelessWidget {
  final List<int> calledNumbers;
  final int? currentNumber;

  const TambolaBoardDialog({
    super.key,
    required this.calledNumbers,
    required this.currentNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2185B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.grid_on_rounded, color: Color(0xFFC2185B), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MASTER CALLER BOARD (1-90)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Check all drawn numbers',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Called: ${calledNumbers.length}/90',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),

            // 10x9 Grid of 1-90 Numbers
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double cellSize = (constraints.maxWidth - 20) / 10;
                    return Wrap(
                      spacing: 2,
                      runSpacing: 3,
                      alignment: WrapAlignment.center,
                      children: List.generate(90, (index) {
                        final num = index + 1;
                        final isCalled = calledNumbers.contains(num);
                        final isCurrent = currentNumber == num;

                        Color bg;
                        Color textCol;
                        Border? border;

                        if (isCurrent) {
                          bg = const Color(0xFFC2185B);
                          textCol = Colors.white;
                          border = Border.all(color: Colors.amber, width: 2);
                        } else if (isCalled) {
                          bg = Colors.amber.shade100;
                          textCol = Colors.brown.shade900;
                          border = Border.all(color: Colors.amber.shade400);
                        } else {
                          bg = Colors.grey.shade100;
                          textCol = Colors.grey.shade600;
                        }

                        return Container(
                          width: cellSize.clamp(24.0, 42.0),
                          height: cellSize.clamp(24.0, 42.0),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                            border: border,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFC2185B).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              num.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: (isCalled || isCurrent) ? FontWeight.bold : FontWeight.w500,
                                color: textCol,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFFC2185B), 'Latest Ball'),
                const SizedBox(width: 14),
                _buildLegendItem(Colors.amber.shade300, 'Called'),
                const SizedBox(width: 14),
                _buildLegendItem(Colors.grey.shade300, 'Pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}
