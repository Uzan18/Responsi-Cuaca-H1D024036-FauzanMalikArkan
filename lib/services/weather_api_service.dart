import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/weather_model.dart';

/// Exception khusus untuk kegagalan permintaan ke REST API Open-Meteo.
class WeatherApiException implements Exception {
  final String message;

  const WeatherApiException(this.message);

  @override
  String toString() => message;
}

/// Service networking untuk mengambil data cuaca dan pencarian kota dari Open-Meteo
/// menggunakan metode HTTP GET.
class WeatherApiService {
  static const String _forecastHost = 'api.open-meteo.com';
  static const String _geocodingHost = 'geocoding-api.open-meteo.com';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil data cuaca terkini (`current`) dan prakiraan harian (`daily`)
  /// berdasarkan koordinat [latitude] dan [longitude].
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
    });

    final jsonMap = await _getJson(uri);
    return WeatherData.fromJson(jsonMap);
  }

  /// Mencari lokasi berdasarkan nama kota menggunakan Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': trimmed,
      'count': '10',
      'language': 'id',
      'format': 'json',
    });

    final jsonMap = await _getJson(uri);
    final results = jsonMap['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromGeocodingJson)
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw WeatherApiException(
          'Server mengembalikan status ${response.statusCode}.',
        );
      }
      if (response.body.trim().isEmpty) {
        throw const WeatherApiException('Respons dari server kosong.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherApiException('Format JSON tidak sesuai.');
      }
      if (decoded['error'] == true) {
        final reason = decoded['reason']?.toString() ?? 'Permintaan ditolak API.';
        throw WeatherApiException(reason);
      }
      return decoded;
    } on TimeoutException {
      throw const WeatherApiException(
        'Waktu permintaan habis. Periksa koneksi internet Anda.',
      );
    } on SocketException {
      throw const WeatherApiException(
        'Tidak ada koneksi internet. Pastikan perangkat terhubung ke jaringan.',
      );
    } on http.ClientException catch (e) {
      throw WeatherApiException('Gagal menghubungi server: ${e.message}');
    } on FormatException catch (e) {
      throw WeatherApiException('Gagal mengolah data JSON: ${e.message}');
    }
  }

  void dispose() {
    _client.close();
  }
}
