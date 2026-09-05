import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double value;
  final double max;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;
  final bool showPercentage;

  const CustomProgressIndicator({
    super.key,
    required this.value,
    required this.max,
    this.color,
    this.backgroundColor,
    this.height = 12,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct  = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final col  = color ?? theme.colorScheme.primary;
    final bgCol = backgroundColor ?? col.withValues(alpha: 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                if (showPercentage)
                  Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: col)),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                color: bgCol,
              ),
              AnimatedFractionallySizedBox(
                widthFactor: pct,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [col.withValues(alpha: 0.7), col],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
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