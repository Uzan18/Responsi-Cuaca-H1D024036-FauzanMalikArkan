import 'dart:convert';

/// Model data untuk lokasi geografis dari Open-Meteo Geocoding API
/// maupun yang tersimpan di penyimpanan lokal (favorit / riwayat pencarian).
class LocationModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;
  final String? admin2;
  final String? timezone;

  const LocationModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
    this.admin2,
    this.timezone,
  });

  /// Lokasi bawaan saat aplikasi pertama kali dijalankan sebelum pengguna memilih kota.
  factory LocationModel.defaultLocation() {
    return const LocationModel(
      id: 1630328,
      name: 'Purwokerto',
      latitude: -7.42139,
      longitude: 109.23444,
      country: 'Indonesia',
      admin1: 'Jawa Tengah',
      admin2: 'Kabupaten Banyumas',
      timezone: 'Asia/Jakarta',
    );
  }

  /// Parsing dari respons JSON Open-Meteo Geocoding API.
  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int?,
      name: (json['name'] as String?)?.trim() ?? 'Tidak diketahui',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: (json['country'] as String?)?.trim() ?? '',
      admin1: (json['admin1'] as String?)?.trim(),
      admin2: (json['admin2'] as String?)?.trim(),
      timezone: (json['timezone'] as String?)?.trim(),
    );
  }

  /// Parsing dari JSON penyimpanan lokal (SharedPreferences).
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Tidak diketahui',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String? ?? '',
      admin1: json['admin1'] as String?,
      admin2: json['admin2'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': admin1,
      'admin2': admin2,
      'timezone': timezone,
    };
  }

  String toRawJson() => jsonEncode(toJson());

  factory LocationModel.fromRawJson(String raw) =>
      LocationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Kunci unik untuk membandingkan dua lokasi agar favorit dan riwayat tidak duplikat.
  String get uniqueKey {
    if (id != null) return 'id_$id';
    return '${name.toLowerCase()}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
  }

  /// Deskripsi wilayah administratif (contoh: "Jawa Tengah, Indonesia").
  String get subtitle {
    final parts = <String>[
      if (admin2 != null && admin2!.isNotEmpty && admin2 != name) admin2!,
      if (admin1 != null && admin1!.isNotEmpty && admin1 != name) admin1!,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.uniqueKey == uniqueKey;
  }

  @override
  int get hashCode => uniqueKey.hashCode;
}
