import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_irigation/service/irrigation_settings.dart';

class IrrigationSettingsService {
  static const String _automaticModeKey = 'automatic_mode';
  static const String _lowerThresholdKey = 'lower_threshold';
  static const String _upperThresholdKey = 'upper_threshold';
  static const String _pumpDurationKey = 'pump_duration';

  Future<void> saveAutomaticMode(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_automaticModeKey, isEnabled);
  }

  Future<bool> getAutomaticMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_automaticModeKey) ?? false;
  }

  Future<void> saveLowerThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lowerThresholdKey, threshold);
  }

  Future<double> getLowerThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lowerThresholdKey) ?? 30.0;
  }

  Future<void> saveUpperThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_upperThresholdKey, threshold);
  }

  Future<double> getUpperThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_upperThresholdKey) ?? 70.0;
  }

  Future<void> savePumpDuration(double duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pumpDurationKey, duration);
  }

  Future<double> getPumpDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_pumpDurationKey) ?? 10.0;
  }

  Future<IrrigationSettings> getSettings() async {
    return IrrigationSettings(
      automaticMode: await getAutomaticMode(),
      lowerThreshold: await getLowerThreshold(),
      upperThreshold: await getUpperThreshold(),
      pumpDuration: await getPumpDuration(),
    );
  }
}
