import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_irigation/presentation/home/home.dart';
import 'package:smart_irigation/service/iot_service.dart';
import 'package:smart_irigation/utils/button.dart';

class BuildControlSection extends StatefulWidget {
  final IoTService iotService;

  const BuildControlSection({
    super.key, 
    required this.iotService
  });

  @override
  _BuildControlSectionState createState() => _BuildControlSectionState();
}

class _BuildControlSectionState extends State<BuildControlSection> {
  bool _isPumpOn = false;
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Reconnect to MQTT
      await widget.iotService.connect();

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh data: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to pump status from IoT device
    widget.iotService.pumpStatusStream.listen((status) {
      setState(() {
        _isPumpOn = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassMorphicButton(
            onPressed: () {
              // Toggle pump status through IoT service
              widget.iotService.controlPump(
                isOn: !_isPumpOn, 
              );
              HapticFeedback.lightImpact();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop, 
                  color: _isPumpOn ? Colors.blue : Colors.white
                ),
                const SizedBox(width: 10),
                Text(
                  _isPumpOn ? 'Stop Pump' : 'Control Pump', 
                  style: const TextStyle(color: Colors.white)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassMorphicButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage())),
            child: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Refresh Data', style: TextStyle(color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}