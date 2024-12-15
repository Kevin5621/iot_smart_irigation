import 'package:flutter/material.dart';

class EmptyScheduleView extends StatelessWidget {
  final VoidCallback onAddSchedule;

  const EmptyScheduleView({
    super.key,
    required this.onAddSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada jadwal penyiraman',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: onAddSchedule,
              child: Text('Tambah Jadwal', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}