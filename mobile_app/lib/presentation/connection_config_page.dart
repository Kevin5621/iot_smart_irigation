import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_irigation/providers/app_provider.dart';
import 'package:smart_irigation/service/plant_classification_service.dart';

class ConnectionConfigPage extends StatefulWidget {
  const ConnectionConfigPage({super.key});

  @override
  State<ConnectionConfigPage> createState() => _ConnectionConfigPageState();
}

class _ConnectionConfigPageState extends State<ConnectionConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _plantApiController = TextEditingController(); // TAMBAHAN BARU

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final config = provider.iotService.getConnectionConfig();

    _brokerController.text = config['broker'] ?? '';
    _portController.text = config['port']?.toString() ?? '';
    _usernameController.text = config['username'] ?? '';
    _passwordController.text = config['password'] ?? '';

    // Load plant classification URL
    final plantService = PlantClassificationService();
    final plantUrl = await plantService.getCurrentBaseUrl();
    _plantApiController.text = plantUrl;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      // Update MQTT configuration
      await provider.updateConnectionConfig(
        broker: _brokerController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update Plant Classification URL
      final plantService = PlantClassificationService();
      await plantService.updateBaseUrl(_plantApiController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      // Test MQTT connection
      final mqttSuccess = await provider.testConnection(
        broker: _brokerController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Test Plant Classification API
      final plantService = PlantClassificationService();
      final plantApiSuccess = await plantService.testConnection(
        customUrl: _plantApiController.text.trim(),
      );

      if (mounted) {
        String message;
        Color backgroundColor;

        if (mqttSuccess && plantApiSuccess) {
          message =
              '✅ MQTT and Plant Classification API connections successful!';
          backgroundColor = Colors.green;
        } else if (mqttSuccess && !plantApiSuccess) {
          message = '⚠️ MQTT connected but Plant Classification API failed!';
          backgroundColor = Colors.orange;
        } else if (!mqttSuccess && plantApiSuccess) {
          message = '⚠️ Plant Classification API connected but MQTT failed!';
          backgroundColor = Colors.orange;
        } else {
          message =
              '❌ Both MQTT and Plant Classification API connections failed!';
          backgroundColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text(
          'Connection Config',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF1B2838),
              Color(0xFF2C5530),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: double.infinity,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(
                                  Icons.settings_ethernet,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Service Configuration',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Form Fields
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // MQTT Section
                                    _buildSectionHeader(
                                        'MQTT Broker Configuration'),
                                    const SizedBox(height: 12),

                                    // Broker IP
                                    _buildInputField(
                                      controller: _brokerController,
                                      label: 'Broker IP Address',
                                      hint: '192.168.1.100',
                                      icon: Icons.router,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter broker IP';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Port
                                    _buildInputField(
                                      controller: _portController,
                                      label: 'Port',
                                      hint: '1883',
                                      icon: Icons.electrical_services,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter port';
                                        }
                                        final port = int.tryParse(value!);
                                        if (port == null ||
                                            port <= 0 ||
                                            port > 65535) {
                                          return 'Please enter valid port (1-65535)';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Username
                                    _buildInputField(
                                      controller: _usernameController,
                                      label: 'Username',
                                      hint: 'user',
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password
                                    _buildInputField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'password',
                                      icon: Icons.lock,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Plant Classification API Section
                                    _buildSectionHeader(
                                        'Plant Classification API'),
                                    const SizedBox(height: 12),

                                    // Plant API URL
                                    _buildInputField(
                                      controller: _plantApiController,
                                      label: 'FastAPI Base URL',
                                      hint: 'http://192.168.1.100:8000',
                                      icon: Icons.api,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter FastAPI URL';
                                        }
                                        // Basic URL validation
                                        if (!value!.startsWith('http://') &&
                                            !value.startsWith('https://')) {
                                          return 'URL must start with http:// or https://';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Info Panel
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline,
                                              color: Colors.blue, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Service Endpoints',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '• MQTT: For sensor data and pump control\n'
                                                  '• FastAPI: For plant classification AI\n'
                                                  '• Both services can run on different servers',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Action Buttons
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                // Test Connection Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _testConnection,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.wifi_find),
                                    label: Text(
                                        _isLoading ? 'Testing...' : 'Test All'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.orange.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Save Button
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _saveConfig,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(_isLoading
                                        ? 'Saving...'
                                        : 'Save & Connect'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && !_isPasswordVisible,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _plantApiController.dispose(); // TAMBAHAN BARU
    super.dispose();
  }
}
