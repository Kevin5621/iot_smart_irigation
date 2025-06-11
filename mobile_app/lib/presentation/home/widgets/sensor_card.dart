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
        final sensorData = provider.currentSensorData;
        final moisture = provider.currentMoisture;
        
        return GlassmorphicContainer(
          width: double.infinity,
          height: 180,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sensors,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sensor Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (sensorData != null)
                      Text(
                        _formatDateTime(sensorData.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (sensorData != null || moisture > 0)
                  Expanded(
                    child: Row(
                      children: [
                        // Soil Moisture
                        Expanded(
                          child: _buildSensorItem(
                            icon: Icons.water_drop,
                            label: 'Soil Moisture',
                            value: '${(sensorData?.soilMoisture ?? moisture).toStringAsFixed(1)}%',
                            color: _getMoistureColor(sensorData?.soilMoisture ?? moisture),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Temperature
                        Expanded(
                          child: _buildSensorItem(
                            icon: Icons.thermostat,
                            label: 'Temperature',
                            value: sensorData != null 
                                ? '${sensorData.temperature.toStringAsFixed(1)}°C'
                                : '--°C',
                            color: _getTemperatureColor(sensorData?.temperature ?? 0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Humidity
                        Expanded(
                          child: _buildSensorItem(
                            icon: Icons.opacity,
                            label: 'Humidity',
                            value: sensorData != null 
                                ? '${sensorData.humidity.toStringAsFixed(1)}%'
                                : '--%',
                            color: _getHumidityColor(sensorData?.humidity ?? 0),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sensors_off,
                            color: Colors.white.withOpacity(0.5),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No sensor data available',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Check IoT device connection',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getMoistureColor(double moisture) {
    if (moisture < 30) {
      return Colors.red;
    } else if (moisture < 60) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  Color _getTemperatureColor(double temperature) {
    if (temperature < 15 || temperature > 35) {
      return Colors.red;
    } else if (temperature < 20 || temperature > 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  Color _getHumidityColor(double humidity) {
    if (humidity < 40 || humidity > 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 30) {
      return 'Live';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}