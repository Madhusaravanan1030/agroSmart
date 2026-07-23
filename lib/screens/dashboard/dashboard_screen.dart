import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/weather_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/motor_toggle.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensor    = context.watch<SensorProvider>();
    final irrigation = context.watch<IrrigationProvider>();
    final weather   = context.watch<WeatherProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroSmart'),
        actions: [
          if (weather.current != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(weather.city,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: AppTheme.darkGreen,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Text('வணக்கம், விவசாயி 🌱',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () => context.read<WeatherProvider>().fetchWeather(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SensorStatusBanner(isRunning: irrigation.isMotorRunning),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                SensorCard(
                  label: 'Temperature', labelTamil: 'வெப்பநிலை',
                  value: sensor.current.temperature.toStringAsFixed(1),
                  unit: '°C', icon: Icons.thermostat, tintColor: AppTheme.warmAmber,
                ),
                SensorCard(
                  label: 'Humidity', labelTamil: 'ஈரப்பதம்',
                  value: sensor.current.humidity.toStringAsFixed(0),
                  unit: '%', icon: Icons.water_drop, tintColor: AppTheme.skyBlue,
                ),
                SensorCard(
                  label: 'Soil moisture', labelTamil: 'மண் ஈரம்',
                  value: sensor.current.soilMoisture.toStringAsFixed(0),
                  unit: '%', icon: Icons.grass, tintColor: AppTheme.primaryGreen,
                ),
                SensorCard(
                  label: 'Last irrigation', labelTamil: 'கடைசி நீர்ப்பாசனம்',
                  value: sensor.lastIrrigationLabel, unit: '',
                  icon: Icons.history, tintColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const MotorToggle(),
            const SizedBox(height: 14),
            if (weather.current != null) _WeatherSummaryCard(weather: weather),
            const SizedBox(height: 14),
            _ConnectSensorBanner(),
          ],
        ),
      ),
    );
  }
}

class _SensorStatusBanner extends StatelessWidget {
  final bool isRunning;
  const _SensorStatusBanner({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isRunning ? AppTheme.lightGreen : AppTheme.lightAmber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isRunning ? Icons.water : Icons.sensors,
              color: isRunning ? AppTheme.primaryGreen : AppTheme.warmAmber,
              size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRunning
                  ? 'Irrigation running / நீர்ப்பாசனம் இயங்குகிறது'
                  : 'Sensor status: Simulated / உருவகப்படுத்தப்பட்டது',
              style: TextStyle(
                  fontSize: 12,
                  color: isRunning ? AppTheme.darkGreen : AppTheme.warmAmber,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isRunning ? AppTheme.primaryGreen : AppTheme.warmAmber,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  final WeatherProvider weather;
  const _WeatherSummaryCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final w = weather.current!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context), // ✅ fixed
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny, color: AppTheme.warmAmber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w.temperature.toStringAsFixed(0)}°C  ·  ${w.description}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Humidity ${w.humidity.toInt()}%  ·  Wind ${w.windSpeed.toStringAsFixed(0)} km/h',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (weather.rainSkipDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${weather.rainSkipDays} day(s) irrigation skipped this week due to rain',
                      style: const TextStyle(fontSize: 11, color: AppTheme.skyBlue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectSensorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_searching, color: AppTheme.primaryGreen, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect to Arduino / ESP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: AppTheme.darkGreen)),
                SizedBox(height: 2),
                Text('Real sensor data will replace simulated readings once connected',
                    style: TextStyle(fontSize: 11, color: AppTheme.darkGreen)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            child: const Text('Connect', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}