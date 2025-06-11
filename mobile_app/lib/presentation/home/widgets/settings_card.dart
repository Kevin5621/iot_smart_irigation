import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/providers/app_provider.dart';

class SettingsCard extends StatefulWidget {
  const SettingsCard({super.key});

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  late TextEditingController _moistureController;
  late TextEditingController _durationController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _moistureController = TextEditingController();
    _durationController = TextEditingController();
  }

  @override
  void dispose() {
    _moistureController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final settings = provider.currentSettings;
        
        // Update controllers when settings change
        if (!_isEditing) {
          _moistureController.text = settings.moistureThreshold.toString();
          _durationController.text = settings.pumpDuration.toString();
        }
        
        return GlassmorphicContainer(
          width: double.infinity,
          height: 200,
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
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Irrigation Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (settings.plantType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          settings.plantType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      // Moisture Threshold
                      Expanded(
                        child: _buildSettingItem(
                          icon: Icons.water_drop,
                          label: 'Moisture Threshold',
                          value: '${settings.moistureThreshold}%',
                          controller: _moistureController,
                          suffix: '%',
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            provider.updateIrrigationSettings(
                              lowerThreshold: value,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Pump Duration
                      Expanded(
                        child: _buildSettingItem(
                          icon: Icons.timer,
                          label: 'Pump Duration',
                          value: '${settings.pumpDuration}s',
                          controller: _durationController,
                          suffix: 's',
                          min: 5,
                          max: 300,
                          onChanged: (value) {
                            provider.updateIrrigationSettings(
                              pumpDuration: value,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Auto Mode Toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_mode,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Auto Irrigation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: settings.automaticMode,
                        onChanged: (value) {
                          provider.updateIrrigationSettings(
                            automaticMode: value,
                          );
                        },
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required String suffix,
    required double min,
    required double max,
    required Function(double) onChanged,
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
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Slider(
              value: double.tryParse(controller.text.replaceAll(suffix, '')) ?? min,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              activeColor: Colors.blue,
              inactiveColor: Colors.white.withOpacity(0.3),
              onChangeStart: (value) {
                setState(() {
                  _isEditing = true;
                });
              },
              onChanged: (value) {
                setState(() {
                  controller.text = value.toInt().toString();
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isEditing = false;
                });
                onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}