import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Demo-mode disease detection screen.
// Shows the full UI and simulated AI results without requiring
// tflite_flutter or image_picker. Add those packages back once
// you're ready to integrate a real model.

class DiseaseResult {
  final String name;
  final String nameTamil;
  final double confidence;
  final String severity;
  final String advice;
  final String adviceTamil;

  const DiseaseResult({
    required this.name,
    required this.nameTamil,
    required this.confidence,
    required this.severity,
    required this.advice,
    required this.adviceTamil,
  });
}

// Sample demo results that cycle on each "Analyze" tap
const List<DiseaseResult> _demoResults = [
  DiseaseResult(
    name: 'Healthy',
    nameTamil: 'ஆரோக்கியமான',
    confidence: 0.96,
    severity: 'healthy',
    advice: 'Your crop looks healthy! Continue normal irrigation and care.',
    adviceTamil: 'உங்கள் பயிர் ஆரோக்கியமாக உள்ளது! சாதாரண நீர்ப்பாசனம் தொடரவும்.',
  ),
  DiseaseResult(
    name: 'Brown Spot',
    nameTamil: 'பழுப்பு புள்ளி',
    confidence: 0.87,
    severity: 'mild',
    advice: 'Apply Tricyclazole fungicide. Avoid overhead irrigation.',
    adviceTamil: 'Tricyclazole பூஞ்சைக்கொல்லி பயன்படுத்தவும். மேல்நோக்கி நீர்ப்பாசனம் தவிர்க்கவும்.',
  ),
  DiseaseResult(
    name: 'Bacterial Blight',
    nameTamil: 'பாக்டீரியா தாக்குதல்',
    confidence: 0.91,
    severity: 'severe',
    advice: 'Apply copper-based bactericide. Remove infected leaves immediately.',
    adviceTamil: 'காப்பர் கலந்த பூஞ்சைக்கொல்லி தெளிக்கவும். பாதிக்கப்பட்ட இலைகளை அகற்றவும்.',
  ),
  DiseaseResult(
    name: 'Leaf Blast',
    nameTamil: 'இலை கருகல்',
    confidence: 0.83,
    severity: 'severe',
    advice: 'Apply Carbendazim fungicide. Ensure proper spacing between plants.',
    adviceTamil: 'Carbendazim பூஞ்சைக்கொல்லி தெளிக்கவும். செடிகளுக்கிடையே இடைவெளி அதிகரிக்கவும்.',
  ),
];

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  bool _isAnalyzing  = false;
  bool _imagePicked  = false;
  DiseaseResult? _result;
  int _demoIndex     = 0;

  Future<void> _simulateAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _imagePicked = true;
      _result      = null;
    });

    // Simulate model inference delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _result      = _demoResults[_demoIndex % _demoResults.length];
      _demoIndex++;
      _isAnalyzing = false;
    });
  }

  void _reset() => setState(() {
    _imagePicked = false;
    _result      = null;
    _isAnalyzing = false;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'நோய் கண்டறிதல் · AI Powered',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── How-to card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecoration(context),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.tips_and_updates, color: AppTheme.warmAmber, size: 18),
                  SizedBox(width: 8),
                  Text('How to use', style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                SizedBox(height: 8),
                Text(
                  '1. Tap "Take Photo" or "Choose from Gallery"\n'
                  '2. Point camera at a single leaf clearly\n'
                  '3. AI will identify diseases and give treatment advice\n'
                  '4. Follow the recommended treatment steps',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
                SizedBox(height: 4),
                Text(
                  'இலையின் தெளிவான படம் எடுக்கவும். AI நோயை கண்டறியும்.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Image area ────────────────────────────────────────
          _ImageArea(
            imagePicked: _imagePicked,
            isAnalyzing: _isAnalyzing,
            onPickImage: _simulateAnalysis,
            onReset: _reset,
          ),
          const SizedBox(height: 14),

          // ── Result ────────────────────────────────────────────
          if (_isAnalyzing)
            _AnalyzingCard()
          else if (_result != null)
            _ResultCard(result: _result!),

          // ── Demo notice ───────────────────────────────────────
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightAmber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.warmAmber, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo mode — results are simulated. '
                    'Add tflite_flutter + a plant disease model for real detection.',
                    style: TextStyle(fontSize: 11, color: AppTheme.warmAmber),
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

// ── Image picker area ──────────────────────────────────────────

class _ImageArea extends StatelessWidget {
  final bool imagePicked;
  final bool isAnalyzing;
  final VoidCallback onPickImage;
  final VoidCallback onReset;

  const _ImageArea({
    required this.imagePicked,
    required this.isAnalyzing,
    required this.onPickImage,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (!imagePicked) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.lightGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: AppTheme.primaryGreen, size: 40),
            const SizedBox(height: 10),
            const Text('Take or upload a leaf photo',
                style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.w500)),
            const Text('இலை படம் எடுக்கவும்',
                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickBtn(icon: Icons.camera_alt,    label: 'Camera',  onTap: onPickImage),
                const SizedBox(width: 12),
                _PickBtn(icon: Icons.photo_library, label: 'Gallery', onTap: onPickImage),
              ],
            ),
          ],
        ),
      );
    }

    // Image picked — show placeholder with analyzing overlay
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Leaf image loaded',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        if (isAnalyzing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        // Retake button
        if (!isAnalyzing)
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}

class _PickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Analyzing card ─────────────────────────────────────────────

class _AnalyzingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: const Column(children: [
        CircularProgressIndicator(color: AppTheme.primaryGreen),
        SizedBox(height: 12),
        Text('Analyzing leaf...', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text('இலையை பகுப்பாய்வு செய்கிறோம்...',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }
}

// ── Result card ────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final DiseaseResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isHealthy = result.severity == 'healthy';
    final isSevere  = result.severity == 'severe';

    final bgColor   = isHealthy ? AppTheme.lightGreen
                    : isSevere  ? AppTheme.lightRed
                    :             AppTheme.lightAmber;
    final fgColor   = isHealthy ? AppTheme.primaryGreen
                    : isSevere  ? AppTheme.softRed
                    :             AppTheme.warmAmber;
    final icon      = isHealthy ? Icons.check_circle
                    : isSevere  ? Icons.warning
                    :             Icons.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header row
        Row(children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fgColor)),
            Text(result.nameTamil,
                style: TextStyle(fontSize: 13, color: fgColor.withOpacity(0.8))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${(result.confidence * 100).toInt()}% sure',
              style: const TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ]),

        const Divider(height: 20),

        // Advice row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.medical_services_outlined, size: 16, color: fgColor),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.advice,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(result.adviceTamil,
                style: TextStyle(fontSize: 12, color: fgColor.withOpacity(0.75))),
          ])),
        ]),
      ]),
    );
  }
}