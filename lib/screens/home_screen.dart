import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/silent_zone.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/zones_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late LocationService _locationService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late TabController _tabController;

  List<SilentZone> _allZones = [];
  List<SilentZone> _customZones = [];

  Position? _currentPosition;
  SilentZone? _currentZone;
  bool _isTracking = false;
  bool _autoSilence = false;
  String _statusText = 'Tap tracking to start';
  bool _showSplash = true;

  String _toastMessage = '';
  bool _showToast = false;
  Color _toastColor = const Color(0xFF374151);
  IconData _toastIcon = Icons.info_outline;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tabController = TabController(length: 2, vsync: this);
    _loadZones();

    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _showSplash = false) : null);

    Future.delayed(
        const Duration(seconds: 3), _requestNotificationPermission);
  }

  // ── Notification permission ─────────────────────────────────
  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.requestPermission();
    if (!granted && mounted) {
      _showInfoDialog(
        icon: Icons.notifications_active,
        iconColor: const Color(0xFF2563EB),
        title: 'Enable Notifications',
        message:
            'SilentZone needs notification permission to alert you when '
            'entering or exiting a silent zone — even when your screen is off.',
        actionLabel: 'Allow',
        onAction: _requestNotificationPermission,
      );
    }
  }

  // ── Location service OFF dialog (matches Android style) ────
  void _showLocationOffDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Turn on Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To continue, your device will need to use Location Services.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _locationRequirement(
              Icons.location_on,
              'Device Location',
              'Required to detect silent zones near you.',
            ),
            const SizedBox(height: 12),
            _locationRequirement(
              Icons.gps_fixed,
              'High Accuracy',
              'Uses GPS, Wi-Fi and mobile networks for precise tracking.',
            ),
            const SizedBox(height: 12),
            const Text(
              'You can change this at any time in Location Settings.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, thanks',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open device location settings
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
  }

  Widget _locationRequirement(
      IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ── DND permission dialog ───────────────────────────────────
  void _showDndPermissionDialog() {
    _showInfoDialog(
      icon: Icons.do_not_disturb_on,
      iconColor: const Color(0xFFF97316),
      title: 'Do Not Disturb Access Required',
      message:
          'To automatically silence your phone, SilentZone needs '
          '"Do Not Disturb" access.\n\nTap "Open Settings", find '
          'SilentZone in the list, and enable it.',
      actionLabel: 'Open Settings',
      onAction: LocationService.openDndSettings,
    );
  }

  void _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String actionLabel = 'Allow',
    required VoidCallback onAction,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(message,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  // ── Load zones ──────────────────────────────────────────────
  Future<void> _loadZones() async {
    final all = await ZonesStorageService.loadAllZones();
    final custom = await ZonesStorageService.loadCustomZones();
    if (mounted) {
      setState(() {
        _allZones = all;
        _customZones = custom;
      });
    }
    _initService();
  }

  void _initService() {
    _locationService = LocationService(
      zones: _allZones,
      onLocationUpdate: (pos) {
        if (mounted) setState(() => _currentPosition = pos);
      },
      onZoneChange: (zone) {
        if (!mounted) return;
        setState(() => _currentZone = zone);
        if (zone != null) {
          _toast(
            '${_autoSilence ? "🔇 Silenced — " : "🤫 "}Entering ${zone.name}',
            _autoSilence
                ? Colors.orange.shade700
                : const Color(0xFF1D4ED8),
            Icons.volume_off,
          );
        } else {
          _toast(
              '🔔 Left silent zone', Colors.green.shade700, Icons.volume_up);
        }
      },
      onStatusChange: (s) {
        if (mounted) setState(() => _statusText = s);
      },
      onDndPermissionMissing: _showDndPermissionDialog,
      // ← Show location off dialog when GPS is disabled
      onLocationServiceOff: () {
        // Also revert the tracking toggle since we didn't actually start
        if (mounted) setState(() => _isTracking = false);
        _showLocationOffDialog();
      },
    );
  }

  void _toast(String msg, Color color, IconData icon) {
    setState(() {
      _toastMessage = msg;
      _toastColor = color;
      _toastIcon = icon;
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 4),
        () => mounted ? setState(() => _showToast = false) : null);
  }

  // ── Toggle tracking ─────────────────────────────────────────
  Future<void> _toggleTracking(bool value) async {
    if (value) {
      // Optimistically set true; service will revert if GPS is off
      setState(() => _isTracking = true);
      await _locationService.startTracking();
      // If service turned it back to false (GPS off), sync the toggle
      if (mounted && !_locationService.isTracking) {
        setState(() => _isTracking = false);
      }
    } else {
      _locationService.stopTracking();
      setState(() => _isTracking = false);
    }
  }

  // ── Toggle auto-silence ─────────────────────────────────────
  Future<void> _toggleAutoSilence(bool val) async {
    if (val) {
      // Check DND permission before enabling
      final hasDnd = await LocationService.hasDndPermission();
      if (!hasDnd) {
        _showDndPermissionDialog();
        return;
      }
    }

    setState(() {
      _autoSilence = val;
      _locationService.autoSilence = val;
    });

    // ✅ If already inside a zone and turning ON, silence immediately
    if (val && _currentZone != null) {
      await _locationService.applyImmediateSilenceIfInZone();
      _toast(
        '🔇 Already in ${_currentZone!.name} — phone silenced now',
        Colors.orange.shade700,
        Icons.volume_off,
      );
    }

    // If turning OFF while in a zone, restore ringer immediately
    if (!val && _currentZone != null) {
      // Temporarily set autoSilence true so the restore call works
      _locationService.autoSilence = false;
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16);
    } else {
      _toast(
          'Enable tracking first', Colors.red.shade700, Icons.location_off);
    }
  }

  void _onMapLongPress(TapPosition _, LatLng latlng) =>
      _showAddZoneDialog(latlng);

  void _showAddZoneDialog(LatLng latlng) {
    final nameCtrl = TextEditingController();
    int radius = 200;
    ZoneType selectedType = ZoneType.custom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Add Silent Zone',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(
                  '${latlng.latitude.toStringAsFixed(5)}, '
                  '${latlng.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Zone Name',
                    hintText: 'e.g. My College, Home Library',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text('Zone Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ZoneType.values.map((type) {
                    final selected = selectedType == type;
                    return ChoiceChip(
                      label: Text(_typeLabel(type)),
                      avatar: Icon(_zoneIcon(type),
                          size: 16,
                          color: selected
                              ? Colors.white
                              : _zoneColor(type)),
                      selected: selected,
                      selectedColor: _zoneColor(type),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) =>
                          setModalState(() => selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Radius',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${radius}m',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB))),
                    ),
                  ],
                ),
                Slider(
                  value: radius.toDouble(),
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${radius}m',
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) =>
                      setModalState(() => radius = v.round()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter a zone name')),
                        );
                        return;
                      }
                      final newZone = SilentZone(
                        lat: latlng.latitude,
                        lon: latlng.longitude,
                        name: name,
                        radius: radius,
                        type: selectedType,
                        isCustom: true,
                      );
                      await ZonesStorageService.addCustomZone(newZone);
                      await _loadZones();
                      if (mounted) {
                        Navigator.pop(context);
                        _toast('✅ "$name" added!',
                            Colors.green.shade700, Icons.check_circle);
                      }
                    },
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Save Silent Zone',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteZone(SilentZone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Zone?'),
        content: Text('Remove "${zone.name}" from your silent zones?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ZonesStorageService.deleteCustomZone(zone.name);
      await _loadZones();
      _toast('🗑️ "${zone.name}" removed', Colors.grey.shade700,
          Icons.delete);
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────
  Color _zoneColor(ZoneType type) {
    switch (type) {
      case ZoneType.hospital:  return const Color(0xFFEF4444);
      case ZoneType.school:    return const Color(0xFF3B82F6);
      case ZoneType.religious: return const Color(0xFF8B5CF6);
      case ZoneType.custom:    return const Color(0xFF10B981);
    }
  }

  IconData _zoneIcon(ZoneType type) {
    switch (type) {
      case ZoneType.hospital:  return Icons.local_hospital;
      case ZoneType.school:    return Icons.school;
      case ZoneType.religious: return Icons.place;
      case ZoneType.custom:    return Icons.location_on;
    }
  }

  String _typeLabel(ZoneType type) {
    switch (type) {
      case ZoneType.hospital:  return 'Hospital';
      case ZoneType.school:    return 'School';
      case ZoneType.religious: return 'Religious';
      case ZoneType.custom:    return 'Custom';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildUI(),
          _buildToast(),
          if (_showSplash) _buildSplash(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(19.0760, 72.8777),
        initialZoom: 13,
        maxZoom: 18,
        minZoom: 8,
        onLongPress: _onMapLongPress,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.silentzone.app',
        ),
        CircleLayer(
          circles: _allZones
              .map((z) => CircleMarker(
                    point: LatLng(z.lat, z.lon),
                    radius: z.radius.toDouble(),
                    useRadiusInMeter: true,
                    color: _zoneColor(z.type)
                        .withValues(alpha: z.isCustom ? 0.18 : 0.12),
                    borderColor: _zoneColor(z.type)
                        .withValues(alpha: z.isCustom ? 1.0 : 0.7),
                    borderStrokeWidth: z.isCustom ? 2.0 : 1.5,
                  ))
              .toList(),
        ),
        MarkerLayer(
          markers: [
            ..._allZones.map(
              (z) => Marker(
                point: LatLng(z.lat, z.lon),
                width: 38,
                height: 38,
                child: _buildZonePin(z),
              ),
            ),
            if (_currentPosition != null) ...[
              Marker(
                point: LatLng(_currentPosition!.latitude,
                    _currentPosition!.longitude),
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              Marker(
                point: LatLng(_currentPosition!.latitude,
                    _currentPosition!.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildZonePin(SilentZone zone) {
    final color = _zoneColor(zone.type);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border:
            Border.all(color: color, width: zone.isCustom ? 2.5 : 1.8),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              spreadRadius: 1),
        ],
      ),
      child: Icon(_zoneIcon(zone.type), color: color, size: 20),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Column(
        children: [
          _buildNavbar(),
          const Spacer(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.volume_off,
                  color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SilentZone',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937))),
                  Text(_statusText,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      size: 12, color: Color(0xFF2563EB)),
                  const SizedBox(width: 3),
                  Text('${_allZones.length} zones',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _centerOnUser,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: const Icon(Icons.my_location,
                    size: 20, color: Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2)),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor: const Color(0xFF2563EB),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              const Tab(text: 'Controls'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Zones'),
                    const SizedBox(width: 4),
                    if (_customZones.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('+${_customZones.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [_buildControlsTab(), _buildZonesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          if (_currentZone != null) _buildZoneAlert(_currentZone!),
          _buildCard(
            color: _isTracking
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFEFF6FF),
            borderColor: _isTracking
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFBFDBFE),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isTracking
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.navigation,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Zone Tracking',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        _isTracking
                            ? 'Active — monitoring location'
                            : 'Inactive — tap to start',
                        style: TextStyle(
                            fontSize: 12,
                            color: _isTracking
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isTracking,
                  onChanged: _toggleTracking,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF22C55E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            icon: Icons.volume_off,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFFFF7ED),
            title: 'Auto-Silence Mode',
            subtitle: 'Silences phone on entry (Android only)',
            value: _autoSilence,
            onChanged: _toggleAutoSilence,
            switchColor: const Color(0xFFF97316),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_active,
                    color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notifications + vibration fire on zone entry/exit regardless of auto-silence.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildZonesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Long-press anywhere on the map to add a custom silent zone.',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _allZones.length,
            itemBuilder: (_, i) => _buildZoneTile(_allZones[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneTile(SilentZone zone) {
    final color = _zoneColor(zone.type);
    final isActive = _currentZone?.name == zone.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_zoneIcon(zone.type), color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(zone.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('HERE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(
          '${zone.typeLabel}  •  ${zone.radius}m radius'
          '${zone.isCustom ? "  •  Custom" : ""}',
          style:
              const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        trailing: zone.isCustom
            ? IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 20),
                onPressed: () => _deleteZone(zone),
              )
            : const Icon(Icons.lock_outline,
                size: 16, color: Color(0xFFD1D5DB)),
        onTap: () {
          _mapController.move(LatLng(zone.lat, zone.lon), 16);
          _tabController.animateTo(0);
        },
      ),
    );
  }

  Widget _buildZoneAlert(SilentZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are in a Silent Zone',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 13)),
                Text('${zone.name}  •  ${zone.typeLabel}',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required Widget child,
      required Color color,
      required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor)),
      child: child,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color switchColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: switchColor,
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ZoneType.values
          .map((t) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_zoneIcon(t), color: _zoneColor(t), size: 13),
                  const SizedBox(width: 3),
                  Text(_typeLabel(t),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildToast() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      top: _showToast ? 100 : -80,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _toastColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(_toastIcon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_toastMessage,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return AnimatedOpacity(
      opacity: _showSplash ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: IgnorePointer(
        ignoring: !_showSplash,
        child: Container(
          color: const Color(0xFF2563EB),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20),
                    ],
                  ),
                  child: const Icon(Icons.volume_off,
                      color: Color(0xFF2563EB), size: 48),
                ),
                const SizedBox(height: 20),
                const Text('SilentZone',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Smart GPS Zone Tracker',
                    style:
                        TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}