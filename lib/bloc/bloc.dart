// Service Layer: Business Logic
import 'package:flutter/material.dart';
import 'package:smart_irigation/entities/entities.dart';
import 'package:smart_irigation/repo/repo.dart';

class IrrigationService {
  final IrrigationRepository _repository;
  
  IrrigationService(this._repository);

  Future<void> autoControlPump(MoistureSensorEntity sensorData) async {
    final settings = IrrigationSettingsEntity();
    
    if (sensorData.moisture < settings.lowerThreshold) {
      await _repository.controlPump(true);
    } else if (sensorData.moisture > settings.upperThreshold) {
      await _repository.controlPump(false);
    }
  }
}

// State Management with Provider
class IrrigationProvider extends ChangeNotifier {
  final IrrigationRepository _repository;
  final IrrigationService _service;

  MoistureSensorEntity? _currentMoisture;
  IrrigationSettingsEntity _settings = IrrigationSettingsEntity();
  bool _isPumpOn = false;

  IrrigationProvider(this._repository, this._service);

  Future<void> fetchMoistureData() async {
    try {
      _currentMoisture = await _repository.readMoisture();
      
      if (_settings.isAutoMode) {
        await _service.autoControlPump(_currentMoisture!);
      }
      
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> togglePump() async {
    final newState = !_isPumpOn;
    final result = await _repository.controlPump(newState);
    
    if (result) {
      _isPumpOn = newState;
      notifyListeners();
    }
  }
}