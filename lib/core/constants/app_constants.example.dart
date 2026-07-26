// Copy this to app_constants.dart and add your OpenWeatherMap key
// Get free key at: https://openweathermap.org/api
class AppConstants {
  static const String weatherApiKey  = 'YOUR_OPENWEATHERMAP_KEY_HERE';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String defaultCity    = 'Chennai';
  static const int    sensorRefreshSeconds = 10;
  static const double irrigationThreshold  = 40.0;
  static const double rainSkipThreshold    = 60.0;
  static const Map<String, Map<String, double>> cropRules = {
    'Rice':   {'minSoil': 70.0, 'heatStress': 38.0, 'dailyWater': 20.0},
    'Tomato': {'minSoil': 50.0, 'heatStress': 33.0, 'dailyWater': 12.0},
    'Onion':  {'minSoil': 45.0, 'heatStress': 35.0, 'dailyWater':  8.0},
    'Chilli': {'minSoil': 55.0, 'heatStress': 36.0, 'dailyWater': 10.0},
    'Banana': {'minSoil': 65.0, 'heatStress': 40.0, 'dailyWater': 25.0},
    'Cotton': {'minSoil': 40.0, 'heatStress': 42.0, 'dailyWater':  7.0},
  };
  static List<String> get allCrops => cropRules.keys.toList();
}