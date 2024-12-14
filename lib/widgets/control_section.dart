import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_irigation/utils/button.dart';

class BuildControlSection extends StatelessWidget {
  const BuildControlSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassMorphicButton(
            onPressed: () {
              // Implement pump control
              HapticFeedback.lightImpact();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, color: Colors.white),
                SizedBox(width: 10),
                Text('Control Pump', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassMorphicButton(
            onPressed: () {
              // Implement refresh
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