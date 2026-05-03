import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/silent_zone.dart';
import 'notification_service.dart';

class LocationService {
  static const _audioChannel = MethodChannel('silent_zone/audio');

  StreamSubscription<Position>? _positionStream;

  bool isTracking = false;
  bool autoSilence = false;

  SilentZone? currentZone;
  List<SilentZone> zones;

  final void Function(Position position) onLocationUpdate;
  final void Function(SilentZone? zone) onZoneChange;
  final void Function(String status) onStatusChange;
  final void Function()? onDndPermissionMissing;

  /// Called when GPS/Location service is completely OFF on the device
  final void Function()? onLocationServiceOff;

  LocationService({
    required this.zones,
    required this.onLocationUpdate,
    required this.onZoneChange,
    required this.onStatusChange,
    this.onDndPermissionMissing,
    this.onLocationServiceOff,
  });

  // ─── Permission & service check ───────────────────────────
  static Future<bool> requestPermissions() async {
    // Check if the device location service (GPS) is even turned on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Returns true if the device location service (GPS toggle) is on
  static Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  // ─── Start tracking ────────────────────────────────────────
  Future<void> startTracking() async {
    // 1. Check if GPS is turned on at the device level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Tell the UI to show the "Turn on Location" dialog
      onLocationServiceOff?.call();
      onStatusChange('Location services are off');
      return;
    }

    // 2. Check/request app permission
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      onStatusChange('Location permission denied');
      return;
    }

    isTracking = true;
    onStatusChange('Acquiring GPS signal...');

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        onLocationUpdate(position);
        onStatusChange('GPS Active (±${position.accuracy.round()}m)');
        _checkZones(position.latitude, position.longitude);
      },
      onError: (_) => onStatusChange('GPS signal lost'),
    );
  }

  // ─── Stop tracking ─────────────────────────────────────────
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    isTracking = false;
    onStatusChange('Tracking paused');
  }

  // ─── Immediately apply silence if already in a zone ────────
  /// Call this when user ENABLES auto-silence while already inside a zone.
  /// Without this, silence only triggers on the next zone entry event.
  Future<void> applyImmediateSilenceIfInZone() async {
    if (currentZone != null && autoSilence) {
      await _setPhoneSilent(true);
    }
  }

  // ─── Zone check ────────────────────────────────────────────
  void _checkZones(double lat, double lon) {
    SilentZone? foundZone;
    for (final zone in zones) {
      if (_distance(lat, lon, zone.lat, zone.lon) < zone.radius) {
        foundZone = zone;
        break;
      }
    }

    if (foundZone != null && currentZone?.name != foundZone.name) {
      currentZone = foundZone;
      NotificationService.showZoneEntry(
        zoneName: foundZone.name,
        autoSilenced: autoSilence,
      );
      if (autoSilence) _setPhoneSilent(true);
      onZoneChange(currentZone);
    } else if (foundZone == null && currentZone != null) {
      final exited = currentZone!;
      currentZone = null;
      NotificationService.showZoneExit(
        zoneName: exited.name,
        autoSilenced: autoSilence,
      );
      if (autoSilence) _setPhoneSilent(false);
      onZoneChange(null);
    }
  }

  // ─── Silence phone via platform channel ───────────────────
  Future<void> _setPhoneSilent(bool silent) async {
    try {
      await _audioChannel.invokeMethod('setSilentMode', {'silent': silent});
    } on PlatformException catch (e) {
      if (e.code == 'NO_DND_PERMISSION') {
        onDndPermissionMissing?.call();
      }
    } catch (_) {}
  }

  // ─── DND helpers ──────────────────────────────────────────
  static Future<bool> hasDndPermission() async {
    try {
      return await _audioChannel.invokeMethod<bool>('hasDndPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openDndSettings() async {
    try {
      await _audioChannel.invokeMethod('openDndSettings');
    } catch (_) {}
  }

  // ─── Haversine distance ────────────────────────────────────
  static double _distance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3;
    final p1 = lat1 * pi / 180;
    final p2 = lat2 * pi / 180;
    final dp = (lat2 - lat1) * pi / 180;
    final dl = (lon2 - lon1) * pi / 180;
    final a = sin(dp / 2) * sin(dp / 2) +
        cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void dispose() => _positionStream?.cancel();
}