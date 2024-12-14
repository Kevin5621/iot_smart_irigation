import 'package:smart_irigation/entities/entities.dart';
import 'package:smart_irigation/service/iot_service.dart';
import 'package:smart_irigation/models/models.dart';

abstract class IrrigationRepository {
  Future<MoistureSensorEntity> readMoisture();
  Future<bool> controlPump(bool state);
  Future<void> updateSettings(IrrigationSettingsEntity settings);
}

// Concrete Repository Implementation
class IoTHardwareRepository implements IrrigationRepository {
  final IotService _iotService;

  IoTHardwareRepository(this._iotService);

  @override
  Future<MoistureSensorEntity> readMoisture() async {
    final moistureData = await _iotService.readMoisture();
    return MoistureSensorEntity(
      moisture: moistureData.moisture, 
      timestamp: DateTime.now()
    );
  }

  @override
  Future<bool> controlPump(bool state) => _iotService.controlPump(state);

  @override
  Future<void> updateSettings(IrrigationSettingsEntity settings) async {
    // Convert domain entity to service-specific model
    final pumpSettings = PumpSettings(
      isAutoMode: settings.isAutoMode,
      lowerThreshold: settings.lowerThreshold,
      upperThreshold: settings.upperThreshold,
      pumpDuration: settings.pumpDuration
    );
    await _iotService.updateSettings(pumpSettings);
  }
}
