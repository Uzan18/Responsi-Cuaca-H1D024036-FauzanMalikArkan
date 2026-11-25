import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

/// Service penyimpanan lokal menggunakan SharedPreferences untuk menyimpan
/// daftar lokasi favorit, riwayat pencarian, dan lokasi terakhir yang dipilih.
class LocalStorageService {
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';
  static const String _selectedLocationKey = 'selected_location';
  static const int _maxHistoryItems = 10;

  SharedPreferences? _prefs;

  LocalStorageService({this._prefs});

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<LocationModel>> getFavorites() async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_favoritesKey) ?? const [];
    return _decodeLocationList(rawList);
  }

  Future<List<LocationModel>> toggleFavorite(LocationModel location) async {
    final favorites = await getFavorites();
    final exists = favorites.any((item) => item == location);

    final updated = exists
        ? favorites.where((item) => item != location).toList()
        : [location, ...favorites];

    await _saveLocationList(_favoritesKey, updated);
    return updated;
  }

  Future<List<LocationModel>> removeFavorite(LocationModel location) async {
    final favorites = await getFavorites();
    final updated = favorites.where((item) => item != location).toList();
    await _saveLocationList(_favoritesKey, updated);
    return updated;
  }

  Future<List<LocationModel>> getSearchHistory() async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_historyKey) ?? const [];
    return _decodeLocationList(rawList);
  }

  Future<List<LocationModel>> addToSearchHistory(LocationModel location) async {
    final history = await getSearchHistory();
    final filtered = history.where((item) => item != location).toList();
    final updated = [location, ...filtered].take(_maxHistoryItems).toList();
    await _saveLocationList(_historyKey, updated);
    return updated;
  }

  Future<List<LocationModel>> removeHistoryItem(LocationModel location) async {
    final history = await getSearchHistory();
    final updated = history.where((item) => item != location).toList();
    await _saveLocationList(_historyKey, updated);
    return updated;
  }

  Future<void> clearSearchHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_historyKey);
  }

  Future<LocationModel?> getSelectedLocation() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_selectedLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LocationModel.fromRawJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedLocation(LocationModel location) async {
    final prefs = await _getPrefs();
    await prefs.setString(_selectedLocationKey, location.toRawJson());
  }

  List<LocationModel> _decodeLocationList(List<String> rawList) {
    final items = <LocationModel>[];
    for (final raw in rawList) {
      try {
        items.add(LocationModel.fromRawJson(raw));
      } catch (_) {
        // Lewati entri yang korup agar aplikasi tetap stabil.
      }
    }
    return items;
  }

  Future<void> _saveLocationList(String key, List<LocationModel> items) async {
    final prefs = await _getPrefs();
    final encoded = items.map((e) => e.toRawJson()).toList();
    await prefs.setStringList(key, encoded);
  }
}
