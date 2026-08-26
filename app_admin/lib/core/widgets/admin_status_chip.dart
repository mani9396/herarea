import 'package:flutter/material.dart';
import 'package:app_admin/domain/models/admin_models.dart';

class AdminStatusChip extends StatelessWidget {
  final AdminStatus status;

  const AdminStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case AdminStatus.approved:
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case AdminStatus.pending:
        backgroundColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        break;
      case AdminStatus.rejected:
      case AdminStatus.suspended:
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case AdminStatus.hidden:
        backgroundColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
        break;
      case AdminStatus.draft:
      case AdminStatus.archived:
        backgroundColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF546E7A);
        break;
    }

    // Adapt slightly for dark mode if active
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      backgroundColor = textColor.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
