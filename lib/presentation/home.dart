import 'package:flutter/material.dart';
import 'package:smart_irigation/widgets/bottom_sheet.dart';
import 'package:smart_irigation/widgets/control_section.dart';
import 'package:smart_irigation/widgets/moisture_sensor_card.dart';
import 'package:smart_irigation/widgets/schedule_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildCustomAppBar(context),
        ],
        body: const _HomePageBody(),
      ),
    );
  }

  SliverAppBar _buildCustomAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {}, // Future: Add side menu
      ),
      title: const Text(
        'Smart Irrigation', 
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsBottomSheet(context),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsBottomSheet(),
    );
  }
}

class _HomePageBody extends StatelessWidget {
  const _HomePageBody();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoistureSensorCard(),
              SizedBox(height: 20),
              BuildControlSection(),
              SizedBox(height: 20),
              ScheduleCard(),
            ],
          ),
        ),
      ),
    );
  }
}