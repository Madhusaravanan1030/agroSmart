import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/services/weather_service.dart';
import '../core/theme/app_theme.dart';

// One row in the 7-day irrigation plan.
// Shows: day name | irrigation bar | rain % | irrigate/skip badge

class WeatherDayRow extends StatelessWidget {
  final DayPlan plan;
  final bool isToday;

  const WeatherDayRow({
    super.key,
    required this.plan,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = isToday ? 'Today' : DateFormat('EEE').format(plan.date);
    final shouldIrrigate = plan.shouldIrrigate;
    final barColor =
        shouldIrrigate ? AppTheme.primaryGreen : AppTheme.skyBlue;
    final barWidth = plan.irrigationLevel / 100; // 0.0 – 1.0

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 44,
            child: Text(
              dayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday
                    ? AppTheme.primaryGreen
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),

          // Irrigation bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barWidth,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Rain probability
          SizedBox(
            width: 36,
            child: Text(
              '${plan.rainProbability.toInt()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: plan.rainProbability > 60
                    ? AppTheme.skyBlue
                    : Colors.grey,
                fontWeight: plan.rainProbability > 60
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Irrigate / skip badge
          SizedBox(
            width: 52,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: shouldIrrigate
                    ? AppTheme.lightGreen
                    : AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shouldIrrigate ? 'Water' : 'Skip',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: shouldIrrigate
                      ? AppTheme.darkGreen
                      : AppTheme.skyBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}