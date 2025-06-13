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
        final isTimerActive = provider.isTimerActive;
        final timerSeconds = provider.timerSeconds;

        return GlassmorphicContainer(
          width: double.infinity,
          height: 180,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      pumpStatus ? Icons.water_drop : Icons.water_drop_outlined,
                      color: pumpStatus ? Colors.blue : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pump Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: pumpStatus
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
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
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content area
                Expanded(
                  child: Row(
                    children: [
                      // Manual Control
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Manual Control',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Manual switch with timer info
                              if (isTimerActive)
                                Column(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(timerSeconds),
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Switch(
                                  value: pumpStatus,
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          provider.controlPump(isOn: value);
                                        },
                                  activeColor: Colors.blue,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor:
                                      Colors.grey.withOpacity(0.3),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quick Actions
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildQuickActionButton(
                                    icon: Icons.timer,
                                    label: '30s',
                                    onTap: () {
                                      provider
                                          .sendManualCommand('pump_30s', {});
                                    },
                                    isLoading: isLoading || isTimerActive,
                                  ),
                                  _buildQuickActionButton(
                                    icon: Icons.timer,
                                    label: '60s',
                                    onTap: () {
                                      provider
                                          .sendManualCommand('pump_60s', {});
                                    },
                                    isLoading: isLoading || isTimerActive,
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
        height: 50,
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLoading
                ? Colors.grey.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
