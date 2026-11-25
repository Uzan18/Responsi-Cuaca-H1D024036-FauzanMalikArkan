import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status tampilan untuk menangani kondisi loading, data tersedia, kosong, dan error.
enum ViewState { initial, loading, loaded, empty, error }

/// ViewModel utama untuk Home / Weather Screen dan manajemen lokasi favorit.
class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  WeatherViewModel({
    required this._apiService,
    required this._storageService,
  });

  ViewState _state = ViewState.initial;
  LocationModel _selectedLocation = LocationModel.defaultLocation();
  WeatherData? _weatherData;
  List<LocationModel> _favorites = const [];
  String? _errorMessage;
  bool _isInitialized = false;

  ViewState get state => _state;
  LocationModel get selectedLocation => _selectedLocation;
  WeatherData? get weatherData => _weatherData;
  List<LocationModel> get favorites => List.unmodifiable(_favorites);
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  bool isFavorite(LocationModel location) {
    return _favorites.any((item) => item == location);
  }

  bool get isCurrentLocationFavorite => isFavorite(_selectedLocation);

  /// Memuat lokasi tersimpan dan daftar favorit dari Local Storage,
  /// lalu mengambil data cuaca terkini dari Open-Meteo API.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _favorites = await _storageService.getFavorites();
    final savedLocation = await _storageService.getSelectedLocation();

    if (savedLocation != null) {
      _selectedLocation = savedLocation;
    } else if (_favorites.isNotEmpty) {
      _selectedLocation = _favorites.first;
    } else {
      _selectedLocation = LocationModel.defaultLocation();
    }

    await fetchWeatherForSelectedLocation();
  }

  /// Memilih lokasi baru, menyimpannya secara lokal, lalu memuat data cuaca.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    await _storageService.saveSelectedLocation(location);
    await fetchWeatherForSelectedLocation();
  }

  /// Mengambil data cuaca terbaru dari Open-Meteo untuk [_selectedLocation].
  Future<void> fetchWeatherForSelectedLocation() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      if (data.dailyForecasts.isEmpty && data.current.time.isEmpty) {
        _weatherData = null;
        _state = ViewState.empty;
      } else {
        _weatherData = data;
        _state = ViewState.loaded;
      }
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan yang tidak terduga: $e';
      _state = ViewState.error;
    }

    notifyListeners();
  }

  Future<void> toggleFavorite(LocationModel location) async {
    _favorites = await _storageService.toggleFavorite(location);
    notifyListeners();
  }

  Future<void> toggleCurrentLocationFavorite() async {
    await toggleFavorite(_selectedLocation);
  }

  Future<void> removeFavorite(LocationModel location) async {
    _favorites = await _storageService.removeFavorite(location);
    notifyListeners();
  }
}
