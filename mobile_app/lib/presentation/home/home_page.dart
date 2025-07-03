import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_irigation/providers/app_provider.dart';
import 'widgets/plant_card.dart';
import 'widgets/sensor_card.dart';
import 'widgets/pump_control_card.dart';
import 'widgets/settings_card.dart';
import 'package:smart_irigation/presentation/connection_config_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Auto connect dengan delay untuk memberikan waktu provider initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (!provider.isConnected) {
        // Coba connect otomatis setelah UI ready
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !provider.isConnected) {
            provider.connectToIoT();
          }
        });
      }
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        // Platform-specific image handling
        if (mounted) {
          if (kIsWeb) {
            // Untuk web, gunakan bytes langsung
            final bytes = await image.readAsBytes();
            await context.read<AppProvider>().classifyPlant(bytes);
          } else {
            // Untuk mobile/desktop, gunakan File
            final imageFile = File(image.path);
            await context.read<AppProvider>().classifyPlant(imageFile);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        // Platform-specific image handling
        if (mounted) {
          if (kIsWeb) {
            // Untuk web, gunakan bytes langsung
            final bytes = await image.readAsBytes();
            await context.read<AppProvider>().classifyPlant(bytes);
          } else {
            // Untuk mobile/desktop, gunakan File
            final imageFile = File(image.path);
            await context.read<AppProvider>().classifyPlant(imageFile);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Lebih gelap
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E1A), // Dark blue-black
              Color(0xFF1B2838), // Dark blue-grey
              Color(0xFF2C5530), // Dark green
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Header yang TIDAK scroll - Fixed di atas
                  Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Irrigation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'AI-Powered Plant Care',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Settings button
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ConnectionConfigPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Connection Settings',
                          ),
                          const SizedBox(width: 8),
                          // Connection status indicator
                          GestureDetector(
                            onTap: !provider.isConnected && !provider.isLoading
                                ? () => provider.connectToIoT()
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: provider.isConnected
                                    ? Colors.green.withOpacity(0.2)
                                    : provider.isLoading
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: provider.isConnected
                                      ? Colors.green
                                      : provider.isLoading
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (provider.isLoading)
                                    const SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        color: Colors.orange,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: provider.isConnected
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    provider.isLoading
                                        ? 'Connecting...'
                                        : provider.isConnected
                                            ? 'Online'
                                            : 'Offline',
                                    style: TextStyle(
                                      color: provider.isConnected
                                          ? Colors.green
                                          : provider.isLoading
                                              ? Colors.orange
                                              : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error/Warning Message
                  if (provider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => provider.connectToIoT(),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: provider.clearError,
                            icon: const Icon(Icons.close,
                                color: Colors.orange, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  // Content yang bisa di-scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Plant Classification Card
                          const PlantCard(),
                          const SizedBox(height: 16),

                          // Sensor Data Cards
                          const SensorCard(),
                          const SizedBox(height: 16),

                          // Pump Control Card
                          const PumpControlCard(),
                          const SizedBox(height: 16),

                          // Connection Help Card
                          if (!provider.isConnected)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Connection Help',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '• Make sure your device is connected to the same network\n'
                                    '• Check if the IoT device is powered on\n'
                                    '• Verify connection settings in Settings menu\n'
                                    '• Try connecting manually by tapping the Offline status',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              provider.connectToIoT(),
                                          icon: const Icon(Icons.refresh,
                                              size: 16),
                                          label: const Text('Try Again'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.withOpacity(0.8),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ConnectionConfigPage(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.settings,
                                              size: 16),
                                          label: const Text('Settings'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.withOpacity(0.8),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Tambah padding extra di bawah untuk FAB
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceDialog,
        backgroundColor: const Color(0xFF4CAF50), // Hijau yang lebih kontras
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Plant'),
      ),
    );
  }
}
