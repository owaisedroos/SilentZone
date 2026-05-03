import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/silent_zone.dart';
import '../data/zones_data.dart';

/// Handles persisting user-created custom zones to the device.
class ZonesStorageService {
  static const _key = 'custom_zones_v1';

  /// Returns ALL zones: built-in defaults + user-created custom zones.
  static Future<List<SilentZone>> loadAllZones() async {
    final customZones = await loadCustomZones();
    return [...ZonesData.defaultZones, ...customZones];
  }

  /// Returns only the user-created zones.
  static Future<List<SilentZone>> loadCustomZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => SilentZone.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves a new custom zone.
  static Future<void> addCustomZone(SilentZone zone) async {
    final existing = await loadCustomZones();
    existing.add(zone);
    await _saveCustomZones(existing);
  }

  /// Deletes a custom zone by name.
  static Future<void> deleteCustomZone(String name) async {
    final existing = await loadCustomZones();
    existing.removeWhere((z) => z.name == name);
    await _saveCustomZones(existing);
  }

  static Future<void> _saveCustomZones(List<SilentZone> zones) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(zones.map((z) => z.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}