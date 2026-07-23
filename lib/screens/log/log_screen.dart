import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/irrigation_provider.dart';
import '../../data/models/irrigation_log.dart';
import '../../core/theme/app_theme.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Align(alignment: Alignment.centerLeft,
                child: Text('நீர்ப்பாசன பதிவு',
                    style: TextStyle(color: Colors.white70, fontSize: 12))),
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(activeFilter: irrigation.activeFilter),
          _StatsRow(irrigation: irrigation),
          Expanded(
            child: irrigation.logs.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: irrigation.logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _LogCard(log: irrigation.logs[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String activeFilter;
  const _FilterBar({required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkCard : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _FilterChip(label: 'Today',     value: 'today', active: activeFilter),
        const SizedBox(width: 8),
        _FilterChip(label: 'This week', value: 'week',  active: activeFilter),
        const SizedBox(width: 8),
        _FilterChip(label: 'Month',     value: 'month', active: activeFilter),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, active;
  const _FilterChip({required this.label, required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => context.read<IrrigationProvider>().setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final IrrigationProvider irrigation;
  const _StatsRow({required this.irrigation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(child: _StatBox(
            label: 'Total sessions', labelTa: 'மொத்த அமர்வுகள்',
            value: '${irrigation.totalSessions}')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
            label: 'Total water time', labelTa: 'மொத்த நேரம்',
            value: irrigation.totalDurationLabel)),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, labelTa, value;
  const _StatBox({required this.label, required this.labelTa, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(context), // ✅ fixed
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
        Text(label,  style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(labelTa,style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}

class _LogCard extends StatelessWidget {
  final IrrigationLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a · dd MMM').format(log.startTime);
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
            color: AppTheme.softRed, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (log.id != null) context.read<IrrigationProvider>().deleteLog(log.id!);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(context), // ✅ fixed
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _modeColor(log.mode).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_modeIcon(log.mode), color: _modeColor(log.mode), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(log.durationLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (log.skipReason != null)
              Text(log.skipReason!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.skyBlue)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _StatusBadge(status: log.status),
            const SizedBox(height: 4),
            Text(log.mode == 'auto' ? 'Auto' : 'Manual',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Color _modeColor(String mode) =>
      mode == 'auto' ? AppTheme.primaryGreen : AppTheme.skyBlue;
  IconData _modeIcon(String mode) =>
      mode == 'auto' ? Icons.autorenew : Icons.touch_app;
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'completed' => (AppTheme.lightGreen, AppTheme.darkGreen,     'Completed'),
      'skipped'   => (AppTheme.lightBlue,  AppTheme.skyBlue,       'Skipped'),
      'upcoming'  => (const Color(0xFFEEEDFE), const Color(0xFF3C3489), 'Upcoming'),
      'running'   => (AppTheme.lightGreen, AppTheme.primaryGreen,  'Running'),
      _           => (Colors.grey.shade100, Colors.grey,            status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: config.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(config.$3,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: config.$2)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 48, color: Colors.grey),
        SizedBox(height: 12),
        Text('No irrigation sessions yet',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        SizedBox(height: 4),
        Text('இன்னும் நீர்ப்பாசன பதிவு இல்லை',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}