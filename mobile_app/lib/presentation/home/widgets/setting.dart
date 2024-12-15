import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.7,
      borderRadius: 20,
      blur: 20,
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Irrigation Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingSwitch('Automatic Mode', true),
          _buildSettingSlider('Lower Threshold', 30),
          _buildSettingSlider('Upper Threshold', 70),
          _buildSettingSlider('Pump Duration', 60),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, bool value) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
      value: value,
      onChanged: (bool newValue) {},
      activeColor: Colors.green,
    );
  }

  Widget _buildSettingSlider(String title, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: value.round().toString(),
          onChanged: (double newValue) {},
          activeColor: Colors.green,
          inactiveColor: Colors.white30,
        ),
      ],
    );
  }
}