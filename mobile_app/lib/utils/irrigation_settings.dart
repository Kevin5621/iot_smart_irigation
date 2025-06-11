class IrrigationSettings {
  final bool automaticMode;
  final double moistureThreshold;
  final double pumpDuration;
  final String plantType;

  const IrrigationSettings({
    required this.automaticMode,
    required this.moistureThreshold,
    required this.pumpDuration,
    this.plantType = '',
  });

  factory IrrigationSettings.fromMap(Map<String, dynamic> map) {
    return IrrigationSettings(
      automaticMode: map['automaticMode'] ?? false,
      moistureThreshold: (map['lowerThreshold'] ?? 30.0).toDouble(),
      pumpDuration: (map['pumpDuration'] ?? 60.0).toDouble(),
      plantType: map['plantType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'automaticMode': automaticMode,
      'lowerThreshold': moistureThreshold,
      'pumpDuration': pumpDuration,
      'plantType': plantType,
    };
  }

  IrrigationSettings copyWith({
    bool? automaticMode,
    double? moistureThreshold,
    double? pumpDuration,
    String? plantType,
  }) {
    return IrrigationSettings(
      automaticMode: automaticMode ?? this.automaticMode,
      moistureThreshold: moistureThreshold ?? this.moistureThreshold,
      pumpDuration: pumpDuration ?? this.pumpDuration,
      plantType: plantType ?? this.plantType,
    );
  }
}