import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';

class IoTService {
  final String _broker = 'broker.hivemq.com';
  final String _clientId = 'smart_irrigation_app';
  // late MqttServerClient _client;
  late MqttClient _client;
  
  // Streams untuk menangani data dari sensor dan status pompa
  final _moistureLevelController = StreamController<double>.broadcast();
  final _pumpStatusController = StreamController<bool>.broadcast();
  final _settingsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<double> get moistureLevelStream => _moistureLevelController.stream;
  Stream<bool> get pumpStatusStream => _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  // Default settings
  Map<String, dynamic> _currentSettings = {
    'automaticMode': true,
    'lowerThreshold': 30.0,
    'upperThreshold': 70.0,
    'pumpDuration': 60.0
  };

  IoTService() {
    _initializeMQTTClient();
  }

  void _initializeMQTTClient() {
    // _client = MqttServerClient(_broker, _clientId);
    _client = MqttClient(_broker, _clientId);
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
      
      // Subscribe ke topik moisture, pump status, dan settings
      _client.subscribe('smart_irrigation/moisture', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/pump_status', MqttQos.atMostOnce);

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
        }
      });
    } catch (e) {
      debugPrint('Connection error: $e');
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

  void _onConnected() {
    debugPrint('Connected to MQTT broker');
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
  }

  void dispose() {
    _client.disconnect();
    _moistureLevelController.close();
    _pumpStatusController.close();
    _settingsController.close();
  }
}