import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

// Holds today's current weather
class CurrentWeather {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;   // e.g. "Sunny", "Light rain"
  final String icon;          // e.g. "01d" — used to pick a weather icon
  final String city;

  const CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.city,
  });
}

// One day in the 7-day irrigation schedule
class DayPlan {
  final DateTime date;
  final double rainProbability;   // 0–100%
  final double maxTemp;
  final bool shouldIrrigate;      // false when rain probability is high

  const DayPlan({
    required this.date,
    required this.rainProbability,
    required this.maxTemp,
    required this.shouldIrrigate,
  });

  // How much irrigation to do today (0–100 scale for the progress bar)
  double get irrigationLevel => shouldIrrigate ? (100 - rainProbability) : 10;
}

class WeatherService {
  /// Fetch current weather for [city]
  Future<CurrentWeather> fetchCurrent(String city) async {
    final url = Uri.parse(
      '${AppConstants.weatherBaseUrl}/weather'
      '?q=$city'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return CurrentWeather(
      temperature: (data['main']['temp'] as num).toDouble(),
      humidity:    (data['main']['humidity'] as num).toDouble(),
      windSpeed:   (data['wind']['speed'] as num).toDouble(),
      description: (data['weather'][0]['description'] as String),
      icon:        (data['weather'][0]['icon'] as String),
      city:        data['name'] as String,
    );
  }

  /// Fetch 5-day forecast (OpenWeatherMap free tier gives 5 days / 3-hour intervals)
  /// We group by day and build the irrigation schedule from it.
  Future<List<DayPlan>> fetchForecast(String city) async {
    final url = Uri.parse(
      '${AppConstants.weatherBaseUrl}/forecast'
      '?q=$city'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Forecast fetch failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List items = data['list'] as List;

    // Group forecast items by day
    final Map<String, List<dynamic>> byDay = {};
    for (final item in items) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as int) * 1000,
      );
      final key = '${dt.year}-${dt.month}-${dt.day}';
      byDay.putIfAbsent(key, () => []).add(item);
    }

    // Build one DayPlan per day
    final plans = <DayPlan>[];
    for (final entry in byDay.entries.take(7)) {
      final dayItems = entry.value;

      // Average rain probability across all intervals in the day
      final avgRain = dayItems
          .map((i) => ((i['pop'] ?? 0) as num).toDouble() * 100)
          .reduce((a, b) => a + b) / dayItems.length;

      // Max temperature of the day
      final maxTemp = dayItems
          .map((i) => ((i['main']['temp_max']) as num).toDouble())
          .reduce((a, b) => a > b ? a : b);

      // Parse the date from the key
      final parts = entry.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      plans.add(DayPlan(
        date: date,
        rainProbability: avgRain,
        maxTemp: maxTemp,
        // Skip irrigation if rain chance is above the threshold in constants
        shouldIrrigate: avgRain < AppConstants.rainSkipThreshold,
      ));
    }

    return plans;
  }
}