// models.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class IrrigationSchedule {
  String id; // Unique identifier for each schedule
  TimeOfDay time;
  List<int> selectedDays; // 0 = Monday, 6 = Sunday
  int duration; // Pump duration in seconds
  bool isEnabled;

  IrrigationSchedule({
    String? id,
    required this.time, 
    required this.selectedDays, 
    required this.duration,
    this.isEnabled = true,
  }) : id = id ?? const Uuid().v4();

  // Deep copy constructor
  IrrigationSchedule.from(IrrigationSchedule other) 
    : id = other.id,
      time = other.time,
      selectedDays = List.from(other.selectedDays),
      duration = other.duration,
      isEnabled = other.isEnabled;

  // Untuk memudahkan serialisasi/deserialisasi jika diperlukan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': '${time.hour}:${time.minute}',
      'selectedDays': selectedDays,
      'duration': duration,
      'isEnabled': isEnabled,
    };
  }

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    // Parsing time from string
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

// Modifikasi PumpSettings untuk mendukung multiple schedules
class PumpSettings {
  double lowerThreshold;
  double upperThreshold;
  bool isAutoMode;
  int pumpDuration; // Default pump duration
  
  // Daftar jadwal penyiraman
  List<IrrigationSchedule> irrigationSchedules;

  PumpSettings({
    this.lowerThreshold = 30.0,
    this.upperThreshold = 70.0,
    this.isAutoMode = false,
    this.pumpDuration = 60, // Default 1 menit
    this.irrigationSchedules = const [],
  });
}