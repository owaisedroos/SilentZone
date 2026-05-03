enum ZoneType { hospital, school, religious, custom }

class SilentZone {
  final double lat;
  final double lon;
  final String name;
  final int radius; // metres
  final ZoneType type;
  final bool isCustom; // true = user-created, can be deleted

  const SilentZone({
    required this.lat,
    required this.lon,
    required this.name,
    required this.radius,
    required this.type,
    this.isCustom = false,
  });

  String get typeLabel {
    switch (type) {
      case ZoneType.hospital:
        return 'Hospital';
      case ZoneType.school:
        return 'School / College';
      case ZoneType.religious:
        return 'Religious Site';
      case ZoneType.custom:
        return 'Custom Zone';
    }
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'name': name,
        'radius': radius,
        'type': type.name,
        'isCustom': isCustom,
      };

  factory SilentZone.fromJson(Map<String, dynamic> json) => SilentZone(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        name: json['name'] as String,
        radius: json['radius'] as int,
        type: ZoneType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ZoneType.custom,
        ),
        isCustom: json['isCustom'] as bool? ?? false,
      );
}