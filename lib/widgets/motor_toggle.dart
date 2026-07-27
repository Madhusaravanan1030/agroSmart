import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../providers/sensor_provider.dart';
import '../core/theme/app_theme.dart';

class MotorToggle extends StatelessWidget {
  const MotorToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationProvider>();
    final sensor     = context.watch<SensorProvider>();
    final isRunning  = irrigation.isMotorRunning;
    final isAuto     = irrigation.isAutoMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(children: [
            Icon(Icons.settings_remote,
                color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 8),
            const Text('Motor control',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 4),
            const Text('/ மோட்டார்',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            // Running indicator
            if (isRunning)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen, shape: BoxShape.circle),
              ),
          ]),
          const SizedBox(height: 12),

          // ── Auto mode switch ──────────────────────────────────
          _SwitchRow(
            label: 'Auto mode',
            labelTa: 'தானியங்கி முறை',
            value: isAuto,
            onChanged: (val) =>
                context.read<IrrigationProvider>().toggleAutoMode(val),
          ),
          const Divider(height: 16),

          // ── Manual override switch ────────────────────────────
          _SwitchRow(
            label: 'Manual override',
            labelTa: 'கைமுறை கட்டுப்பாடு',
            value: !isAuto,
            onChanged: (val) =>
                context.read<IrrigationProvider>().toggleAutoMode(!val),
          ),
          const SizedBox(height: 16),

          // ── Start / Stop button ───────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // ✅ Never null — always tappable
              onPressed: () => _handleMotorPress(context, irrigation, sensor),
              icon: Icon(
                isRunning ? Icons.stop_circle : Icons.play_circle,
                size: 20,
              ),
              label: Text(
                isRunning
                    ? 'Stop Motor / நிறுத்து'
                    : 'Start Motor / தொடங்கு',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isRunning ? AppTheme.softRed : AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),

          // ── Web notice ────────────────────────────────────────
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Motor log saved in memory on web (resets on refresh)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ]),
            ),

          // ── Auto irrigation hint ──────────────────────────────
          if (isAuto && sensor.current.needsIrrigation && !isRunning)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppTheme.warmAmber),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Soil moisture low — auto irrigation recommended',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.warmAmber),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _handleMotorPress(
    BuildContext context,
    IrrigationProvider irrigation,
    SensorProvider sensor,
  ) async {
    try {
      if (irrigation.isMotorRunning) {
        await context.read<IrrigationProvider>().stopMotor();
        if (context.mounted) {
          context.read<SensorProvider>().onMotorStopped();
        }
      } else {
        final mode = irrigation.isAutoMode ? 'auto' : 'manual';
        await context.read<IrrigationProvider>().startMotor(mode: mode);
        if (context.mounted) {
          context.read<SensorProvider>().onMotorStarted();
        }
      }
    } catch (e) {
      debugPrint('Motor press error: $e');
      // Show a snackbar if something goes wrong
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Motor error: ${e.toString()}'),
            backgroundColor: AppTheme.softRed,
          ),
        );
      }
    }
  }
}

class _SwitchRow extends StatelessWidget {
  final String label, labelTa;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.labelTa,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
        Text(labelTa,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      const Spacer(),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
    ]);
  }
}