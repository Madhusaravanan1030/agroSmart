import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// A single metric tile — temperature, humidity, soil moisture, etc.
// Used in the Dashboard screen in a 2x2 grid.

class SensorCard extends StatelessWidget {
  final String label;       // English label
  final String labelTamil;  // Tamil label shown below
  final String value;       // e.g. "32"
  final String unit;        // e.g. "°C"
  final IconData icon;
  final Color tintColor;    // background tint

  const SensorCard({
    super.key,
    required this.label,
    required this.labelTamil,
    required this.value,
    required this.unit,
    required this.icon,
    required this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tintColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tintColor.withOpacity(0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tintColor, size: 20),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: tintColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: tintColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tintColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            labelTamil,
            style: TextStyle(
              fontSize: 10,
              color: tintColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}