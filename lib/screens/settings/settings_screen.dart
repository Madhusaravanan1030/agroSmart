import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/weather_provider.dart';
import '../../providers/theme_provider.dart';   // ✅ fixed: import added
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _farmNameController = TextEditingController();
  final _cityController     = TextEditingController();
  bool _isTamil             = false;
  bool _notificationsEnabled = true;
  bool _isLoading           = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _farmNameController.text      = prefs.getString('farmName') ?? 'My Farm';
      _cityController.text          = prefs.getString('city') ?? 'Chennai';
      _isTamil                      = prefs.getBool('isTamil') ?? false;
      _notificationsEnabled         = prefs.getBool('notifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmName', _farmNameController.text.trim());
    await prefs.setString('city', _cityController.text.trim());
    await prefs.setBool('isTamil', _isTamil);
    await prefs.setBool('notifications', _notificationsEnabled);

    if (mounted) {
      await context.read<WeatherProvider>()
          .fetchWeather(city: _cityController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings saved / அமைப்புகள் சேமிக்கப்பட்டன'),
        backgroundColor: AppTheme.primaryGreen,
      ));
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: const Align(alignment: Alignment.centerLeft,
                child: Text('அமைப்புகள்',
                    style: TextStyle(color: Colors.white70, fontSize: 12))),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Farm details ──────────────────────────────────
                _SectionHeader(title: 'Farm details', titleTa: 'பண்ணை விவரங்கள்'),
                const SizedBox(height: 10),
                _SettingCard(child: Column(children: [
                  _FieldRow(label: 'Farm name', labelTa: 'பண்ணை பெயர்',
                      icon: Icons.agriculture, controller: _farmNameController),
                  const Divider(height: 1),
                  _FieldRow(label: 'City / Location', labelTa: 'நகரம்',
                      icon: Icons.location_city, controller: _cityController,
                      hint: 'e.g. Chennai, Coimbatore'),
                ])),
                const SizedBox(height: 20),

                // ── Preferences ───────────────────────────────────
                _SectionHeader(title: 'Preferences', titleTa: 'விருப்பத்தேர்வுகள்'),
                const SizedBox(height: 10),
                _SettingCard(child: Column(children: [
                  _SwitchRow(
                    icon: Icons.language,
                    label: 'Tamil language', labelTa: 'தமிழ் மொழி',
                    value: _isTamil,
                    onChanged: (val) => setState(() => _isTamil = val),
                  ),
                  const Divider(height: 1),
                  // ✅ fixed: ThemeProvider now properly imported and typed
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) => _SwitchRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark mode', labelTa: 'இரவு பயன்முறை',
                      value: theme.isDark,
                      onChanged: (val) =>
                          context.read<ThemeProvider>().toggleTheme(val),
                    ),
                  ),
                  const Divider(height: 1),
                  _SwitchRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications', labelTa: 'அறிவிப்புகள்',
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ])),
                const SizedBox(height: 20),

                // ── Device ────────────────────────────────────────
                _SectionHeader(title: 'Device', titleTa: 'சாதனம்'),
                const SizedBox(height: 10),
                _SettingCard(child: Column(children: [
                  _InfoRow(icon: Icons.memory, label: 'Microcontroller',
                      value: 'Arduino / ESP (not connected)'),
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.sensors, label: 'Sensor mode',
                      value: 'Simulated (Demo)'),
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.cloud, label: 'Weather source',
                      value: 'OpenWeatherMap API'),
                ])),
                const SizedBox(height: 20),

                // ── About ─────────────────────────────────────────
                _SectionHeader(title: 'About', titleTa: 'பற்றி'),
                const SizedBox(height: 10),
                _SettingCard(child: Column(children: [
                  _InfoRow(icon: Icons.info_outline, label: 'App version', value: '1.0.0'),
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.code, label: 'Built with', value: 'Flutter + Provider'),
                ])),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save settings / அமைப்புகளை சேமி',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, titleTa;
  const _SectionHeader({required this.title, required this.titleTa});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: AppTheme.primaryGreen)),
      const SizedBox(width: 6),
      Text('/ $titleTa', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(context), // ✅ fixed
      child: child,
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label, labelTa;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  const _FieldRow({required this.label, required this.labelTa,
      required this.icon, required this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label / $labelTa',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true, contentPadding: EdgeInsets.zero,
              border: InputBorder.none, hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ])),
      ]),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label, labelTa;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label, required this.labelTa,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(labelTa, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged,
            activeColor: AppTheme.primaryGreen),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}