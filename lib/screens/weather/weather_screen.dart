import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/weather_day_row.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Schedule'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                weather.status == WeatherStatus.loaded
                    ? 'Updated ${weather.lastFetchedLabel}  ·  வானிலை & திட்டம்'
                    : 'வானிலை & திட்டம்',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WeatherProvider>().fetchWeather(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () => context.read<WeatherProvider>().fetchWeather(),
        child: _buildBody(context, weather),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WeatherProvider weather) {
    switch (weather.status) {
      case WeatherStatus.loading:
        return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 12),
            Text('Fetching weather...', style: TextStyle(color: Colors.grey)),
          ]),
        );
      case WeatherStatus.error:
        return _ErrorState(message: weather.errorMessage);
      case WeatherStatus.loaded:
        return _LoadedView(weather: weather);
      default:
        return const Center(
          child: Text('Pull down to load weather',
              style: TextStyle(color: Colors.grey)));
    }
  }
}

class _LoadedView extends StatelessWidget {
  final WeatherProvider weather;
  const _LoadedView({required this.weather});

  @override
  Widget build(BuildContext context) {
    final w = weather.current!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current weather gradient card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(w.city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('${w.temperature.toStringAsFixed(0)}°C',
                  style: const TextStyle(color: Colors.white, fontSize: 48,
                      fontWeight: FontWeight.w600, height: 1)),
              const Spacer(),
              const Icon(Icons.wb_sunny, color: Colors.white, size: 48),
            ]),
            const SizedBox(height: 6),
            Text(w.description.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(children: [
              _WeatherDetail(icon: Icons.water_drop, label: 'Humidity',
                  value: '${w.humidity.toInt()}%'),
              const SizedBox(width: 20),
              _WeatherDetail(icon: Icons.air, label: 'Wind',
                  value: '${w.windSpeed.toStringAsFixed(0)} km/h'),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        if (weather.rainSkipDays > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppTheme.skyBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${weather.rainSkipDays} day(s) this week will skip irrigation due to rain. மழை வாய்ப்பு.',
                style: const TextStyle(fontSize: 12, color: AppTheme.skyBlue),
              )),
            ]),
          ),

        // 7-day plan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration(context), // ✅ fixed
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('7-day irrigation plan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Spacer(),
              Text('7 நாள் திட்டம்',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _Legend(color: AppTheme.primaryGreen, label: 'Irrigate'),
              const SizedBox(width: 12),
              _Legend(color: AppTheme.skyBlue, label: 'Skip (rain)'),
              const SizedBox(width: 12),
              const Text('Rain %', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
            const Divider(height: 20),
            ...weather.forecast.asMap().entries.map((entry) =>
                WeatherDayRow(plan: entry.value, isToday: entry.key == 0)),
          ]),
        ),
      ],
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _WeatherDetail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Could not load weather',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            message.contains('401')
                ? 'Add your OpenWeatherMap API key in app_constants.dart'
                : 'Check your internet connection and try again',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<WeatherProvider>().fetchWeather(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }
}