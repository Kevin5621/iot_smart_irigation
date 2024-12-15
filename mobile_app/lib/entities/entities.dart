class MoistureSensorEntity {
  final double moisture;
  final DateTime timestamp;

  const MoistureSensorEntity({
    required this.moisture, 
    required this.timestamp
  });
}

class IrrigationSettingsEntity {
  bool isAutoMode;
  double lowerThreshold;
  double upperThreshold;
  int pumpDuration;

  IrrigationSettingsEntity({
    this.isAutoMode = true,
    this.lowerThreshold = 30.0,
    this.upperThreshold = 70.0,
    this.pumpDuration = 60
  });
}