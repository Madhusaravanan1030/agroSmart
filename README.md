# 🌱 AgroSmart — Smart Irrigation Companion

A Flutter app for smart farm irrigation management built for small-scale farmers.

## Features
- 📊 Real-time sensor dashboard (temperature, humidity, soil moisture)
- 💧 Motor control — auto and manual irrigation modes
- 📋 Irrigation log with SQLite local storage
- 🌦️ 7-day weather forecast with auto irrigation scheduling
- 🌿 AI crop advisor with bilingual tips (English + Tamil)
- 📈 Water usage charts (daily, weekly, monthly)
- 🔔 Push notifications for rain alerts and soil moisture
- 🤖 AI disease detection (demo mode)
- 🌙 Dark mode support
- 🗣️ Bilingual UI — English + Tamil

## Tech Stack
- Flutter 3.44 + Dart 3.9
- Provider (state management)
- SQLite / sqflite (local database)
- OpenWeatherMap API (weather)
- fl_chart (charts)
- flutter_local_notifications

## Hardware (Physical Project)
- Arduino / ESP microcontroller
- DHT11 Temperature & Humidity sensor
- Soil moisture sensor
- Water pump motor with relay

> Note: This app runs in demo mode with simulated sensor data.
> Connect to real Arduino/ESP hardware to get live readings.

## Setup
1. Clone the repo
2. Copy `lib/core/constants/app_constants.example.dart` → `app_constants.dart`
3. Add your [OpenWeatherMap API key](https://openweathermap.org/api)
4. Run `flutter pub get`
5. Run `flutter run`

