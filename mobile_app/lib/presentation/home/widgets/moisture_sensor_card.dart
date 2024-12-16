import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class MoistureSensorCard extends StatelessWidget {
  final double moistureLevel;
  final bool isDeviceOnline;
  final Color? accentColor;
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final TextStyle? statusStyle;

  const MoistureSensorCard({
    super.key,
    required this.moistureLevel,
    required this.isDeviceOnline,
    this.accentColor = Colors.green,
    this.title = 'Soil Moisture',
    this.titleStyle,
    this.valueStyle,
    this.statusStyle,
  });

  String _getMoistureStatus(double moisture) {
    if (!isDeviceOnline) return 'Device Offline';
    if (moisture < 30) return 'Very Dry';
    if (moisture < 50) return 'Dry';
    if (moisture < 70) return 'Optimal Condition';
    return 'Too Wet';
  }

  Color _getStatusColor() {
    if (!isDeviceOnline) return Colors.red;
    if (moistureLevel < 30) return Colors.orange;
    if (moistureLevel < 50) return Colors.yellow;
    if (moistureLevel < 70) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMoistureStatus(moistureLevel);
    final statusColor = _getStatusColor();

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
                    color: isDeviceOnline ? Colors.white70 : Colors.red,
                    fontSize: 16,
                  ),
                ),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: isDeviceOnline ? accentColor : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeviceOnline 
                    ? '${moistureLevel.toStringAsFixed(1)}%' 
                    : 'N/A',
                  style: valueStyle ?? TextStyle(
                    fontSize: 48,
                    color: isDeviceOnline ? Colors.white : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: statusStyle ?? TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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