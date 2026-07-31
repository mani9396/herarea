import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isOpen;
  final String text;

  const StatusBadge({super.key, required this.isOpen, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppTheme.successGreen : AppTheme.errorRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Open Now' : text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
