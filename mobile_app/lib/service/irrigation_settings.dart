class IrrigationSettings {
  bool automaticMode;
  double lowerThreshold;
  double upperThreshold;
  double pumpDuration;

  IrrigationSettings({
    this.automaticMode = false,
    this.lowerThreshold = 30.0,
    this.upperThreshold = 70.0,
    this.pumpDuration = 10.0,
  });

   Map<String, dynamic> toMap() {
    return {
      'automaticMode': automaticMode,
      'lowerThreshold': lowerThreshold,
      'upperThreshold': upperThreshold,
      'pumpDuration': pumpDuration,
    };
  }
}