import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/providers/app_provider.dart';

class PumpControlCard extends StatelessWidget {
  const PumpControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final pumpStatus = provider.pumpStatus;
        final isLoading = provider.isLoading;
        
        return GlassmorphicContainer(
          width: double.infinity,
          height: 160,
          borderRadius: 20,
          blur: 10,
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      pumpStatus ? Icons.water_drop : Icons.water_drop_outlined,
                      color: pumpStatus ? Colors.blue : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pump Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pumpStatus 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pumpStatus 
                              ? Colors.green.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        pumpStatus ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: pumpStatus ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      // Manual Control
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Manual Control',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isLoading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              else
                                Switch(
                                  value: pumpStatus,
                                  onChanged: (value) {
                                    provider.controlPump(isOn: value);
                                  },
                                  activeColor: Colors.blue,
                                  activeTrackColor: Colors.blue.withOpacity(0.3),
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quick Actions
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildQuickActionButton(
                                    icon: Icons.play_arrow,
                                    label: '30s',
                                    onTap: () => provider.sendManualCommand('pump_30s', {'duration': 30}),
                                    isLoading: isLoading,
                                  ),
                                  _buildQuickActionButton(
                                    icon: Icons.timer,
                                    label: '60s',
                                    onTap: () => provider.sendManualCommand('pump_60s', {'duration': 60}),
                                    isLoading: isLoading,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLoading 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isLoading 
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}