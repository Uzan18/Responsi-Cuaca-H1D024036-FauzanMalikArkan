import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'widgets/state_feedback_view.dart';

/// Halaman pencarian lokasi kota menggunakan Open-Meteo Geocoding API
/// serta pengelolaan lokasi favorit dan riwayat pencarian (Search / Location Screen).
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final searchVm = context.read<SearchLocationViewModel>();
      searchVm.resetSearch();
      searchVm.loadHistory();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        context.read<SearchLocationViewModel>().searchCities(value);
      }
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    context.read<SearchLocationViewModel>().searchCities(value);
  }

  Future<void> _selectLocation(LocationModel location) async {
    final weatherVm = context.read<WeatherViewModel>();
    final searchVm = context.read<SearchLocationViewModel>();

    await searchVm.recordSelection(location);
    unawaited(weatherVm.selectLocation(location));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherVm = context.watch<WeatherViewModel>();
    final searchVm = context.watch<SearchLocationViewModel>();
    final isLoading = searchVm.state == ViewState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Lokasi'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        hintText: 'Cari nama kota atau wilayah...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (_searchController.text.isNotEmpty) ...[
                              IconButton(
                                tooltip: 'Cari sekarang',
                                onPressed: () =>
                                    _submitSearch(_searchController.text),
                                icon: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Bersihkan pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  searchVm.resetSearch();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildContent(context, weatherVm, searchVm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WeatherViewModel weatherVm,
    SearchLocationViewModel searchVm,
  ) {
    switch (searchVm.state) {
      case ViewState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Mencari lokasi...'),
              ],
            ),
          ),
        );
      case ViewState.error:
        return StateFeedbackView(
          icon: Icons.wifi_off_rounded,
          title: 'Pencarian Gagal',
          message:
              searchVm.errorMessage ?? 'Gagal mengambil daftar kota dari API.',
          actionLabel: 'Coba Lagi',
          onAction: () => searchVm.searchCities(_searchController.text),
          isError: true,
        );
      case ViewState.empty:
        return StateFeedbackView(
          icon: Icons.location_off_rounded,
          title: 'Kota Tidak Ditemukan',
          message: searchVm.errorMessage ??
              'Tidak ada hasil untuk "${searchVm.query}". Coba gunakan kata kunci lain.',
        );
      case ViewState.loaded:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          itemCount: searchVm.searchResults.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final city = searchVm.searchResults[index];
            return _LocationTile(
              location: city,
              isSelected: city == weatherVm.selectedLocation,
              isFavorite: weatherVm.isFavorite(city),
              onTap: () => _selectLocation(city),
              onToggleFavorite: () => weatherVm.toggleFavorite(city),
            );
          },
        );
      case ViewState.initial:
        return _SavedLocationsView(
          favorites: weatherVm.favorites,
          history: searchVm.searchHistory,
          selectedLocation: weatherVm.selectedLocation,
          isFavoriteFn: weatherVm.isFavorite,
          onSelect: _selectLocation,
          onToggleFavorite: weatherVm.toggleFavorite,
          onRemoveHistory: searchVm.removeHistoryItem,
          onClearHistory: searchVm.clearHistory,
        );
    }
  }
}

class _SavedLocationsView extends StatelessWidget {
  final List<LocationModel> favorites;
  final List<LocationModel> history;
  final LocationModel selectedLocation;
  final bool Function(LocationModel) isFavoriteFn;
  final ValueChanged<LocationModel> onSelect;
  final ValueChanged<LocationModel> onToggleFavorite;
  final ValueChanged<LocationModel> onRemoveHistory;
  final VoidCallback onClearHistory;

  const _SavedLocationsView({
    required this.favorites,
    required this.history,
    required this.selectedLocation,
    required this.isFavoriteFn,
    required this.onSelect,
    required this.onToggleFavorite,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (favorites.isEmpty && history.isEmpty) {
      return const StateFeedbackView(
        icon: Icons.explore_outlined,
        title: 'Cari Lokasi Cuaca',
        message:
            'Ketik nama kota di kolom pencarian untuk melihat cuaca terkini atau menyimpannya sebagai favorit.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      children: [
        Text('Lokasi Favorit', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (favorites.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Belum ada lokasi favorit. Ketuk ikon hati pada hasil pencarian untuk menyimpan kota.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...favorites.map(
            (city) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LocationTile(
                location: city,
                isSelected: city == selectedLocation,
                isFavorite: true,
                onTap: () => onSelect(city),
                onToggleFavorite: () => onToggleFavorite(city),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pencarian Terakhir', style: theme.textTheme.titleLarge),
            if (history.isNotEmpty)
              TextButton(
                onPressed: onClearHistory,
                child: const Text('Hapus Semua'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Belum ada riwayat pencarian.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...history.map(
            (city) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LocationTile(
                location: city,
                isSelected: city == selectedLocation,
                isFavorite: isFavoriteFn(city),
                onTap: () => onSelect(city),
                onToggleFavorite: () => onToggleFavorite(city),
                onDeleteHistory: () => onRemoveHistory(city),
              ),
            ),
          ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final LocationModel location;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDeleteHistory;

  const _LocationTile({
    required this.location,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.onDeleteHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.35))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.near_me_rounded
                      : Icons.place_outlined,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (location.subtitle.isNotEmpty) location.subtitle,
                          location.coordinatesLabel,
                        ].join(' • '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      isFavorite ? 'Hapus dari Favorit' : 'Simpan Favorit',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                if (onDeleteHistory != null)
                  IconButton(
                    tooltip: 'Hapus dari Riwayat',
                    onPressed: onDeleteHistory,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
