import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassMorphicButton(
            onPressed: () {
              // Toggle pump status
              setState(() {
                _isPumpOn = !_isPumpOn;
              });
              widget.iotService.controlPump(isOn: _isPumpOn);
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
            onPressed: () {
              // Refresh data manually 
              widget.iotService.connect();
              HapticFeedback.lightImpact();
            },
            child: const Row(
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