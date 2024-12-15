import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MoistureData {
  final double moisture;
  final DateTime timestamp;

  MoistureData({required this.moisture, required this.timestamp});
}

class IrrigationSchedule {
  String id;
  TimeOfDay time;
  List<int> selectedDays;
  int duration;
  bool isEnabled;

  IrrigationSchedule({
    String? id,
    required this.time, 
    required this.selectedDays, 
    required this.duration,
    this.isEnabled = true,
  }) : id = id ?? const Uuid().v4();

  IrrigationSchedule.from(IrrigationSchedule other) 
    : id = other.id,
      time = other.time,
      selectedDays = List.from(other.selectedDays),
      duration = other.duration,
      isEnabled = other.isEnabled;

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    List<String> timeParts = json['time'].split(':');
    return IrrigationSchedule(
      id: json['id'],
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      selectedDays: List<int>.from(json['selectedDays']),
      duration: json['duration'],
      isEnabled: json['isEnabled'],
    );
  }
}

class PumpSettings {
  double lowerThreshold;
  double upperThreshold;
  bool isAutoMode;
  int pumpDuration;
  
  List<IrrigationSchedule> irrigationSchedules;

  PumpSettings({
    this.lowerThreshold = 30.0,
    this.upperThreshold = 70.0,
    this.isAutoMode = false,
    this.pumpDuration = 60,
    List<IrrigationSchedule>? irrigationSchedules,
  }) : irrigationSchedules = irrigationSchedules ?? [];

  PumpSettings.from(PumpSettings other)
    : lowerThreshold = other.lowerThreshold,
      upperThreshold = other.upperThreshold,
      isAutoMode = other.isAutoMode,
      pumpDuration = other.pumpDuration,
      irrigationSchedules = other.irrigationSchedules
          .map((schedule) => IrrigationSchedule.from(schedule))
          .toList();

  factory PumpSettings.fromJson(Map<String, dynamic> json) {
    return PumpSettings(
      lowerThreshold: json['lowerThreshold'],
      upperThreshold: json['upperThreshold'],
      isAutoMode: json['isAutoMode'],
      pumpDuration: json['pumpDuration'],
      irrigationSchedules: (json['irrigationSchedules'] as List)
          .map((s) => IrrigationSchedule.fromJson(s))
          .toList(),
    );
  }
}