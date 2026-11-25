import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';
import 'weather_viewmodel.dart';

/// ViewModel untuk Search / Location Screen yang menangani pencarian kota via
/// Open-Meteo Geocoding API serta riwayat pencarian tersimpan lokal.
class SearchLocationViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  SearchLocationViewModel({
    required this._apiService,
    required this._storageService,
  });

  ViewState _state = ViewState.initial;
  String _query = '';
  List<LocationModel> _searchResults = const [];
  List<LocationModel> _searchHistory = const [];
  String? _errorMessage;

  ViewState get state => _state;
  String get query => _query;
  List<LocationModel> get searchResults => List.unmodifiable(_searchResults);
  List<LocationModel> get searchHistory => List.unmodifiable(_searchHistory);
  String? get errorMessage => _errorMessage;

  /// Memuat riwayat pencarian dari Local Storage saat halaman dibuka.
  Future<void> loadHistory() async {
    _searchHistory = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Melakukan pencarian lokasi kota ke Open-Meteo Geocoding API.
  Future<void> searchCities(String rawQuery) async {
    final trimmed = rawQuery.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      _searchResults = const [];
      _errorMessage = null;
      _state = ViewState.initial;
      notifyListeners();
      return;
    }

    if (trimmed.length < 2) {
      _searchResults = const [];
      _errorMessage = 'Masukkan minimal 2 karakter nama kota.';
      _state = ViewState.empty;
      notifyListeners();
      return;
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.searchLocations(trimmed);
      if (results.isEmpty) {
        _searchResults = const [];
        _state = ViewState.empty;
      } else {
        _searchResults = results;
        _state = ViewState.loaded;
      }
    } on WeatherApiException catch (e) {
      _searchResults = const [];
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (e) {
      _searchResults = const [];
      _errorMessage = 'Gagal mencari lokasi: $e';
      _state = ViewState.error;
    }

    notifyListeners();
  }

  /// Menyimpan lokasi yang dipilih ke riwayat pencarian lokal.
  Future<void> recordSelection(LocationModel location) async {
    _searchHistory = await _storageService.addToSearchHistory(location);
    notifyListeners();
  }

  Future<void> removeHistoryItem(LocationModel location) async {
    _searchHistory = await _storageService.removeHistoryItem(location);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = const [];
    notifyListeners();
  }

  void resetSearch() {
    _query = '';
    _searchResults = const [];
    _errorMessage = null;
    _state = ViewState.initial;
    notifyListeners();
  }
}
