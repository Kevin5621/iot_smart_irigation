// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_irigation/iot_service.dart';
import 'package:smart_irigation/models.dart';
import 'package:smart_irigation/schedule.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final IotService _iotService = IotService();
  MoistureData? _currentMoisture;
  PumpSettings _settings = PumpSettings();
  bool _isPumpOn = false;
  bool _isLoading = false;

  // Controllers input
  final TextEditingController _lowerThresholdController = TextEditingController();
  final TextEditingController _upperThresholdController = TextEditingController();
  final TextEditingController _pumpDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMoistureData();
    _initializeControllers();
  }

  void _showScheduledWateringPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledWateringPage(
          settings: _settings,
          onSettingsUpdated: _updateSettings,
        ),
      ),
    );
  }

  void _updateSettings(PumpSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });

    try {
      // Kirim pembaruan ke IoT Service
      await _iotService.updateSettings(_settings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan berhasil diperbarui'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  void _initializeControllers() {
    _lowerThresholdController.text = _settings.lowerThreshold.toString();
    _upperThresholdController.text = _settings.upperThreshold.toString();
    _pumpDurationController.text = _settings.pumpDuration.toString();
  }


  Future<void> _fetchMoistureData() async {
    try {
      final moistureData = await _iotService.readMoisture();
      setState(() {
        _currentMoisture = moistureData;
      });

      // Cek auto control jika mode otomatis aktif
      if (_settings.isAutoMode) {
        await _iotService.autoControlPump(moistureData, _settings);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal membaca sensor moisture');
    }
  }

  Future<void> _togglePump() async {
    try {
      final result = await _iotService.controlPump(!_isPumpOn);
      if (result) {
        setState(() {
          _isPumpOn = !_isPumpOn;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Gagal mengontrol pompa');
    }
  }

  void _showSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            title: const Text('Pengaturan Irigasi'),
            content: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Mode Otomatis (Moisture)'),
                        value: _settings.isAutoMode,
                        onChanged: (bool value) {
                          dialogSetState(() {
                            _settings.isAutoMode = value;
                          });
                        },
                      ),
                      TextField(
                        controller: _lowerThresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Batas Bawah Moisture (%)',
                          helperText: 'Rentang 0-100%'
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                        ],
                      ),
                      TextField(
                        controller: _upperThresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Batas Atas Moisture (%)',
                          helperText: 'Rentang 0-100%'
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                        ],
                      ),
                      TextField(
                        controller: _pumpDurationController,
                        decoration: const InputDecoration(
                          labelText: 'Durasi Pompa (detik)',
                          helperText: 'Waktu pompa menyala'
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ],
                  ),
                ),
            actions: _isLoading 
              ? [] 
              : [
                  TextButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    child: const Text('Simpan'),
                    onPressed: () => _saveSettings(context, dialogSetState),
                  ),
                ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveSettings(BuildContext context, StateSetter dialogSetState) async {
    dialogSetState(() {
      _isLoading = true;
    });

    try {
      // Validasi input dengan try-catch
      final lowerThreshold = double.tryParse(_lowerThresholdController.text);
      final upperThreshold = double.tryParse(_upperThresholdController.text);
      final pumpDuration = int.tryParse(_pumpDurationController.text);

      if (lowerThreshold == null || 
          upperThreshold == null || 
          pumpDuration == null ||
          lowerThreshold < 0 || 
          lowerThreshold > 100 ||
          upperThreshold < 0 || 
          upperThreshold > 100 ||
          pumpDuration <= 0) {
        throw Exception('Input tidak valid');
      }

      // Update settings
      _settings.lowerThreshold = lowerThreshold;
      _settings.upperThreshold = upperThreshold;
      _settings.pumpDuration = pumpDuration;

      // Kirim ke IoT Service
      await _iotService.updateSettings(_settings);

      // Tutup dialog
      Navigator.of(context).pop();

      // Tampilkan success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan tersimpan'))
      );
    } catch (e) {
      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      // Kembalikan loading state
      dialogSetState(() {
        _isLoading = false;
      });
    }
  }


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Smart Irrigation (HW-080)', 
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _showScheduledWateringPage,
            tooltip: 'Jadwal Penyiraman',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black87.withOpacity(0.9),
                ],
              ),
            ),
          ),
          
          // Blurred background effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGlassMorphicContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kelembaban Tanah (HW-080)',
                        style: TextStyle(
                          fontSize: 20, 
                          color: Colors.white70,
                          fontWeight: FontWeight.w300
                        ),
                      ),
                      Text(
                        _currentMoisture != null 
                          ? '${_currentMoisture!.moisture.toStringAsFixed(2)}%' 
                          : 'Memuat...',
                        style: const TextStyle(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                ElevatedButton.icon(
                  icon: Icon(
                    _isPumpOn ? Icons.water_drop : Icons.water_drop_outlined, 
                    color: Colors.white
                  ),
                  label: Text(
                    _isPumpOn ? 'Matikan Pompa' : 'Nyalakan Pompa',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPumpOn 
                      ? Colors.red.withOpacity(0.7) 
                      : Colors.green.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _togglePump,
                ),
                
                const SizedBox(height: 20),
                
                _buildGlassMorphicButton(
                  child: Text(
                    'Refresh Data Moisture', 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8)
                    )
                  ),
                  onPressed: _fetchMoistureData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom glassmorphic
  Widget _buildGlassMorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5)
              )
            ]
          ),
          child: child,
        ),
      ),
    );
  }

  // Glassmorphic button
  Widget _buildGlassMorphicButton({
    required Widget child, 
    required VoidCallback onPressed
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1
              )
            ),
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}