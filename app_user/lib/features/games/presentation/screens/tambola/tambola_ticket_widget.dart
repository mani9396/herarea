import 'package:flutter/material.dart';

class TambolaTicketWidget extends StatelessWidget {
  final List<List<int>> ticket;
  final Set<int> markedNumbers;
  final List<int> calledNumbers;
  final int? currentCalledNumber;
  final Function(int) onNumberTapped;
  final String ticketSerial;

  const TambolaTicketWidget({
    super.key,
    required this.ticket,
    required this.markedNumbers,
    required this.calledNumbers,
    required this.currentCalledNumber,
    required this.onNumberTapped,
    this.ticketSerial = 'HA-7821',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8), // Cream cardstock paper
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Authentic Ticket Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF880E4F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'TICKET #$ticketSerial',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'HER AREA TAMBOLA',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${markedNumbers.length}/15',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 3x9 Ticket Grid
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cellWidth = (constraints.maxWidth - (8 * 3)) / 9;
                final double cellHeight = (cellWidth * 1.15).clamp(38.0, 56.0);

                return Column(
                  children: List.generate(3, (rowIdx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(9, (colIdx) {
                          final int value = ticket[rowIdx][colIdx];
                          return SizedBox(
                            width: cellWidth,
                            height: cellHeight,
                            child: _buildCell(context, value),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Perforated Bottom Edge
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEBE9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(18, (index) {
                  return Container(
                    width: 4,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade200,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, int number) {
    if (number == 0) {
      // Classic blank cell with watermark pattern
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0D8C8), width: 0.8),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.brown.shade100,
            ),
          ),
        ),
      );
    }

    final bool isMarked = markedNumbers.contains(number);

    return GestureDetector(
      onTap: () => onNumberTapped(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isMarked ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMarked ? Colors.green.shade600 : const Color(0xFFD7CCC8),
            width: isMarked ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Number Text (Clean authentic presentation without hints)
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isMarked ? Colors.green.shade900 : Colors.brown.shade900,
                letterSpacing: -0.5,
              ),
            ),

            // Ink Dauber / Stamped Badge when marked
            if (isMarked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.22),
                    border: Border.all(color: Colors.green.shade600, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
