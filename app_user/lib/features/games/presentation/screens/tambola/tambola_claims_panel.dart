import 'package:flutter/material.dart';
import 'tambola_engine.dart';

class TambolaClaimsPanel extends StatelessWidget {
  final TambolaEngine engine;
  final Function(TambolaPattern) onClaimPattern;

  const TambolaClaimsPanel({
    super.key,
    required this.engine,
    required this.onClaimPattern,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text(
                  'PRIZE CLAIMS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              '${engine.claimedPatterns.length}/6 Claimed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth < 350
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 8,
              children: kTambolaPrizes.map((prize) {
                final bool isClaimed = engine.claimedPatterns.contains(prize.pattern);
                final bool isAchieved = engine.isPatternAchieved(prize.pattern);
                final bool canClaimNow = isAchieved && !isClaimed;

                return SizedBox(
                  width: cardWidth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isClaimed
                          ? Colors.green.shade50
                          : canClaimNow
                              ? Colors.amber.shade50
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isClaimed
                            ? Colors.green.shade400
                            : canClaimNow
                                ? Colors.amber.shade600
                                : Colors.grey.shade300,
                        width: canClaimNow ? 2.0 : 1.0,
                      ),
                      boxShadow: canClaimNow
                          ? [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prize.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isClaimed
                                      ? Colors.green.shade900
                                      : canClaimNow
                                          ? Colors.brown.shade900
                                          : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${prize.points} pts',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isClaimed ? Colors.green.shade700 : const Color(0xFFC2185B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isClaimed)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          )
                        else if (canClaimNow)
                          ElevatedButton(
                            onPressed: () => onClaimPattern(prize.pattern),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(54, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('CLAIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          OutlinedButton(
                            onPressed: () => onClaimPattern(prize.pattern),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(54, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Claim', style: TextStyle(fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
