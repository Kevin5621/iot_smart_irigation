import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class MoistureSensorCard extends StatelessWidget {
  final double moistureLevel;
  final Color? accentColor;
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final TextStyle? statusStyle;

  const MoistureSensorCard({
    super.key,
    required this.moistureLevel,
    this.accentColor = Colors.green,
    this.title = 'Soil Moisture',
    this.titleStyle,
    this.valueStyle,
    this.statusStyle,
  });

  String _getMoistureStatus(double moisture) {
    if (moisture < 30) return 'Very Dry';
    if (moisture < 50) return 'Dry';
    if (moisture < 70) return 'Optimal Condition';
    return 'Too Wet';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMoistureStatus(moistureLevel);

    return GlassmorphicContainer(
      width: double.infinity,
      height: 200,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? 'Soil Moisture',
                  style: titleStyle ?? TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${moistureLevel.toStringAsFixed(1)}%',
                  style: valueStyle ?? const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: statusStyle ?? TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}