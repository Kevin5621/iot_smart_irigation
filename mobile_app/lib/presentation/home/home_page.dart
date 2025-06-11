import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_irigation/providers/app_provider.dart';
import 'widgets/plant_card.dart';
import 'widgets/sensor_card.dart';
import 'widgets/pump_control_card.dart';
import 'widgets/settings_card.dart';
import 'package:smart_irigation/utils/button.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().connectToIoT();
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
        final File imageFile = File(image.path);
        if (mounted) {
          await context.read<AppProvider>().classifyPlant(imageFile);
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
        final File imageFile = File(image.path);
        if (mounted) {
          await context.read<AppProvider>().classifyPlant(imageFile);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Header
                  Padding(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: provider.isConnected
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: provider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                provider.isConnected ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: provider.isConnected
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Error Message
                  if (provider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: provider.clearError,
                            icon: const Icon(Icons.close, color: Colors.red, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  
                  // Content
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
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
                                
                                // Settings Card
                                const SettingsCard(),
                                const SizedBox(height: 20),
                                
                                // Camera Button
                                CustomButton(
                                  text: 'Take Photo for Plant Classification',
                                  onPressed: provider.isLoading ? null : () => _showImageSourceDialog(),
                                  icon: Icons.camera_alt,
                                ),
                                
                                // Connection Status
                                if (!provider.isConnected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'IoT device not connected. Check your connection.',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 14,
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
                                      ],
                                    ),
                                  ),
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
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Plant'),
      ),
    );
  }
}