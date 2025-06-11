import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:smart_irigation/entities/entities.dart';
import 'package:smart_irigation/service/plant_classification_service.dart';

// Conditional imports for different platforms
import 'package:mqtt_client/mqtt_server_client.dart';

// Platform-specific client creation
MqttClient createMqttClient(String broker, String clientId) {
  if (kIsWeb) {
    // For web, we need to use WebSocket connection
    return MqttBrowserClient('wss://broker.hivemq.com:8884/mqtt', clientId);
  } else {
    // For mobile/desktop, use the server client
    return MqttServerClient(broker, clientId);
  }
}

class IoTService {
  final String _broker = 'broker.hivemq.com';
  final String _clientId = 'smart_irrigation_app';
  late MqttClient _client;
  
  // Streams untuk menangani data dari sensor, status pompa, dan status perangkat
  final _moistureLevelController = StreamController<double>.broadcast();
  final _pumpStatusController = StreamController<bool>.broadcast();
  final _settingsController = StreamController<Map<String, dynamic>>.broadcast();
  final _deviceStatusController = StreamController<bool>.broadcast();
  final _sensorDataController = StreamController<SensorDataEntity>.broadcast();
  final _plantDataController = StreamController<PlantEntity>.broadcast();

  Stream<double> get moistureLevelStream => _moistureLevelController.stream;
  Stream<bool> get pumpStatusStream => _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;
  Stream<bool> get deviceStatusStream => _deviceStatusController.stream;
  Stream<SensorDataEntity> get sensorDataStream => _sensorDataController.stream;
  Stream<PlantEntity> get plantDataStream => _plantDataController.stream;

  // Default settings
  final Map<String, dynamic> _currentSettings = {
    'automaticMode': true,
    'lowerThreshold': 30.0,
    'upperThreshold': 70.0,
    'pumpDuration': 60.0
  };

  IoTService() {
    _initializeMQTTClient();
  }

  void _initializeMQTTClient() {
    _client = createMqttClient(_broker, _clientId);
    _client.logging(on: true);
    _client.keepAlivePeriod = 60;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMessage;
  }

  Future<void> connect() async {
    try {
      await _client.connect();
      
      // Subscribe ke topik moisture, pump status, sensor data, dan settings
      _client.subscribe('smart_irrigation/moisture', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/pump_status', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/sensor_data', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/temperature', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/humidity', MqttQos.atMostOnce);

      // Notify the device is online
      _deviceStatusController.add(true);

      _client.updates?.listen((List<MqttReceivedMessage> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        
        final String payload = 
            const Utf8Decoder().convert(message.payload.message.toList());

        if (c[0].topic == 'smart_irrigation/moisture') {
          try {
            _moistureLevelController.add(double.parse(payload));
          } catch (e) {
            debugPrint('Error parsing moisture level: $e');
          }
        } else if (c[0].topic == 'smart_irrigation/pump_status') {
          _pumpStatusController.add(payload == 'ON');
        } else if (c[0].topic == 'smart_irrigation/sensor_data') {
          try {
            final data = jsonDecode(payload);
            final sensorData = SensorDataEntity.fromJson(data);
            _sensorDataController.add(sensorData);
          } catch (e) {
            debugPrint('Error parsing sensor data: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Connection error: $e');
      // In case of an error, mark device as offline
      _deviceStatusController.add(false);
    }
  }

  void controlPump({required bool isOn, double? duration}) {
    final builder = MqttClientPayloadBuilder();
    
    final pumpControlMessage = {
      'status': isOn ? 'ON' : 'OFF',
      'duration': duration ?? 0.0
    };

    builder.addString(jsonEncode(pumpControlMessage));
    
    _client.publishMessage(
      'smart_irrigation/pump_control', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );
  }

  void updatePumpSettings({
    bool? automaticMode,
    double? lowerThreshold,
    double? upperThreshold,
    double? pumpDuration
  }) {
    // Update local settings
    if (automaticMode != null) _currentSettings['automaticMode'] = automaticMode;
    if (lowerThreshold != null) _currentSettings['lowerThreshold'] = lowerThreshold;
    if (upperThreshold != null) _currentSettings['upperThreshold'] = upperThreshold;
    if (pumpDuration != null) _currentSettings['pumpDuration'] = pumpDuration;

    // Kirim ke perangkat IoT
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(_currentSettings));
    _client.publishMessage(
      'smart_irrigation/pump_settings', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );

    // Kirim update ke stream
    _settingsController.add(_currentSettings);
  }

  // Method untuk mendapatkan settings saat ini
  Map<String, dynamic> getCurrentSettings() {
    return Map.from(_currentSettings);
  }

  // Mengirim data plant classification ke IoT device
  void sendPlantClassificationData(PlantEntity plant) {
    final builder = MqttClientPayloadBuilder();
    
    final plantData = {
      'plantType': plant.type,
      'plantName': plant.name,
      'confidence': plant.confidence,
      'detectedAt': plant.detectedAt.toIso8601String(),
    };

    builder.addString(jsonEncode(plantData));
    
    _client.publishMessage(
      'smart_irrigation/plant_data', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );

    // Update local plant data stream
    _plantDataController.add(plant);
    
    // Auto-update irrigation settings based on plant type
    final plantClassificationService = PlantClassificationService();
    final newSettings = plantClassificationService.getIrrigationSettings(plant.type);
    updatePumpSettings(
      automaticMode: newSettings['automaticMode'],
      lowerThreshold: newSettings['lowerThreshold'],
      upperThreshold: newSettings['upperThreshold'],
      pumpDuration: newSettings['pumpDuration'],
    );
  }

  // Mengirim command manual ke IoT device
  void sendManualCommand(String command, Map<String, dynamic> data) {
    final builder = MqttClientPayloadBuilder();
    
    final commandData = {
      'command': command,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    builder.addString(jsonEncode(commandData));
    
    _client.publishMessage(
      'smart_irrigation/manual_command', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker');
    // Ensure the device is online when connected
    _deviceStatusController.add(true);
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    // Ensure the device is offline when disconnected
    _deviceStatusController.add(false);
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
  }

  void dispose() {
    _client.disconnect();
    _moistureLevelController.close();
    _pumpStatusController.close();
    _settingsController.close();
    _deviceStatusController.close();
    _sensorDataController.close();
    _plantDataController.close();
  }
}
