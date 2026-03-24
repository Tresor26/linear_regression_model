import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String text;
  final bool isError;
  final String? area;
  final String? crop;

  const ResultCard({
    super.key,
    required this.text,
    required this.isError,
    this.area,
    this.crop,
  });

  @override
  Widget build(BuildContext context) {
    final bg        = isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final border    = isError ? Colors.red.shade200 : Colors.green.shade300;
    final iconData  = isError ? Icons.error_outline : Icons.check_circle_outline;
    final iconColor = isError ? Colors.red : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(iconData, size: 40, color: iconColor),
          const SizedBox(height: 10),
          Text(
            isError ? 'Prediction Failed' : 'Predicted Yield',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: iconColor,
              letterSpacing: 0.3,
            ),
          ),
          if (!isError && area != null && crop != null) ...[
            const SizedBox(height: 4),
            Text(
              '$crop • $area',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isError ? 14 : 26,
              fontWeight: isError ? FontWeight.normal : FontWeight.bold,
              color: isError ? Colors.red.shade700 : const Color(0xFF1B5E20),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
