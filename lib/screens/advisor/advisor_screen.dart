import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crop_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/weather_provider.dart';
import '../../data/models/crop.dart';
import '../../core/theme/app_theme.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<CropProvider>().loadSavedCrops();
      _refreshTips();
    });
  }

  void _refreshTips() {
    final sensor = context.read<SensorProvider>().current;
    final weather = context.read<WeatherProvider>();
    final rainProb = weather.forecast.isNotEmpty
        ? weather.forecast.first.rainProbability : null;
    context.read<CropProvider>().generateTips(sensor, rainProbability: rainProb);
  }

  @override
  Widget build(BuildContext context) {
    final crops = context.watch<CropProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Advisor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Align(alignment: Alignment.centerLeft,
                child: Text('பயிர் ஆலோசனை',
                    style: TextStyle(color: Colors.white70, fontSize: 12))),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshTips),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MyCropsCard(onCropsChanged: _refreshTips),
          const SizedBox(height: 14),
          if (crops.selectedCropNames.isEmpty)
            _EmptyCropsState()
          else if (crops.tips.isEmpty)
            _LoadingTips()
          else ...[
            Row(children: [
              const Text("Today's tips",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(width: 6),
              const Text('இன்றைய ஆலோசனை',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Text('${crops.tips.length} tip(s)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            const SizedBox(height: 10),
            ...crops.tips.map((tip) => _TipCard(tip: tip)),
          ],
        ],
      ),
    );
  }
}

class _MyCropsCard extends StatelessWidget {
  final VoidCallback onCropsChanged;
  const _MyCropsCard({required this.onCropsChanged});

  @override
  Widget build(BuildContext context) {
    final cropProvider = context.watch<CropProvider>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context), // ✅ fixed
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.eco, color: AppTheme.primaryGreen, size: 18),
          SizedBox(width: 8),
          Text('My crops', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          SizedBox(width: 4),
          Text('/ என் பயிர்கள்', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ...cropProvider.selectedCrops.map((crop) => _CropChip(
              crop: crop, selected: true,
              onTap: () async {
                await context.read<CropProvider>().removeCrop(crop.name);
                onCropsChanged();
              },
            )),
            GestureDetector(
              onTap: () => _showCropPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGreen, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: AppTheme.primaryGreen),
                  SizedBox(width: 4),
                  Text('Add crop / பயிர் சேர்',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
                ]),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  void _showCropPicker(BuildContext context) {
    final selected = context.read<CropProvider>().selectedCropNames;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select crops / பயிர் தேர்வு',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: Crop.all.map((crop) => _CropChip(
              crop: crop,
              selected: selected.contains(crop.name),
              onTap: () async {
                if (selected.contains(crop.name)) {
                  await context.read<CropProvider>().removeCrop(crop.name);
                } else {
                  await context.read<CropProvider>().addCrop(crop.name);
                }
                // ignore: use_build_context_synchronously
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  context.read<CropProvider>(); // triggers rebuild
                }
              },
            )).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final Crop crop;
  final bool selected;
  final VoidCallback onTap;
  const _CropChip({required this.crop, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.lightGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
              width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${crop.name} / ${crop.nameTamil}',
              style: TextStyle(fontSize: 12,
                  color: selected ? AppTheme.darkGreen : Colors.grey.shade700,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400)),
          if (selected) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, size: 13, color: AppTheme.primaryGreen),
          ],
        ]),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final CropTip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final (bgColor, dotColor, icon) = switch (tip.severity) {
      'urgent'  => (AppTheme.lightRed,   AppTheme.softRed,      Icons.warning_amber),
      'warning' => (AppTheme.lightAmber, AppTheme.warmAmber,    Icons.thermostat),
      _         => (AppTheme.lightGreen, AppTheme.primaryGreen, Icons.info_outline),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: dotColor, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: dotColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text('${tip.cropName} / ${tip.cropNameTamil}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: dotColor)),
          ),
          const SizedBox(height: 6),
          Text(tip.messageEn,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(tip.messageTa,
              style: TextStyle(fontSize: 12, color: dotColor.withOpacity(0.8))),
        ])),
      ]),
    );
  }
}

class _EmptyCropsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(padding: EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.eco, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Add a crop to get advice',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text('ஆலோசனை பெற பயிர் சேர்க்கவும்',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _LoadingTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
    );
  }
}