import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/providers/app_provider.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final moisture = provider.currentMoisture;
        final temperature = provider.currentTemperature;
        final hasData = moisture > 0 || temperature > 0;

        return GlassmorphicContainer(
          width: double.infinity,
          height: 200, // Increased height to accommodate content
          borderRadius: 20,
          blur: 10,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFffffff).withOpacity(0.1),
              const Color(0xFFFFFFFF).withOpacity(0.05),
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
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    const Icon(
                      Icons.sensors,
                      color: Colors.white,
                      size: 22, // Slightly smaller icon
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sensor Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16, // Slightly smaller text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced spacing
                // Content area
                Expanded(
                  child: hasData
                      ? Row(
                          children: [
                            // Soil Moisture
                            Expanded(
                              child: _buildSensorItem(
                                icon: Icons.water_drop,
                                label: 'Kelembapan Tanah',
                                value: '${moisture.toStringAsFixed(1)}%',
                                color: _getMoistureColor(moisture),
                                subtitle: _getMoistureStatus(moisture),
                              ),
                            ),
                            const SizedBox(width: 12), // Reduced spacing
                            // Temperature
                            Expanded(
                              child: _buildSensorItem(
                                icon: Icons.thermostat,
                                label: 'Suhu',
                                value: '${temperature.toStringAsFixed(1)}°C',
                                color: _getTemperatureColor(temperature),
                                subtitle: _getTemperatureStatus(temperature),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sensors_off,
                                color: Colors.white.withOpacity(0.5),
                                size: 28, // Smaller icon
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No sensor data available',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12, // Smaller text
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check IoT device connection',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10, // Smaller text
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14), // Slightly smaller radius
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Important: minimize size
        children: [
          Icon(
            icon,
            color: color,
            size: 24, // Slightly smaller icon
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16, // Slightly larger for readability
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3), // Reduced spacing
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10, // Smaller text
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow wrapping
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10, // Smaller text
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 20) {
      return Colors.red;
    } else if (moisture < 40) {
      return Colors.orange;
    } else if (moisture < 70) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  String _getMoistureStatus(double moisture) {
    if (moisture < 20) {
      return 'Sangat Kering';
    } else if (moisture < 40) {
      return 'Kering';
    } else if (moisture < 70) {
      return 'Optimal';
    } else {
      return 'Basah';
    }
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 15) {
      return Colors.lightBlue;
    } else if (temperature < 20) {
      return Colors.blue;
    } else if (temperature <= 30) {
      return Colors.green;
    } else if (temperature <= 35) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getTemperatureStatus(double temperature) {
    if (temperature < 15) {
      return 'Sangat Dingin';
    } else if (temperature < 20) {
      return 'Dingin';
    } else if (temperature <= 30) {
      return 'Optimal';
    } else if (temperature <= 35) {
      return 'Panas';
    } else {
      return 'Sangat Panas';
    }
  }
}
