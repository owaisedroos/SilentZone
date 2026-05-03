import '../models/silent_zone.dart';

class ZonesData {
  static const List<SilentZone> defaultZones = [
    // ── HOSPITALS ──────────────────────────────────────────────
    SilentZone(
      lat: 19.0642, lon: 72.8359,
      name: 'Lilavati Hospital', radius: 200, type: ZoneType.hospital,
    ),
    SilentZone(
      lat: 19.1199, lon: 72.8453,
      name: 'Nanavati Hospital', radius: 250, type: ZoneType.hospital,
    ),
    SilentZone(
      lat: 19.0225, lon: 72.8438,
      name: 'Tata Memorial Hospital', radius: 300, type: ZoneType.hospital,
    ),
    SilentZone(
      lat: 19.0760, lon: 72.8777,
      name: 'KEM Hospital', radius: 200, type: ZoneType.hospital,
    ),
    SilentZone(
      lat: 19.1335, lon: 72.9150,
      name: 'Rajawadi Hospital', radius: 200, type: ZoneType.hospital,
    ),

    // ── SCHOOLS / COLLEGES ─────────────────────────────────────
    SilentZone(
      lat: 19.0785, lon: 72.8990,
      name: 'Somaiya University', radius: 400, type: ZoneType.school,
    ),
    SilentZone(
      lat: 19.1039, lon: 72.8383,
      name: 'Mithibai College', radius: 200, type: ZoneType.school,
    ),
    SilentZone(
      lat: 19.0215, lon: 72.8366,
      name: 'IIT Bombay', radius: 600, type: ZoneType.school,
    ),
    SilentZone(
      lat: 18.9548, lon: 72.8153,
      name: 'Mumbai University', radius: 400, type: ZoneType.school,
    ),
    SilentZone(
      lat: 19.0813, lon: 72.8886,
      name: 'Don Bosco Institute of Technology', radius: 200, type: ZoneType.school,
    ),

    // ── RELIGIOUS SITES ────────────────────────────────────────
    SilentZone(
      lat: 19.0213, lon: 72.8561,
      name: 'Siddhivinayak Temple', radius: 200, type: ZoneType.religious,
    ),
    SilentZone(
      lat: 18.9647, lon: 72.8354,
      name: 'Haji Ali Dargah', radius: 250, type: ZoneType.religious,
    ),
    SilentZone(
      lat: 18.9441, lon: 72.8269,
      name: 'Mahalakshmi Temple', radius: 100, type: ZoneType.religious,
    ),
  ];
}