class SensorDataEntity {
  final String deviceId;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final bool pumpStatus;
  final DateTime timestamp;
  final String? plantType;
  
  const SensorDataEntity({
    required this.deviceId,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.pumpStatus,
    required this.timestamp,
    this.plantType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'humidity': humidity,
      'pumpStatus': pumpStatus,
      'timestamp': timestamp.toIso8601String(),
      'plantType': plantType,
    };
  }
  
  factory SensorDataEntity.fromJson(Map<String, dynamic> json) {
    return SensorDataEntity(
      deviceId: json['deviceId'],
      soilMoisture: json['soilMoisture'].toDouble(),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      pumpStatus: json['pumpStatus'],
      timestamp: DateTime.parse(json['timestamp']),
      plantType: json['plantType'],
    );
  }
  
  SensorDataEntity copyWith({
    String? deviceId,
    double? soilMoisture,
    double? temperature,
    double? humidity,
    bool? pumpStatus,
    DateTime? timestamp,
    String? plantType,
  }) {
    return SensorDataEntity(
      deviceId: deviceId ?? this.deviceId,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pumpStatus: pumpStatus ?? this.pumpStatus,
      timestamp: timestamp ?? this.timestamp,
      plantType: plantType ?? this.plantType,
    );
  }
}