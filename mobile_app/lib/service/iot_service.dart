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
MqttClient createMqttClient(String broker, String clientId, int port) {
  if (kIsWeb) {
    return MqttBrowserClient('ws://$broker:9001', clientId);
  } else {
    return MqttServerClient.withPort(broker, clientId, port);
  }
}

class IoTService {
  final String _broker = '192.168.18.18';
  final int _port = 1883;
  final String _username = 'user';
  final String _password = 'sehatmu';
  final String _clientId = 'smart_irrigation_app';
  late MqttClient _client;

  // Streams
  final _moistureLevelController = StreamController<double>.broadcast();
  final _temperatureController = StreamController<double>.broadcast();
  final _pumpStatusController = StreamController<bool>.broadcast();
  final _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deviceStatusController = StreamController<bool>.broadcast();
  final _plantDataController = StreamController<PlantEntity>.broadcast();
  final _pumpTimerController =
      StreamController<int>.broadcast(); // New timer stream

  Stream<double> get moistureLevelStream => _moistureLevelController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<bool> get pumpStatusStream => _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;
  Stream<bool> get deviceStatusStream => _deviceStatusController.stream;
  Stream<PlantEntity> get plantDataStream => _plantDataController.stream;
  Stream<int> get pumpTimerStream =>
      _pumpTimerController.stream; // New timer stream

  // Default settings
  final Map<String, dynamic> _currentSettings = {
    'automaticMode': true,
    'lowerThreshold': 30.0,
    'upperThreshold': 70.0,
    'pumpDuration': 60.0
  };

  // Current values
  double _currentMoisture = 0.0;
  double _currentTemperature = 0.0;
  bool _currentPumpStatus = false;
  DateTime _lastMoistureUpdate = DateTime.now();
  DateTime _lastTemperatureUpdate = DateTime.now();
  DateTime _lastPumpStatusUpdate = DateTime.now();

  // Timer variables
  Timer? _pumpTimer;
  int _currentTimerSeconds = 0;
  bool _isTimerActive = false;

  IoTService() {
    _initializeMQTTClient();
  }

  void _initializeMQTTClient() {
    _client = createMqttClient(_broker, _clientId, _port);
    _client.logging(on: true);
    _client.keepAlivePeriod = 60;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .withWillTopic('smart_irrigation/status')
        .withWillMessage('offline')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMessage;
  }

  Future<void> connect() async {
    try {
      debugPrint('Attempting to connect to MQTT broker at $_broker:$_port');
      final status = await _client.connect(_username, _password);

      if (status == null || status.state != MqttConnectionState.connected) {
        debugPrint('MQTT connection failed - status: ${status?.state}');
        _deviceStatusController.add(false);
        throw Exception('Failed to connect to MQTT broker');
      }

      debugPrint('Successfully connected to MQTT broker');

      _client.subscribe('kelembapan_tanah', MqttQos.atMostOnce);
      _client.subscribe('data_suhu', MqttQos.atMostOnce);
      _client.subscribe('status', MqttQos.atMostOnce);

      final builder = MqttClientPayloadBuilder();
      builder.addString('online');
      _client.publishMessage(
        'smart_irrigation/status',
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );

      _deviceStatusController.add(true);

      _client.updates?.listen((List<MqttReceivedMessage> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final String payload =
            const Utf8Decoder().convert(message.payload.message.toList());

        debugPrint('Received message on ${c[0].topic}: $payload');

        if (c[0].topic == 'kelembapan_tanah') {
          try {
            final moistureValue = double.parse(payload.trim());
            _currentMoisture = moistureValue;
            _lastMoistureUpdate = DateTime.now();
            _moistureLevelController.add(moistureValue);
          } catch (e) {
            debugPrint('Error parsing moisture level: $e');
          }
        } else if (c[0].topic == 'data_suhu') {
          try {
            final temperatureValue = double.parse(payload.trim());
            _currentTemperature = temperatureValue;
            _lastTemperatureUpdate = DateTime.now();
            _temperatureController.add(temperatureValue);
          } catch (e) {
            debugPrint('Error parsing temperature: $e');
          }
        } else if (c[0].topic == 'status') {
          try {
            final statusValue = payload.trim();
            bool pumpStatus = false;

            if (statusValue == '1' || statusValue.toUpperCase() == 'ON') {
              pumpStatus = true;
            } else if (statusValue == '0' ||
                statusValue.toUpperCase() == 'OFF') {
              pumpStatus = false;
            } else {
              final intValue = int.tryParse(statusValue);
              if (intValue != null) {
                pumpStatus = intValue == 1;
              }
            }

            _currentPumpStatus = pumpStatus;
            _lastPumpStatusUpdate = DateTime.now();
            _pumpStatusController.add(pumpStatus);
          } catch (e) {
            debugPrint('Error parsing pump status: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Connection error: $e');
      _deviceStatusController.add(false);
      rethrow;
    }
  }

  // Get current values
  double get currentMoisture => _currentMoisture;
  double get currentTemperature => _currentTemperature;
  bool get currentPumpStatus => _currentPumpStatus;
  bool get isTimerActive => _isTimerActive;
  int get currentTimerSeconds => _currentTimerSeconds;
  DateTime get lastMoistureUpdate => _lastMoistureUpdate;
  DateTime get lastTemperatureUpdate => _lastTemperatureUpdate;
  DateTime get lastPumpStatusUpdate => _lastPumpStatusUpdate;

  void controlPump({required bool isOn, double? duration}) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot control pump: MQTT not connected');
      return;
    }

    // Cancel any existing timer
    _cancelTimer();

    final builder = MqttClientPayloadBuilder();
    final command = isOn ? '1' : '0';
    builder.addString(command);

    _client.publishMessage('status', MqttQos.atLeastOnce, builder.payload!);
    debugPrint('Sent pump control to status topic: $command');
  }

  void startPumpWithTimer(int seconds) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot start pump timer: MQTT not connected');
      return;
    }

    // Cancel any existing timer
    _cancelTimer();

    // Turn pump ON
    final builder = MqttClientPayloadBuilder();
    builder.addString('1');
    _client.publishMessage('status', MqttQos.atLeastOnce, builder.payload!);

    debugPrint('Started pump timer for $seconds seconds');

    // Start countdown timer
    _isTimerActive = true;
    _currentTimerSeconds = seconds;
    _pumpTimerController.add(_currentTimerSeconds);

    _pumpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimerSeconds--;
      _pumpTimerController.add(_currentTimerSeconds);

      debugPrint('Pump timer: ${_currentTimerSeconds}s remaining');

      if (_currentTimerSeconds <= 0) {
        // Time's up, turn pump OFF
        _stopPumpTimer();
      }
    });
  }

  void _stopPumpTimer() {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      // Turn pump OFF
      final builder = MqttClientPayloadBuilder();
      builder.addString('0');
      _client.publishMessage('status', MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Pump timer finished - turned pump OFF');
    }

    _cancelTimer();
  }

  void _cancelTimer() {
    if (_pumpTimer != null) {
      _pumpTimer!.cancel();
      _pumpTimer = null;
    }

    if (_isTimerActive) {
      _isTimerActive = false;
      _currentTimerSeconds = 0;
      _pumpTimerController.add(0);
      debugPrint('Pump timer cancelled');
    }
  }

  void cancelPumpTimer() {
    _cancelTimer();
  }

  void updatePumpSettings(
      {bool? automaticMode,
      double? lowerThreshold,
      double? upperThreshold,
      double? pumpDuration}) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot update settings: MQTT not connected');
      return;
    }

    if (automaticMode != null)
      _currentSettings['automaticMode'] = automaticMode;
    if (lowerThreshold != null)
      _currentSettings['lowerThreshold'] = lowerThreshold;
    if (upperThreshold != null)
      _currentSettings['upperThreshold'] = upperThreshold;
    if (pumpDuration != null) _currentSettings['pumpDuration'] = pumpDuration;

    _currentSettings['timestamp'] = DateTime.now().toIso8601String();

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(_currentSettings));
    _client.publishMessage(
        'pump_settings', MqttQos.atLeastOnce, builder.payload!);

    _settingsController.add(_currentSettings);
    debugPrint('Sent pump settings: ${jsonEncode(_currentSettings)}');
  }

  Map<String, dynamic> getCurrentSettings() {
    return Map.from(_currentSettings);
  }

  void sendPlantClassificationData(PlantEntity plant) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot send plant data: MQTT not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    final plantData = {
      'plantType': plant.type,
      'plantName': plant.name,
      'confidence': plant.confidence,
      'detectedAt': plant.detectedAt.toIso8601String(),
    };

    builder.addString(jsonEncode(plantData));
    _client.publishMessage('plant_data', MqttQos.atLeastOnce, builder.payload!);
    _plantDataController.add(plant);

    debugPrint('Sent plant data: ${jsonEncode(plantData)}');

    final plantClassificationService = PlantClassificationService();
    final newSettings =
        plantClassificationService.getIrrigationSettings(plant.type);
    updatePumpSettings(
      automaticMode: newSettings['automaticMode'],
      lowerThreshold: newSettings['lowerThreshold'],
      upperThreshold: newSettings['upperThreshold'],
      pumpDuration: newSettings['pumpDuration'],
    );
  }

  void sendManualCommand(String command, Map<String, dynamic> data) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot send manual command: MQTT not connected');
      return;
    }

    // Handle quick actions with timer
    if (command == 'pump_30s') {
      startPumpWithTimer(30);
      return;
    } else if (command == 'pump_60s') {
      startPumpWithTimer(60);
      return;
    }

    // For other commands
    final builder = MqttClientPayloadBuilder();
    final commandData = {
      'command': command,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    builder.addString(jsonEncode(commandData));
    _client.publishMessage(
        'manual_command', MqttQos.atLeastOnce, builder.payload!);

    debugPrint('Sent manual command: $command');
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker $_broker:$_port');
    _deviceStatusController.add(true);
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker');
    _deviceStatusController.add(false);
    _cancelTimer(); // Cancel timer if disconnected
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
  }

  void dispose() {
    // Cancel timer before disposing
    _cancelTimer();

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('offline');
      _client.publishMessage(
        'smart_irrigation/status',
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
    }

    _client.disconnect();
    _moistureLevelController.close();
    _temperatureController.close();
    _pumpStatusController.close();
    _settingsController.close();
    _deviceStatusController.close();
    _plantDataController.close();
    _pumpTimerController.close(); // Close timer stream
  }
}
