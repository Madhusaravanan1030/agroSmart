import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/irrigation_provider.dart';
import '../../data/models/irrigation_log.dart';
import '../../core/theme/app_theme.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Usage'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyChart(),
          _WeeklyChart(),
          _MonthlyChart(),
        ],
      ),
    );
  }
}

// ── Shared stat card ───────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(sub,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper: build bar chart data from logs ─────────────────────

List<BarChartGroupData> _buildBars(
  List<MapEntry<int, int>> entries, {
  Color color = AppTheme.primaryGreen,
}) {
  return entries.map((e) {
    return BarChartGroupData(
      x: e.key,
      barRods: [
        BarChartRodData(
          toY: e.value.toDouble(),
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }).toList();
}

// ── Daily chart — hours per hour of today ─────────────────────

class _DailyChart extends StatelessWidget {
  const _DailyChart();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<IrrigationProvider>().logs;
    // Build minutes per 4-hour block (0,4,8,12,16,20)
    final Map<int, int> blocks = {0: 0, 4: 0, 8: 0, 12: 0, 16: 0, 20: 0};
    for (final log in logs) {
      if (log.status != 'completed' || log.duration == null) continue;
      final hour = log.startTime.hour;
      final block = (hour ~/ 4) * 4;
      blocks[block] = (blocks[block] ?? 0) + log.duration!.inMinutes;
    }

    final totalMin = blocks.values.fold(0, (a, b) => a + b);
    final entries = blocks.entries.map((e) => MapEntry(e.key, e.value)).toList();

    return _ChartPage(
      title: 'Today\'s irrigation',
      titleTa: 'இன்றைய நீர்ப்பாசனம்',
      statLabel: 'Total today',
      statValue: totalMin >= 60
          ? '${totalMin ~/ 60}h ${totalMin % 60}m'
          : '${totalMin}m',
      statSub: '${logs.where((l) => l.status == 'completed').length} sessions',
      statColor: AppTheme.primaryGreen,
      chart: _buildBarChart(
        context: context,
        bars: _buildBars(entries),
        maxY: (blocks.values.fold(0, (a, b) => a > b ? a : b) + 10).toDouble(),
        getTitle: (v, _) => Text(
          '${v.toInt()}h',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        leftTitle: 'min',
      ),
    );
  }
}

// ── Weekly chart — minutes per day for last 7 days ────────────

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationProvider>();
    // We need all logs — trigger week filter
    final logs = irrigation.logs;

    final now = DateTime.now();
    // Build minutes per weekday (0=Mon … 6=Sun) for last 7 days
    final Map<int, int> byDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (final log in logs) {
      if (log.status != 'completed' || log.duration == null) continue;
      final diff = now.difference(log.startTime).inDays;
      if (diff < 7) {
        final idx = 6 - diff; // 6=today, 0=6 days ago
        byDay[idx] = (byDay[idx] ?? 0) + log.duration!.inMinutes;
      }
    }

    final totalMin = byDay.values.fold(0, (a, b) => a + b);
    final entries = byDay.entries.map((e) => MapEntry(e.key, e.value)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d);
    });

    return _ChartPage(
      title: 'Last 7 days',
      titleTa: 'கடந்த 7 நாட்கள்',
      statLabel: 'Total this week',
      statValue: totalMin >= 60
          ? '${totalMin ~/ 60}h ${totalMin % 60}m'
          : '${totalMin}m',
      statSub: 'Avg ${(totalMin / 7).round()} min/day',
      statColor: AppTheme.skyBlue,
      chart: _buildBarChart(
        context: context,
        bars: _buildBars(entries, color: AppTheme.skyBlue),
        maxY: (byDay.values.fold(0, (a, b) => a > b ? a : b) + 10).toDouble(),
        getTitle: (v, meta) {
          final idx = v.toInt().clamp(0, 6);
          return Text(
            dayLabels[idx],
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          );
        },
        leftTitle: 'min',
      ),
    );
  }
}

// ── Monthly chart — sessions per week of this month ───────────

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<IrrigationProvider>().logs;
    final now = DateTime.now();
    // Group by week of month (1–5)
    final Map<int, int> byWeek = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final log in logs) {
      if (log.status != 'completed' || log.duration == null) continue;
      if (log.startTime.month != now.month) continue;
      final week = ((log.startTime.day - 1) ~/ 7) + 1;
      byWeek[week] = (byWeek[week] ?? 0) + log.duration!.inMinutes;
    }

    final totalMin = byWeek.values.fold(0, (a, b) => a + b);
    final entries = byWeek.entries.map((e) => MapEntry(e.key, e.value)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _ChartPage(
      title: DateFormat('MMMM yyyy').format(now),
      titleTa: 'இந்த மாதம்',
      statLabel: 'Total this month',
      statValue: totalMin >= 60
          ? '${totalMin ~/ 60}h ${totalMin % 60}m'
          : '${totalMin}m',
      statSub: '${logs.where((l) => l.status == 'completed' && l.startTime.month == now.month).length} sessions',
      statColor: AppTheme.warmAmber,
      chart: _buildBarChart(
        context: context,
        bars: _buildBars(entries, color: AppTheme.warmAmber),
        maxY: (byWeek.values.fold(0, (a, b) => a > b ? a : b) + 10).toDouble(),
        getTitle: (v, _) => Text(
          'W${v.toInt()}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        leftTitle: 'min',
      ),
    );
  }
}

// ── Shared chart page layout ───────────────────────────────────

class _ChartPage extends StatelessWidget {
  final String title;
  final String titleTa;
  final String statLabel;
  final String statValue;
  final String statSub;
  final Color statColor;
  final Widget chart;

  const _ChartPage({
    required this.title,
    required this.titleTa,
    required this.statLabel,
    required this.statValue,
    required this.statSub,
    required this.statColor,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(width: 6),
            Text(titleTa,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        _StatRow(
          label: statLabel,
          value: statValue,
          sub: statSub,
          color: statColor,
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: AppTheme.cardDecoration(context),
          child: chart,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.cardDecoration(context),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Swipe left/right to switch between daily, weekly, and monthly views',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared bar chart builder ───────────────────────────────────

Widget _buildBarChart({
  required BuildContext context,
  required List<BarChartGroupData> bars,
  required double maxY,
  required GetTitleWidgetFunction getTitle,
  required String leftTitle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final gridColor = isDark ? Colors.white12 : Colors.grey.shade200;

  return BarChart(
    BarChartData(
      maxY: maxY < 10 ? 10 : maxY,
      barGroups: bars,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: gridColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitle,
            reservedSize: 24,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} min',
            const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12),
          ),
        ),
      ),
    ),
  );
}