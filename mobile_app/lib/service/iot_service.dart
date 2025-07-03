import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:smart_irigation/entities/entities.dart';
import 'package:smart_irigation/service/plant_classification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Default configuration
  String _broker = '192.168.18.91';
  int _port = 1883;
  String _username = 'user';
  String _password = 'sehatmu';
  final String _clientId = 'smart_irrigation_app';
  late MqttClient _client;

  // Configuration keys for SharedPreferences
  static const String _brokerKey = 'mqtt_broker';
  static const String _portKey = 'mqtt_port';
  static const String _usernameKey = 'mqtt_username';
  static const String _passwordKey = 'mqtt_password';

  // Streams
  final _moistureLevelController = StreamController<double>.broadcast();
  final _temperatureController = StreamController<double>.broadcast();
  final _pumpStatusController = StreamController<bool>.broadcast();
  final _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deviceStatusController = StreamController<bool>.broadcast();
  final _plantDataController = StreamController<PlantEntity>.broadcast();
  final _pumpTimerController = StreamController<int>.broadcast();
  final _pumpModeController =
      StreamController<bool>.broadcast(); // New pump mode stream

  Stream<double> get moistureLevelStream => _moistureLevelController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<bool> get pumpStatusStream => _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;
  Stream<bool> get deviceStatusStream => _deviceStatusController.stream;
  Stream<PlantEntity> get plantDataStream => _plantDataController.stream;
  Stream<int> get pumpTimerStream => _pumpTimerController.stream;
  Stream<bool> get pumpModeStream =>
      _pumpModeController.stream; // New pump mode stream

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
  bool _currentPumpMode = false; // false = manual, true = automatic
  DateTime _lastMoistureUpdate = DateTime.now();
  DateTime _lastTemperatureUpdate = DateTime.now();
  DateTime _lastPumpStatusUpdate = DateTime.now();

  // Timer variables
  Timer? _pumpTimer;
  int _currentTimerSeconds = 0;
  bool _isTimerActive = false;

  IoTService() {
    _loadConfiguration().then((_) => _initializeMQTTClient());
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _broker = prefs.getString(_brokerKey) ?? _broker;
      _port = prefs.getInt(_portKey) ?? _port;
      _username = prefs.getString(_usernameKey) ?? _username;
      _password = prefs.getString(_passwordKey) ?? _password;

      debugPrint('Loaded configuration: $_broker:$_port');
    } catch (e) {
      debugPrint('Error loading configuration: $e');
    }
  }

  Future<void> updateConfiguration({
    required String broker,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_brokerKey, broker);
      await prefs.setInt(_portKey, port);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);

      _broker = broker;
      _port = port;
      _username = username;
      _password = password;

      debugPrint('Configuration updated: $_broker:$_port');

      // Reinitialize MQTT client with new configuration
      _initializeMQTTClient();
    } catch (e) {
      debugPrint('Error saving configuration: $e');
      throw Exception('Failed to save configuration');
    }
  }

  Map<String, dynamic> getConnectionConfig() {
    return {
      'broker': _broker,
      'port': _port,
      'username': _username,
      'password': _password,
    };
  }

  Future<bool> testConnection({
    required String broker,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final testClient = createMqttClient(broker, '${_clientId}_test', port);
      testClient.logging(on: false);
      testClient.keepAlivePeriod = 20;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('${_clientId}_test')
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      testClient.connectionMessage = connMessage;

      final status = await testClient.connect(username, password);

      if (status?.state == MqttConnectionState.connected) {
        debugPrint('Test connection successful');
        testClient.disconnect();
        return true;
      } else {
        debugPrint('Test connection failed: ${status?.state}');
        return false;
      }
    } catch (e) {
      debugPrint('Test connection error: $e');
      return false;
    }
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

      // Set timeout untuk connection
      final status = await _client
          .connect(_username, _password)
          .timeout(const Duration(seconds: 10));

      if (status == null || status.state != MqttConnectionState.connected) {
        debugPrint('MQTT connection failed - status: ${status?.state}');
        _deviceStatusController.add(false);
        throw Exception(
            'Failed to connect to MQTT broker - Check network and broker settings');
      }

      debugPrint('Successfully connected to MQTT broker');

      _client.subscribe('kelembapan_tanah', MqttQos.atMostOnce);
      _client.subscribe('data_suhu', MqttQos.atMostOnce);
      _client.subscribe('status', MqttQos.atMostOnce);
      _client.subscribe('pump_mode', MqttQos.atMostOnce);

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
        } else if (c[0].topic == 'pump_mode') {
          try {
            final modeValue = payload.trim();
            bool isAutomatic = false;

            if (modeValue == '1' || modeValue.toUpperCase() == 'AUTO') {
              isAutomatic = true;
            } else if (modeValue == '0' ||
                modeValue.toUpperCase() == 'MANUAL') {
              isAutomatic = false;
            } else {
              final intValue = int.tryParse(modeValue);
              if (intValue != null) {
                isAutomatic = intValue == 1;
              }
            }

            _currentPumpMode = isAutomatic;
            _pumpModeController.add(isAutomatic);
            debugPrint(
                'Pump mode updated: ${isAutomatic ? 'Automatic (1)' : 'Manual (0)'}');
          } catch (e) {
            debugPrint('Error parsing pump mode: $e');
          }
        }
      });
    } on TimeoutException {
      debugPrint('Connection timeout - broker not responding');
      _deviceStatusController.add(false);
      throw Exception('Connection timeout - Make sure broker is accessible');
    } catch (e) {
      debugPrint('Connection error: $e');
      _deviceStatusController.add(false);
      if (e.toString().contains('not known')) {
        throw Exception('Network error - Check WiFi connection and broker IP');
      }
      rethrow;
    }
  }

  // Get current values
  double get currentMoisture => _currentMoisture;
  double get currentTemperature => _currentTemperature;
  bool get currentPumpStatus => _currentPumpStatus;
  bool get currentPumpMode => _currentPumpMode;
  bool get isTimerActive => _isTimerActive;
  int get currentTimerSeconds => _currentTimerSeconds;
  DateTime get lastMoistureUpdate => _lastMoistureUpdate;
  DateTime get lastTemperatureUpdate => _lastTemperatureUpdate;
  DateTime get lastPumpStatusUpdate => _lastPumpStatusUpdate;

  void setPumpMode(bool isAutomatic) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot set pump mode: MQTT not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    final modeValue = isAutomatic ? '1' : '0';
    builder.addString(modeValue);

    _client.publishMessage('pump_mode', MqttQos.atLeastOnce, builder.payload!);
    debugPrint(
        'Sent pump mode: ${isAutomatic ? 'Automatic (1)' : 'Manual (0)'}');
  }

  void controlPump({required bool isOn, double? duration}) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot control pump: MQTT not connected');
      return;
    }

    if (_currentPumpMode) {
      debugPrint('Cannot control pump manually: Currently in automatic mode');
      return;
    }

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

    if (_currentPumpMode) {
      debugPrint('Cannot start pump timer: Currently in automatic mode');
      return;
    }

    _cancelTimer();

    final builder = MqttClientPayloadBuilder();
    builder.addString('1');
    _client.publishMessage('status', MqttQos.atLeastOnce, builder.payload!);

    debugPrint('Started pump timer for $seconds seconds');

    _isTimerActive = true;
    _currentTimerSeconds = seconds;
    _pumpTimerController.add(_currentTimerSeconds);

    _pumpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimerSeconds--;
      _pumpTimerController.add(_currentTimerSeconds);

      debugPrint('Pump timer: ${_currentTimerSeconds}s remaining');

      if (_currentTimerSeconds <= 0) {
        _stopPumpTimer();
      }
    });
  }

  void _stopPumpTimer() {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
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

    if (_currentPumpMode && (command == 'pump_30s' || command == 'pump_60s')) {
      debugPrint(
          'Cannot send manual pump command: Currently in automatic mode');
      return;
    }

    if (command == 'pump_30s') {
      startPumpWithTimer(30);
      return;
    } else if (command == 'pump_60s') {
      startPumpWithTimer(60);
      return;
    }

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
      builder.addString('0');
      _client.publishMessage(
        'status',
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
    _pumpTimerController.close();
    _pumpModeController.close(); // Close pump mode stream
  }
}
