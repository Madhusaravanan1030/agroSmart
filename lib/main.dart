import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sensor_provider.dart';
import 'providers/irrigation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/log/log_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/advisor/advisor_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  runApp(const AgroSmartApp());
}

class AgroSmartApp extends StatelessWidget {
  const AgroSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AgroSmart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LogScreen(),
    WeatherScreen(),
    AdvisorScreen(),
    ChatScreen(),      // ← new AI chat tab
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SensorProvider>().startSimulation();
      context.read<IrrigationProvider>().loadLogs();
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.cloud_outlined),
              activeIcon: Icon(Icons.cloud),
              label: 'Weather'),
          BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined),
              activeIcon: Icon(Icons.eco),
              label: 'Crops'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}