import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';

class IoTService {
  final String _broker = 'broker.hivemq.com';
  final String _clientId = 'smart_irrigation_app';
  late MqttServerClient _client;
  
  // Streams untuk menangani data dari sensor dan status pompa
  final _moistureLevelController = StreamController<double>.broadcast();
  final _pumpStatusController = StreamController<bool>.broadcast();

  Stream<double> get moistureLevelStream => _moistureLevelController.stream;
  Stream<bool> get pumpStatusStream => _pumpStatusController.stream;

  IoTService() {
    _initializeMQTTClient();
  }

  void _initializeMQTTClient() {
    _client = MqttServerClient(_broker, _clientId);
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
      
      // Subscribe ke topik moisture dan pump status
      _client.subscribe('smart_irrigation/moisture', MqttQos.atMostOnce);
      _client.subscribe('smart_irrigation/pump_status', MqttQos.atMostOnce);

      _client.updates?.listen((List<MqttReceivedMessage> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        
        // Decode payload dengan cara yang benar
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

  void controlPump(bool turnOn) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(turnOn ? 'ON' : 'OFF');
    _client.publishMessage(
      'smart_irrigation/pump_control', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );
  }

  void updatePumpSettings(Map<String, dynamic> settings) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(settings));
    _client.publishMessage(
      'smart_irrigation/pump_settings', 
      MqttQos.atLeastOnce, 
      builder.payload!
    );
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker');
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    // Implementasi reconnect jika diperlukan
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
  }

  void dispose() {
    _client.disconnect();
    _moistureLevelController.close();
    _pumpStatusController.close();
  }
}