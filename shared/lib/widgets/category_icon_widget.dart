import 'package:flutter/material.dart';

class CategoryIconWidget extends StatelessWidget {
  final String? iconUrl;
  final Color color;
  final double size;

  const CategoryIconWidget({
    super.key,
    required this.iconUrl,
    required this.color,
    this.size = 28,
  });

  IconData? _parseIcon(String? iconString) {
    if (iconString == null || iconString.isEmpty) return null;
    switch (iconString.toLowerCase()) {
      case 'brush': return Icons.brush_rounded;
      case 'auto_awesome': return Icons.auto_awesome_rounded;
      case 'face_retouching_natural': return Icons.face_retouching_natural_rounded;
      case 'design_services': return Icons.design_services_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      case 'photo_camera': return Icons.photo_camera_rounded;
      case 'spa': return Icons.spa_rounded;
      case 'diamond': return Icons.diamond_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final val = iconUrl?.trim() ?? '';
    if (val.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          val,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Icon(Icons.broken_image, size: size, color: color),
        ),
      );
    } else if (val.isNotEmpty && val.runes.length <= 3 && !RegExp(r'[a-zA-Z]').hasMatch(val)) {
      return Text(val, style: TextStyle(fontSize: size * 0.85));
    } else {
      return Icon(_parseIcon(val) ?? Icons.category_rounded, color: color, size: size);
    }
  }
}
