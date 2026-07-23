// Represents one crop the farmer is growing.
// Used by the Crop Advisor screen to generate tips.

class Crop {
  final String name;          // English name e.g. "Rice"
  final String nameTamil;     // Tamil name e.g. "நெல்"
  final double minSoilMoisture; // optimal minimum soil %
  final double heatStressTemp;  // °C above which heat stress occurs
  final double dailyWaterMm;    // recommended daily water in mm

  const Crop({
    required this.name,
    required this.nameTamil,
    required this.minSoilMoisture,
    required this.heatStressTemp,
    required this.dailyWaterMm,
  });

  // All supported crops — extend this list to add more
  static List<Crop> get all => [
    const Crop(name: 'Rice',   nameTamil: 'நெல்',      minSoilMoisture: 70, heatStressTemp: 38, dailyWaterMm: 20),
    const Crop(name: 'Tomato', nameTamil: 'தக்காளி',   minSoilMoisture: 50, heatStressTemp: 33, dailyWaterMm: 12),
    const Crop(name: 'Onion',  nameTamil: 'வெங்காயம்', minSoilMoisture: 45, heatStressTemp: 35, dailyWaterMm: 8),
    const Crop(name: 'Chilli', nameTamil: 'மிளகாய்',   minSoilMoisture: 55, heatStressTemp: 36, dailyWaterMm: 10),
    const Crop(name: 'Banana', nameTamil: 'வாழை',      minSoilMoisture: 65, heatStressTemp: 40, dailyWaterMm: 25),
    const Crop(name: 'Cotton', nameTamil: 'பருத்தி',   minSoilMoisture: 40, heatStressTemp: 42, dailyWaterMm: 7),
  ];

  // Look up a crop by its English name
  static Crop? findByName(String name) {
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}