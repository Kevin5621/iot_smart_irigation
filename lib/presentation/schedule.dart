import 'package:flutter/material.dart';
import 'package:smart_irigation/models/models.dart';

class ScheduledWateringPage extends StatefulWidget {
  final PumpSettings settings;
  final Function(PumpSettings) onSettingsUpdated;

  const ScheduledWateringPage({
    super.key, 
    required this.settings, 
    required this.onSettingsUpdated
  });

  @override
  _ScheduledWateringPageState createState() => _ScheduledWateringPageState();
}

class _ScheduledWateringPageState extends State<ScheduledWateringPage> {
  late PumpSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = PumpSettings.from(widget.settings);
  }

  void _addScheduledWatering() {
    _showScheduleModal(null);
  }

  void _editScheduledWatering(IrrigationSchedule schedule) {
    _showScheduleModal(schedule);
  }

  void _showScheduleModal(IrrigationSchedule? existingSchedule) {
    TimeOfDay selectedTime = existingSchedule?.time ?? TimeOfDay.now();
    int duration = existingSchedule?.duration ?? _settings.pumpDuration;
    List<int> selectedDays = existingSchedule?.selectedDays.toList() ?? [];
    bool isEnabled = existingSchedule?.isEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingSchedule == null 
                    ? 'Tambah Jadwal Penyiraman' 
                    : 'Edit Jadwal Penyiraman',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // Pilih Waktu
                ElevatedButton(
                  onPressed: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    
                    if (pickedTime != null) {
                      setState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Text(
                    'Waktu: ${selectedTime.format(context)}',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Pilih Durasi Pompa
                Row(
                  children: [
                    const Text('Durasi Pompa (detik):'),
                    Slider(
                      value: duration.toDouble(),
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: duration.toString(),
                      onChanged: (double value) {
                        setState(() {
                          duration = value.toInt();
                        });
                      },
                    ),
                    Text('$duration detik'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Pilih Hari
                const Text('Pilih Hari:'),
                Wrap(
                  spacing: 8.0,
                  children: List.generate(7, (index) {
                    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                    final isSelected = selectedDays.contains(index);
                    
                    return ChoiceChip(
                      label: Text(days[index]),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedDays.add(index);
                          } else {
                            selectedDays.remove(index);
                          }
                        });
                      },
                    );
                  }),
                ),
                
                const SizedBox(height: 16),
                
                // Aktifkan/Nonaktifkan Jadwal
                SwitchListTile(
                  title: const Text('Aktifkan Jadwal'),
                  value: isEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      isEnabled = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedDays.isNotEmpty) {
                          if (existingSchedule == null) {
                            // Tambah jadwal baru
                            final newSchedule = IrrigationSchedule(
                              time: selectedTime,
                              selectedDays: selectedDays,
                              duration: duration,
                              isEnabled: isEnabled,
                            );
                            _settings.irrigationSchedules.add(newSchedule);
                          } else {
                            // Edit jadwal yang ada
                            final index = _settings.irrigationSchedules
                                .indexWhere((s) => s.id == existingSchedule.id);
                            if (index != -1) {
                              _settings.irrigationSchedules[index] = IrrigationSchedule(
                                id: existingSchedule.id,
                                time: selectedTime,
                                selectedDays: selectedDays,
                                duration: duration,
                                isEnabled: isEnabled,
                              );
                            }
                          }

                          widget.onSettingsUpdated(_settings);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih minimal satu hari'),
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _deleteSchedule(IrrigationSchedule schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Jadwal'),
          content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _settings.irrigationSchedules
                      .removeWhere((s) => s.id == schedule.id);
                });
                widget.onSettingsUpdated(_settings);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Penyiraman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addScheduledWatering,
            tooltip: 'Tambah Jadwal',
          ),
        ],
      ),
      body: _buildScheduleContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addScheduledWatering,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleContent() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    if (_settings.irrigationSchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada jadwal penyiraman',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addScheduledWatering,
              child: const Text('Tambah Jadwal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _settings.irrigationSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _settings.irrigationSchedules[index];
        return Dismissible(
          key: Key(schedule.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Hapus Jadwal'),
                  content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            setState(() {
              _settings.irrigationSchedules.removeAt(index);
            });
            widget.onSettingsUpdated(_settings);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                'Waktu: ${schedule.time.format(context)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Durasi: ${schedule.duration} detik | '
                'Hari: ${schedule.selectedDays.map((d) => days[d]).join(', ')}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: schedule.isEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        schedule.isEnabled = value;
                      });
                      widget.onSettingsUpdated(_settings);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editScheduledWatering(schedule),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}