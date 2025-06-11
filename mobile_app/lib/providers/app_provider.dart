import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_irigation/entities/entities.dart';
import 'package:smart_irigation/service/iot_service.dart';
import 'package:smart_irigation/service/plant_classification_service.dart';
import 'package:smart_irigation/service/setting_service.dart';
import 'package:smart_irigation/utils/irrigation_settings.dart';

class AppProvider extends ChangeNotifier {
  final IoTService _iotService = IoTService();
  final PlantClassificationService _plantService = PlantClassificationService();
  final IrrigationSettingsService _settingsService = IrrigationSettingsService();
  
  // State variables
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  PlantEntity? _currentPlant;
  SensorDataEntity? _currentSensorData;
  double _currentMoisture = 0.0;
  bool _pumpStatus = false;
  Map<String, dynamic> _irrigationSettings = {};
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PlantEntity? get currentPlant => _currentPlant;
  SensorDataEntity? get currentSensorData => _currentSensorData;
  double get currentMoisture => _currentMoisture;
  bool get pumpStatus => _pumpStatus;
  Map<String, dynamic> get irrigationSettings => _irrigationSettings;
  IrrigationSettings get currentSettings => IrrigationSettings.fromMap(_irrigationSettings);
  IoTService get iotService => _iotService;
  PlantClassificationService get plantService => _plantService;
  
  AppProvider() {
    _initializeServices();
  }
  
  void _initializeServices() {
    // Listen to IoT service streams
    _iotService.deviceStatusStream.listen((status) {
      _isConnected = status;
      notifyListeners();
    });
    
    _iotService.moistureLevelStream.listen((moisture) {
      _currentMoisture = moisture;
      notifyListeners();
    });
    
    _iotService.pumpStatusStream.listen((status) {
      _pumpStatus = status;
      notifyListeners();
    });
    
    _iotService.sensorDataStream.listen((data) {
      _currentSensorData = data;
      notifyListeners();
    });
    
    _iotService.plantDataStream.listen((plant) {
      _currentPlant = plant;
      notifyListeners();
    });
    
    _iotService.settingsStream.listen((settings) {
      _irrigationSettings = settings;
      notifyListeners();
    });
    
    // Load saved settings
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      _irrigationSettings = (await _settingsService.getSettings()).toMap();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load settings: $e');
    }
  }
  
  Future<void> connectToIoT() async {
    _setLoading(true);
    try {
      await _iotService.connect();
      _clearError();
    } catch (e) {
      _setError('Failed to connect to IoT device: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> classifyPlant(File imageFile) async {
    _setLoading(true);
    try {
      final plant = await _plantService.classifyPlant(imageFile);
      if (plant != null) {
        _currentPlant = plant;
        // Send plant data to IoT device
        _iotService.sendPlantClassificationData(plant);
        _clearError();
      } else {
        _setError('Failed to classify plant');
      }
    } catch (e) {
      _setError('Error classifying plant: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void controlPump({required bool isOn, double? duration}) {
    try {
      _iotService.controlPump(isOn: isOn, duration: duration);
      _clearError();
    } catch (e) {
      _setError('Failed to control pump: $e');
    }
  }
  
  Future<void> updateIrrigationSettings({
    bool? automaticMode,
    double? lowerThreshold,
    double? upperThreshold,
    double? pumpDuration,
  }) async {
    try {
      // Update local settings
      if (automaticMode != null) {
        await _settingsService.saveAutomaticMode(automaticMode);
      }
      if (lowerThreshold != null) {
        await _settingsService.saveLowerThreshold(lowerThreshold);
      }
      if (upperThreshold != null) {
        await _settingsService.saveUpperThreshold(upperThreshold);
      }
      if (pumpDuration != null) {
        await _settingsService.savePumpDuration(pumpDuration);
      }
      
      // Update IoT device settings
      _iotService.updatePumpSettings(
        automaticMode: automaticMode,
        lowerThreshold: lowerThreshold,
        upperThreshold: upperThreshold,
        pumpDuration: pumpDuration,
      );
      
      // Reload settings
      await _loadSettings();
      _clearError();
    } catch (e) {
      _setError('Failed to update settings: $e');
    }
  }
  
  void sendManualCommand(String command, Map<String, dynamic> data) {
    try {
      _iotService.sendManualCommand(command, data);
      _clearError();
    } catch (e) {
      _setError('Failed to send command: $e');
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearError() {
    _clearError();
  }
  
  @override
  void dispose() {
    _iotService.dispose();
    super.dispose();
  }
}