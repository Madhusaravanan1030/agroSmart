import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/crop.dart';
import '../data/models/sensor_data.dart';

// A tip shown in the Crop Advisor screen
class CropTip {
  final String cropName;
  final String cropNameTamil;
  final String messageEn;
  final String messageTa;
  final String severity; // 'info' | 'warning' | 'urgent'

  const CropTip({
    required this.cropName,
    required this.cropNameTamil,
    required this.messageEn,
    required this.messageTa,
    required this.severity,
  });
}

class CropProvider extends ChangeNotifier {
  List<String> _selectedCropNames = []; // names of crops farmer added
  List<String> get selectedCropNames => _selectedCropNames;

  List<Crop> get selectedCrops => _selectedCropNames
      .map((n) => Crop.findByName(n))
      .whereType<Crop>()
      .toList();

  List<CropTip> _tips = [];
  List<CropTip> get tips => _tips;

  // Load saved crop selection from SharedPreferences on app start
  Future<void> loadSavedCrops() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCropNames = prefs.getStringList('selectedCrops') ?? ['Rice'];
    notifyListeners();
  }

  Future<void> addCrop(String name) async {
    if (_selectedCropNames.contains(name)) return;
    _selectedCropNames.add(name);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> removeCrop(String name) async {
    _selectedCropNames.remove(name);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedCrops', _selectedCropNames);
  }

  // ── Offline tip engine ────────────────────────────────────────
  // Generates bilingual tips based on current sensor readings.
  // No internet needed — pure rules-based logic.

  void generateTips(SensorData sensor, {double? rainProbability}) {
    _tips = [];

    for (final crop in selectedCrops) {
      // Low soil moisture → needs water
      if (sensor.soilMoisture < crop.minSoilMoisture) {
        _tips.add(CropTip(
          cropName:      crop.name,
          cropNameTamil: crop.nameTamil,
          severity:      'urgent',
          messageEn: '${crop.name} needs ${crop.dailyWaterMm.toInt()}mm water '
              'today — soil moisture is low (${sensor.soilMoisture.toInt()}%)',
          messageTa: '${crop.nameTamil}க்கு இன்று ${crop.dailyWaterMm.toInt()}mm '
              'தண்ணீர் தேவை — மண் ஈரம் குறைவாக உள்ளது (${sensor.soilMoisture.toInt()}%)',
        ));
      }

      // Heat stress warning
      if (sensor.temperature > crop.heatStressTemp) {
        _tips.add(CropTip(
          cropName:      crop.name,
          cropNameTamil: crop.nameTamil,
          severity:      'warning',
          messageEn: '${crop.name} — skip afternoon watering, '
              'heat stress risk above ${crop.heatStressTemp.toInt()}°C',
          messageTa: '${crop.nameTamil} — வெப்பம் அதிகமாக உள்ளது '
              '(${sensor.temperature.toInt()}°C), பகல் நீர்ப்பாசனம் வேண்டாம்',
        ));
      }

      // Rain coming — hold fertilizer
      if (rainProbability != null && rainProbability > 60) {
        _tips.add(CropTip(
          cropName:      crop.name,
          cropNameTamil: crop.nameTamil,
          severity:      'info',
          messageEn: 'Rain expected — hold off on fertilizer for ${crop.name}',
          messageTa: 'மழை வாய்ப்பு உள்ளது — ${crop.nameTamil}க்கு '
              'உரம் போட வேண்டாம்',
        ));
        break; // One rain tip is enough regardless of crop count
      }

      // Soil is good
      if (sensor.soilMoisture >= crop.minSoilMoisture &&
          sensor.temperature <= crop.heatStressTemp) {
        _tips.add(CropTip(
          cropName:      crop.name,
          cropNameTamil: crop.nameTamil,
          severity:      'info',
          messageEn: '${crop.name} conditions are good today',
          messageTa: '${crop.nameTamil}க்கு இன்று நிலைமை சரியாக உள்ளது',
        ));
      }
    }

    notifyListeners();
  }
}