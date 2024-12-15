import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/models/models.dart';
import 'package:smart_irigation/presentation/schedule/widgets/empty_schedule_view.dart';
import 'package:smart_irigation/presentation/schedule/widgets/schedule_date.dart';

class ScheduledWateringPage extends StatefulWidget {
  final PumpSettings settings;
  final Function(PumpSettings) onSettingsUpdated;

  const ScheduledWateringPage({
    super.key,
    required this.settings,
    required this.onSettingsUpdated,
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
    ScheduleModal.show(
      context: context,
      settings: _settings,
      onSave: (updatedSettings) {
        setState(() {
          _settings = updatedSettings;
        });
        widget.onSettingsUpdated(_settings);
      },
    );
  }

  void _editScheduledWatering(IrrigationSchedule schedule) {
    ScheduleModal.show(
      context: context,
      settings: _settings,
      existingSchedule: schedule,
      onSave: (updatedSettings) {
        setState(() {
          _settings = updatedSettings;
        });
        widget.onSettingsUpdated(_settings);
      },
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87.withOpacity(0.9),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Jadwal Penyiraman',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addScheduledWatering,
                  ),
                ],
              ),
            ],
            body: _buildScheduleContent(),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _addScheduledWatering,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    if (_settings.irrigationSchedules.isEmpty) {
      return EmptyScheduleView(onAddSchedule: _addScheduledWatering);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _settings.irrigationSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _settings.irrigationSchedules[index];
        return _ScheduleListItem(
          schedule: schedule,
          days: days,
          onEdit: () => _editScheduledWatering(schedule),
          onDelete: () => _deleteSchedule(schedule),
          onToggle: (enabled) {
            setState(() {
              schedule.isEnabled = enabled;
            });
            widget.onSettingsUpdated(_settings);
          },
        );
      },
    );
  }
}

class _ScheduleListItem extends StatelessWidget {
  final IrrigationSchedule schedule;
  final List<String> days;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ScheduleListItem({
    required this.schedule,
    required this.days,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
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
      onDismissed: (direction) => onDelete(),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
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
        child: ListTile(
          onTap: onEdit,
          title: Text(
            'Waktu: ${schedule.time.format(context)}',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Durasi: ${schedule.duration} detik | '
            'Hari: ${schedule.selectedDays.map((d) => days[d]).join(', ')}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Switch(
            value: schedule.isEnabled,
            onChanged: onToggle,
            activeColor: Colors.green,
          ),
        ),
      ),
    );
  }
}
