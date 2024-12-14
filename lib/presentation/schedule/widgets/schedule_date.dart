import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/models/models.dart';

class ScheduleModal {
  static void show({
    required BuildContext context,
    required PumpSettings settings,
    IrrigationSchedule? existingSchedule,
    required Function(PumpSettings) onSave,
  }) {
    TimeOfDay selectedTime = existingSchedule?.time ?? TimeOfDay.now();
    int duration = existingSchedule?.duration ?? settings.pumpDuration;
    List<int> selectedDays = existingSchedule?.selectedDays.toList() ?? [];
    bool isEnabled = existingSchedule?.isEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return GlassmorphicContainer(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            borderRadius: 20,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFffffff).withOpacity(0.1),
                const Color(0xFFFFFFFF).withOpacity(0.05),
              ],
              stops: const [0.1, 1],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.2),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  existingSchedule == null 
                    ? 'Tambah Jadwal Penyiraman' 
                    : 'Edit Jadwal Penyiraman',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Time Picker
                _buildTimePicker(context, selectedTime, (pickedTime) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }),
                
                // Duration Slider
                _buildDurationSlider(duration, (value) {
                  setState(() {
                    duration = value.toInt();
                  });
                }),
                
                // Day Selector
                _buildDaySelector(
                  context, 
                  selectedDays, 
                  (index, selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(index);
                      } else {
                        selectedDays.remove(index);
                      }
                    });
                  }
                ),
                
                // Schedule Enable Toggle
                _buildScheduleToggle(isEnabled, (value) {
                  setState(() {
                    isEnabled = value;
                  });
                }),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white30,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: selectedDays.isNotEmpty 
                        ? () {
                            final updatedSettings = _updateSettings(
                              settings, 
                              existingSchedule, 
                              selectedTime, 
                              selectedDays, 
                              duration, 
                              isEnabled
                            );
                            onSave(updatedSettings);
                            Navigator.pop(context);
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih minimal satu hari'),
                              ),
                            );
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildTimePicker(
    BuildContext context, 
    TimeOfDay selectedTime, 
    Function(TimeOfDay) onTimeChanged
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pilih Waktu',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: selectedTime,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.green,
                      onPrimary: Colors.white,
                      surface: Colors.black54,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (pickedTime != null) {
              onTimeChanged(pickedTime);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white30,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            'Waktu: ${selectedTime.format(context)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  static Widget _buildDurationSlider(
    int duration, 
    Function(double) onDurationChanged
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Durasi Pompa (detik)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Slider(
          value: duration.toDouble(),
          min: 10,
          max: 300,
          divisions: 29,
          label: duration.toString(),
          onChanged: onDurationChanged,
          activeColor: Colors.green,
          inactiveColor: Colors.white30,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '$duration detik',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  static Widget _buildDaySelector(
    BuildContext context,
    List<int> selectedDays,
    Function(int, bool) onDayToggle
  ) {
    final days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 
      'Jumat', 'Sabtu', 'Minggu'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pilih Hari',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                // Create a copy of selected days to avoid modifying the original list directly
                List<int> tempSelectedDays = List.from(selectedDays);

                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.black,
                      title: const Text('Pilih Hari', style: TextStyle(color: Colors.white)),
                      content: SingleChildScrollView(
                        child: Column(
                          children: List.generate(days.length, (index) {
                            final isSelected = tempSelectedDays.contains(index);
                            return ListTile(
                              title: Text(
                                days[index],
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.circle_outlined, color: Colors.white30),
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    tempSelectedDays.remove(index);
                                  } else {
                                    tempSelectedDays.add(index);
                                  }
                                });
                              },
                            );
                          }),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Batal', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            // Call the original onDayToggle with the changes
                            for (int index = 0; index < days.length; index++) {
                              final wasSelected = selectedDays.contains(index);
                              final isNowSelected = tempSelectedDays.contains(index);
                              
                              if (wasSelected != isNowSelected) {
                                onDayToggle(index, isNowSelected);
                              }
                            }
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white30,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            selectedDays.isEmpty 
              ? 'Pilih Hari' 
              : selectedDays.map((index) => days[index]).join(', '),
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildScheduleToggle(
    bool isEnabled, 
    Function(bool) onToggleChanged
  ) {
    return SwitchListTile(
      title: const Text(
        'Aktifkan Jadwal',
        style: TextStyle(color: Colors.white70),
      ),
      value: isEnabled,
      onChanged: onToggleChanged,
      activeColor: Colors.green,
    );
  }

  static PumpSettings _updateSettings(
    PumpSettings settings,
    IrrigationSchedule? existingSchedule,
    TimeOfDay selectedTime,
    List<int> selectedDays,
    int duration,
    bool isEnabled
  ) {
    final updatedSettings = PumpSettings.from(settings);

    if (existingSchedule == null) {
      final newSchedule = IrrigationSchedule(
        time: selectedTime,
        selectedDays: selectedDays,
        duration: duration,
        isEnabled: isEnabled,
      );
      updatedSettings.irrigationSchedules.add(newSchedule);
    } else {
      final index = updatedSettings.irrigationSchedules
          .indexWhere((s) => s.id == existingSchedule.id);
      if (index != -1) {
        updatedSettings.irrigationSchedules[index] = IrrigationSchedule(
          id: existingSchedule.id,
          time: selectedTime,
          selectedDays: selectedDays,
          duration: duration,
          isEnabled: isEnabled,
        );
      }
    }

    return updatedSettings;
  }
}