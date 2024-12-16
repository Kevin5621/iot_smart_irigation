import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/service/setting_service.dart';

class SettingsBottomSheet extends StatefulWidget {
  final IrrigationSettingsService settingsService;
  

  const SettingsBottomSheet({
    super.key, 
    required this.settingsService
  });

  @override
  _SettingsBottomSheetState createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late bool _automaticMode;
  late double _lowerThreshold;
  late double _upperThreshold;
  late double _pumpDuration;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settings = await widget.settingsService.getSettings();
    setState(() {
      _automaticMode = settings.automaticMode;
      _lowerThreshold = settings.lowerThreshold;
      _upperThreshold = settings.upperThreshold;
      _pumpDuration = settings.pumpDuration;
    });
  }

  Future<void> _saveSettings() async {
    await widget.settingsService.saveAutomaticMode(_automaticMode);
    await widget.settingsService.saveLowerThreshold(_lowerThreshold);
    await widget.settingsService.saveUpperThreshold(_upperThreshold);
    await widget.settingsService.savePumpDuration(_pumpDuration);
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
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
          SwitchListTile(
            title: const Text(
              'Automatic Mode',
              style: TextStyle(color: Colors.white),
            ),
            value: _automaticMode,
            onChanged: (bool value) {
              setState(() {
                _automaticMode = value;
                _saveSettings();
              });
            },
          ),
          _buildSettingSlider(
            'Lower Moisture Threshold',
            _lowerThreshold,
            0,
            50,
            (value) {
              setState(() {
                _lowerThreshold = value;
                _saveSettings();
              });
            },
          ),
          _buildSettingSlider(
            'Upper Moisture Threshold',
            _upperThreshold,
            50,
            100,
            (value) {
              setState(() {
                _upperThreshold = value;
                _saveSettings();
              });
            },
          ),
          _buildSettingSlider(
            'Pump Duration (minutes)',
            _pumpDuration,
            1,
            30,
            (value) {
              setState(() {
                _pumpDuration = value;
                _saveSettings();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider(
    String title, 
    double value, 
    double min, 
    double max, 
    ValueChanged<double> onChanged
  ) {
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
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.round().toString(),
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
      ],
    );
  }
}