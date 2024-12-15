import 'package:flutter/material.dart';
import 'package:smart_irigation/models/models.dart';
import 'package:smart_irigation/presentation/schedule/schedule.dart';
import 'package:smart_irigation/presentation/home/widgets/setting.dart';
import 'package:smart_irigation/presentation/home/widgets/control_section.dart';
import 'package:smart_irigation/presentation/home/widgets/moisture_sensor_card.dart';
import 'package:smart_irigation/presentation/home/widgets/schedule_card.dart';
import 'package:smart_irigation/service/iot_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final IoTService _iotService = IoTService();
  double _moistureLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _iotService.connect();

    // Listen to moisture level stream
    _iotService.moistureLevelStream.listen((level) {
      setState(() {
        _moistureLevel = level;
      });
    });

    // Listen to pump status stream
    _iotService.pumpStatusStream.listen((status) {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _iotService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildCustomAppBar(context),
        ],
        body: _HomePageBody(
          moistureLevel: _moistureLevel,
          iotService: _iotService,
        ),
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
        onPressed: () => _openScheduledWateringPage(context), // Updated method
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

  void _openScheduledWateringPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledWateringPage(
          settings: PumpSettings(),
          onSettingsUpdated: (updatedSettings) {
            // Handle settings update if needed
            // You might want to save these settings or update app state
          },
        ),
      ),
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
  final double moistureLevel;
  final IoTService iotService;

  const _HomePageBody({
    required this.moistureLevel, 
    required this.iotService
  });

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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoistureSensorCard(moistureLevel: moistureLevel),
              const SizedBox(height: 20),
              BuildControlSection(iotService: iotService),
              const SizedBox(height: 20),
              const ScheduleCard(),
            ],
          ),
        ),
      ),
    );
  }
}