import 'package:flutter/material.dart';
import 'package:smart_irigation/models/models.dart';
import 'package:smart_irigation/presentation/schedule/schedule.dart';
import 'package:smart_irigation/presentation/home/widgets/setting.dart';
import 'package:smart_irigation/presentation/home/widgets/control_section.dart';
import 'package:smart_irigation/presentation/home/widgets/moisture_sensor_card.dart';
import 'package:smart_irigation/presentation/home/widgets/schedule_card.dart';
import 'package:smart_irigation/service/iot_service.dart';
import 'package:smart_irigation/service/irrigation_settings.dart';
import 'package:smart_irigation/service/setting_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Inisialisasi service-service yang dibutuhkan
  final IoTService _iotService = IoTService();
  final IrrigationSettingsService _settingsService = IrrigationSettingsService();
  
  double _moistureLevel = 0.0;
  late IrrigationSettings _irrigationSettings;

  @override
  void initState() {
    super.initState();
    
    // Koneksi IoT service
    _iotService.connect();

    // Muat pengaturan awal
    _loadInitialSettings();

    // Listen to moisture level stream
    _iotService.moistureLevelStream.listen((level) {
      setState(() {
        _moistureLevel = level;
        
        // Cek apakah perlu menyalakan pompa berdasarkan pengaturan
        _checkAndControlPump(level);
      });
    });

    // Listen to pump status stream
    _iotService.pumpStatusStream.listen((status) {
      setState(() {
        // Jika perlu update UI berdasarkan status pompa
      });
    });
  }

  Future<void> _loadInitialSettings() async {
    final settings = await _settingsService.getSettings();
    setState(() {
      _irrigationSettings = settings;
    });
  }

  void _checkAndControlPump(double currentMoistureLevel) {
    // Logika otomatis menyalakan pompa
    if (_irrigationSettings.automaticMode) {
      if (currentMoistureLevel < _irrigationSettings.lowerThreshold) {
        // Nyalakan pompa
        _iotService.controlPump(
          isOn: true, 
          duration: _irrigationSettings.pumpDuration
        );
      } else if (currentMoistureLevel > _irrigationSettings.upperThreshold) {
        // Matikan pompa
        _iotService.controlPump(isOn: false);
      }
    }
  }

  @override
  void dispose() {
    _iotService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _buildCustomAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _HomePageBody(
              moistureLevel: _moistureLevel,
              iotService: _iotService,
              settingsService: _settingsService,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildCustomAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => _openScheduledWateringPage(context),
      ),
      title: const Text(
        'Smart Irrigation', 
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsBottomSheet(context),
        ),
      ],
    );
  }

  void _openScheduledWateringPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledWateringPage(
          settings: PumpSettings(),
          onSettingsUpdated: (updatedSettings) {
            // Handle settings update if needed
          },
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsBottomSheet(
        settingsService: _settingsService
      ),
    ).then((_) {
      _loadInitialSettings();
    });
  }
}

class _HomePageBody extends StatefulWidget {
  final double moistureLevel;
  final IoTService iotService;
  final IrrigationSettingsService settingsService;

  const _HomePageBody({
    required this.moistureLevel, 
    required this.iotService,
    required this.settingsService,
  });

  @override
  __HomePageBodyState createState() => __HomePageBodyState();
}

class __HomePageBodyState extends State<_HomePageBody> {
  late IrrigationSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsService.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black87.withOpacity(0.9),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Informasi Pengaturan Irigasi
              Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Irrigation Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingInfo('Automatic Mode', _settings.automaticMode ? 'Enabled' : 'Disabled'),
                      _buildSettingInfo('Lower Moisture Threshold', '${_settings.lowerThreshold.round()}%'),
                      _buildSettingInfo('Upper Moisture Threshold', '${_settings.upperThreshold.round()}%'),
                      _buildSettingInfo('Pump Duration', '${_settings.pumpDuration.round()} minutes'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              MoistureSensorCard(moistureLevel: widget.moistureLevel),
              const SizedBox(height: 20),
              BuildControlSection(iotService: widget.iotService),
              const SizedBox(height: 20),
              const ScheduleCard(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSettingInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}