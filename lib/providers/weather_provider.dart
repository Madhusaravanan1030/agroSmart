import 'package:flutter/foundation.dart';
import '../data/services/weather_service.dart';
import '../core/constants/app_constants.dart';

// Three possible states for the weather fetch
enum WeatherStatus { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final _service = WeatherService();

  WeatherStatus _status = WeatherStatus.initial;
  WeatherStatus get status => _status;

  CurrentWeather? _current;
  CurrentWeather? get current => _current;

  List<DayPlan> _forecast = [];
  List<DayPlan> get forecast => _forecast;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // When weather was last fetched (shown in the header)
  DateTime? _lastFetched;
  String get lastFetchedLabel {
    if (_lastFetched == null) return '';
    final diff = DateTime.now().difference(_lastFetched!).inMinutes;
    return '$diff min ago';
  }

  String _city = AppConstants.defaultCity;
  String get city => _city;

  /// Main fetch — gets current weather + 7-day forecast
  Future<void> fetchWeather({String? city}) async {
    _city = city ?? _city;
    _status = WeatherStatus.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchCurrent(_city),
        _service.fetchForecast(_city),
      ]);

      _current = results[0] as CurrentWeather;
      _forecast = results[1] as List<DayPlan>;
      _lastFetched = DateTime.now();
      _status = WeatherStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
    }

    notifyListeners();
  }

  /// How many days this week have irrigation skipped due to rain
  int get rainSkipDays =>
      _forecast.where((d) => !d.shouldIrrigate).length;
}