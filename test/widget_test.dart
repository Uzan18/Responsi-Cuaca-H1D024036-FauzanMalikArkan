import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsi_flutter_cuaca/main.dart';
import 'package:responsi_flutter_cuaca/models/location_model.dart';
import 'package:responsi_flutter_cuaca/models/weather_model.dart';
import 'package:responsi_flutter_cuaca/services/local_storage_service.dart';
import 'package:responsi_flutter_cuaca/services/weather_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sampleForecastJson = {
  'latitude': -7.42,
  'longitude': 109.23,
  'timezone': 'Asia/Jakarta',
  'timezone_abbreviation': 'GMT+7',
  'current': {
    'time': '2026-11-25T18:15',
    'temperature_2m': 24.8,
    'relative_humidity_2m': 96,
    'apparent_temperature': 30.4,
    'precipitation': 0.2,
    'weather_code': 53,
    'wind_speed_10m': 3.7,
  },
  'daily': {
    'time': ['2026-11-25', '2026-11-26', '2026-11-27'],
    'weather_code': [81, 80, 1],
    'temperature_2m_max': [29.0, 28.1, 30.6],
    'temperature_2m_min': [24.4, 23.3, 23.1],
    'precipitation_probability_max': [100, 85, 20],
  },
};

const _sampleGeocodingJson = {
  'results': [
    {
      'id': 1642911,
      'name': 'Jakarta',
      'latitude': -6.21462,
      'longitude': 106.84513,
      'country': 'Indonesia',
      'admin1': 'Jakarta',
      'timezone': 'Asia/Jakarta',
    },
    {
      'id': 1650357,
      'name': 'Bandung',
      'latitude': -6.92222,
      'longitude': 107.60694,
      'country': 'Indonesia',
      'admin1': 'Jawa Barat',
      'timezone': 'Asia/Jakarta',
    },
  ],
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model & API Service', () {
    test('WeatherData.fromJson memetakan seluruh field Open-Meteo dengan benar', () {
      final data = WeatherData.fromJson(_sampleForecastJson);

      expect(data.timezone, 'Asia/Jakarta');
      expect(data.current.temperature2m, 24.8);
      expect(data.current.relativeHumidity2m, 96);
      expect(data.current.apparentTemperature, 30.4);
      expect(data.current.precipitation, 0.2);
      expect(data.current.weatherCode, 53);
      expect(data.current.windSpeed10m, 3.7);
      expect(data.dailyForecasts.length, 3);
      expect(data.dailyForecasts.first.temperature2mMax, 29.0);
      expect(data.dailyForecasts.first.temperature2mMin, 24.4);
      expect(data.dailyForecasts.first.precipitationProbabilityMax, 100);
    });

    test('WeatherApiService mengirim HTTP GET dengan parameter sesuai modul', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        expect(request.method, 'GET');
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(jsonEncode(_sampleForecastJson), 200);
        }
        return http.Response(jsonEncode(_sampleGeocodingJson), 200);
      });

      final service = WeatherApiService(client: client);
      final weather = await service.fetchWeather(
        latitude: -7.42139,
        longitude: 109.23444,
      );

      expect(capturedUri?.host, 'api.open-meteo.com');
      expect(capturedUri?.queryParameters['timezone'], 'auto');
      expect(capturedUri?.queryParameters['current'], contains('temperature_2m'));
      expect(
        capturedUri?.queryParameters['daily'],
        contains('precipitation_probability_max'),
      );
      expect(weather.current.temperature2m, 24.8);

      final cities = await service.searchLocations('Jakarta');
      expect(cities.length, 2);
      expect(cities.first.name, 'Jakarta');
    });

    test('WeatherApiService mengembalikan list kosong saat hasil geocoding tidak ada', () async {
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'generationtime_ms': 0.2}), 200);
      });

      final service = WeatherApiService(client: client);
      final results = await service.searchLocations('KotaFiktifXYZ');
      expect(results, isEmpty);
    });

    test('WeatherApiService melempar WeatherApiException saat HTTP status bukan 200', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
      final service = WeatherApiService(client: client);

      expect(
        () => service.fetchWeather(latitude: 0, longitude: 0),
        throwsA(isA<WeatherApiException>()),
      );
    });
  });

  group('LocalStorageService', () {
    test('Menyimpan dan memuat ulang lokasi favorit serta riwayat pencarian', () async {
      final storage = LocalStorageService();
      const jakarta = LocationModel(
        id: 1642911,
        name: 'Jakarta',
        latitude: -6.21462,
        longitude: 106.84513,
        country: 'Indonesia',
      );

      await storage.toggleFavorite(jakarta);
      await storage.addToSearchHistory(jakarta);
      await storage.saveSelectedLocation(jakarta);

      final favorites = await storage.getFavorites();
      final history = await storage.getSearchHistory();
      final selected = await storage.getSelectedLocation();

      expect(favorites, [jakarta]);
      expect(history, [jakarta]);
      expect(selected, jakarta);
    });
  });

  group('Widget & MVVM Integration', () {
    testWidgets('HomeWeatherScreen menampilkan data cuaca dari API dan bisa berpindah ke Search',
        (tester) async {
      final client = MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(jsonEncode(_sampleForecastJson), 200);
        }
        return http.Response(jsonEncode(_sampleGeocodingJson), 200);
      });

      await tester.pumpWidget(
        CuacaApp(
          apiService: WeatherApiService(client: client),
          storageService: LocalStorageService(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Purwokerto'), findsWidgets);
      expect(find.text('24.8°C'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
      expect(find.text('3.7 km/j'), findsOneWidget);
      expect(find.text('0.2 mm'), findsOneWidget);
      expect(find.text('100%'), findsWidgets);
      expect(find.text('Prakiraan 3 Hari Ke Depan'), findsOneWidget);

      await tester.tap(find.byTooltip('Cari Kota & Favorit'));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Lokasi'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Jakarta');
      await tester.pump();
      await tester.tap(find.byTooltip('Cari sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Jakarta'), findsWidgets);
      expect(find.text('Bandung'), findsOneWidget);
    });

    testWidgets('HomeWeatherScreen menampilkan pesan error dan tombol Coba Lagi saat API gagal',
        (tester) async {
      var fail = true;
      final client = MockClient((_) async {
        if (fail) {
          return http.Response('Server Down', 503);
        }
        return http.Response(jsonEncode(_sampleForecastJson), 200);
      });

      await tester.pumpWidget(
        CuacaApp(
          apiService: WeatherApiService(client: client),
          storageService: LocalStorageService(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Gagal Memuat Cuaca'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('24.8°C'), findsOneWidget);
    });
  });
}
