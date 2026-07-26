import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/crop_provider.dart';
import '../../data/services/chat_service.dart';
import '../../core/theme/app_theme.dart';

// Quick reply suggestions shown at the top — farmer taps one to send instantly
// Two sets: English and Tamil
const List<String> _quickRepliesEn = [
  'Should I irrigate today?',
  'How is my soil moisture?',
  'Is my rice crop healthy?',
  'When will it rain?',
  'My tomato leaves are yellow',
  'Best time to water today?',
];

const List<String> _quickRepliesTa = [
  'இன்று நீர்ப்பாசனம் வேண்டுமா?',
  'என் மண் ஈரம் எப்படி உள்ளது?',
  'என் நெல் பயிர் நலமாக உள்ளதா?',
  'மழை எப்போது வரும்?',
  'என் தக்காளி இலைகள் மஞ்சளாக உள்ளன',
  'இன்று நீர்ப்பாசனத்திற்கு சிறந்த நேரம் எது?',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller    = TextEditingController();
  final _scrollController = ScrollController();
  bool _showQuickReplies = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().loadSettings());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() => _showQuickReplies = false);

    final sensor    = context.read<SensorProvider>().current;
    final cropNames = context.read<CropProvider>().selectedCropNames;

    await context.read<ChatProvider>().sendMessage(
      text: text,
      sensor: sensor,
      cropNames: cropNames,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat   = context.watch<ChatProvider>();
    final isTamil = chat.isTamil;
    final isEmpty = chat.messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Assistant'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI பண்ணை உதவியாளர் · Powered by Claude',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: () {
                context.read<ChatProvider>().clearChat();
                setState(() => _showQuickReplies = true);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Sensor context strip ───────────────────────────────
          _SensorStrip(),

          // ── Chat messages ──────────────────────────────────────
          Expanded(
            child: isEmpty
                ? _EmptyState(isTamil: isTamil)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: chat.messages.length +
                        (chat.isLoading ? 1 : 0) +
                        (chat.errorMessage != null ? 1 : 0),
                    itemBuilder: (context, i) {
                      // Error message
                      if (chat.errorMessage != null &&
                          i == chat.messages.length) {
                        return _ErrorBubble(message: chat.errorMessage!);
                      }
                      // Typing indicator
                      if (chat.isLoading && i == chat.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: chat.messages[i]);
                    },
                  ),
          ),

          // ── Quick replies ──────────────────────────────────────
          if (_showQuickReplies && isEmpty)
            _QuickReplies(
              replies: isTamil ? _quickRepliesTa : _quickRepliesEn,
              onTap: _send,
            ),

          // ── Input bar ──────────────────────────────────────────
          _InputBar(
            controller: _controller,
            isLoading: chat.isLoading,
            isTamil: isTamil,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Sensor context strip ───────────────────────────────────────
// Shows live sensor values so farmer knows what Claude is seeing

class _SensorStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>().current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.darkCard : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sensors, size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          const Text('Live context: ',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          _Strip(label: '🌡', value: '${sensor.temperature.toStringAsFixed(0)}°C'),
          _Strip(label: '💧', value: '${sensor.humidity.toStringAsFixed(0)}%'),
          _Strip(
            label: '🌱',
            value: '${sensor.soilMoisture.toStringAsFixed(0)}%',
            highlight: sensor.soilMoisture < 40,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Simulated',
                style: TextStyle(fontSize: 9, color: AppTheme.darkGreen)),
          ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Strip({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: highlight ? AppTheme.softRed : AppTheme.primaryGreen,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isTamil;
  const _EmptyState({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture,
                  color: AppTheme.primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              isTamil ? 'வணக்கம்! நான் உங்கள் AI பண்ணை உதவியாளர்'
                      : 'Hello! I\'m your AI farm assistant',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'நீர்ப்பாசனம், பயிர் பராமரிப்பு, வானிலை பற்றி கேளுங்கள்'
                  : 'Ask me about irrigation, crop care, weather, or soil conditions',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'உங்கள் தோட்டத்தின் நிகழ்நேர தரவு என்னிடம் உள்ளது'
                  : 'I have your farm\'s live sensor data to give accurate advice',
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick replies ──────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              replies[i],
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser  = message.role == 'user';
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture,
                  color: Colors.white, size: 18),
            ),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryGreen
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCard
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppTheme.borderGray, width: 0.5),
                    boxShadow: isUser
                        ? null
                        : [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          // User avatar
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: AppTheme.primaryGreen, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing indicator ───────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen, shape: BoxShape.circle),
            child: const Icon(Icons.agriculture, color: Colors.white, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.borderGray, width: 0.5),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Row(
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(
                        (i == 0 ? _anim.value : i == 1
                            ? 1 - _anim.value * 0.5 : 0.4)),
                    shape: BoxShape.circle,
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error bubble ───────────────────────────────────────────────

class _ErrorBubble extends StatelessWidget {
  final String message;
  const _ErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.softRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: AppTheme.softRed)),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isTamil;
  final ValueChanged<String> onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.isTamil,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderGray, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderGray, width: 0.5),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isTamil
                        ? 'கேள்வி கேளுங்கள்...'
                        : 'Ask about your farm...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: isLoading ? null : onSend,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isLoading ? null : () => onSend(controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isLoading
                      ? Colors.grey.shade300
                      : AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLoading ? Icons.hourglass_top : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}