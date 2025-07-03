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
        final pumpMode = provider.pumpMode; // false = manual, true = automatic
        final isLoading = provider.isLoading;
        final isTimerActive = provider.isTimerActive;
        final timerSeconds = provider.timerSeconds;

        return GlassmorphicContainer(
          width: double.infinity,
          height: 250, // Increased height to fix overflow
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
                    // Status indicator - hanya tampilkan ON/OFF
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: pumpStatus
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pumpStatus
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.red.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        pumpStatus ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: pumpStatus ? Colors.blue : Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pump Mode Selector
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Mode:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            // Manual Mode Button
                            Expanded(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        provider.setPumpMode(
                                            false); // Set to manual
                                      },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !pumpMode
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !pumpMode
                                          ? Colors.blue.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'Manual',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !pumpMode
                                          ? Colors.blue
                                          : Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Automatic Mode Button
                            Expanded(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        provider.setPumpMode(
                                            true); // Set to automatic
                                      },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: pumpMode
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: pumpMode
                                          ? Colors.blue.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'Auto',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: pumpMode
                                          ? Colors.blue
                                          : Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Content area - only show if manual mode
                Expanded(
                  child: pumpMode
                      ? // Automatic mode - show info message
                      Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_mode,
                                color: Colors.white.withOpacity(0.7),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Automatic Mode Active',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pump is controlled by\nsensor readings automatically',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : // Manual mode - show pump controls
                      Row(
                          children: [
                            // Manual Control
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Manual switch with timer info
                                    if (isTimerActive)
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatTime(timerSeconds),
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Timer Active',
                                              style: TextStyle(
                                                color: Colors.orange
                                                    .withOpacity(0.8),
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: pumpStatus,
                                          onChanged: isLoading
                                              ? null
                                              : (value) {
                                                  provider.controlPump(
                                                      isOn: value);
                                                },
                                          activeColor: Colors.blue,
                                          inactiveThumbColor: Colors.grey,
                                          inactiveTrackColor:
                                              Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick Actions
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildQuickActionButton(
                                          icon: Icons.timer,
                                          label: '30s',
                                          onTap: () {
                                            provider.sendManualCommand(
                                                'pump_30s', {});
                                          },
                                          isLoading: isLoading || isTimerActive,
                                        ),
                                        _buildQuickActionButton(
                                          icon: Icons.timer,
                                          label: '60s',
                                          onTap: () {
                                            provider.sendManualCommand(
                                                'pump_60s', {});
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
        width: 35,
        height: 45,
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
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
                fontSize: 9,
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
