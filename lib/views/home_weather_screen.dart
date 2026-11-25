import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';
import '../utils/weather_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'search_location_screen.dart';
import 'widgets/daily_forecast_tile.dart';
import 'widgets/state_feedback_view.dart';
import 'widgets/weather_illustration.dart';
import 'widgets/weather_metric_card.dart';

/// Halaman utama aplikasi untuk menampilkan cuaca terkini dan prakiraan harian
/// kota yang sedang dipilih (Home / Weather Screen).
class HomeWeatherScreen extends StatefulWidget {
  const HomeWeatherScreen({super.key});

  @override
  State<HomeWeatherScreen> createState() => _HomeWeatherScreenState();
}

class _HomeWeatherScreenState extends State<HomeWeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WeatherViewModel>().initialize();
      }
    });
  }

  Future<void> _openSearchScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchLocationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(
      builder: (context, viewModel, _) {
        final weather = viewModel.weatherData;
        final visual = weather != null
            ? WeatherHelper.describeWeatherCode(weather.current.weatherCode)
            : WeatherHelper.describeWeatherCode(1);

        final isLoaded =
            viewModel.state == ViewState.loaded && weather != null;

        return Scaffold(
          backgroundColor: AppTheme.canvasBackground,
          body: isLoaded
              ? _LoadedWeatherBody(
                  viewModel: viewModel,
                  weather: weather,
                  visual: visual,
                  onOpenSearch: _openSearchScreen,
                )
              : _NonLoadedShell(
                  viewModel: viewModel,
                  onOpenSearch: _openSearchScreen,
                ),
        );
      },
    );
  }
}

class _NonLoadedShell extends StatelessWidget {
  final WeatherViewModel viewModel;
  final VoidCallback onOpenSearch;

  const _NonLoadedShell({
    required this.viewModel,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedLocation;
    return Scaffold(
      appBar: AppBar(
        title: Text(selected.name),
        actions: [
          IconButton(
            tooltip: 'Cari Kota & Favorit',
            onPressed: onOpenSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Perbarui Cuaca',
            onPressed: viewModel.state == ViewState.loading
                ? null
                : viewModel.fetchWeatherForSelectedLocation,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (viewModel.state) {
          ViewState.initial || ViewState.loading => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mengambil prakiraan cuaca terkini...'),
                  ],
                ),
              ),
            ),
          ViewState.empty => StateFeedbackView(
              icon: Icons.cloud_off_rounded,
              title: 'Data Cuaca Kosong',
              message:
                  'Informasi cuaca untuk lokasi ini belum tersedia. Coba pilih kota lain.',
              actionLabel: 'Cari Kota Lain',
              onAction: onOpenSearch,
            ),
          ViewState.error => StateFeedbackView(
              icon: Icons.wifi_off_rounded,
              title: 'Gagal Memuat Cuaca',
              message: viewModel.errorMessage ??
                  'Terjadi gangguan saat menghubungi layanan cuaca Open-Meteo.',
              actionLabel: 'Coba Lagi',
              onAction: viewModel.fetchWeatherForSelectedLocation,
              isError: true,
            ),
          ViewState.loaded => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LoadedWeatherBody extends StatelessWidget {
  final WeatherViewModel viewModel;
  final WeatherData weather;
  final WeatherVisual visual;
  final VoidCallback onOpenSearch;

  const _LoadedWeatherBody({
    required this.viewModel,
    required this.weather,
    required this.visual,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedLocation;
    final isFav = viewModel.isCurrentLocationFavorite;

    return RefreshIndicator(
      onRefresh: viewModel.fetchWeatherForSelectedLocation,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _AtmosphericHeader(
              location: selected,
              weather: weather,
              visual: visual,
              isFavorite: isFav,
              favorites: viewModel.favorites,
              onSelectFavorite: viewModel.selectLocation,
              onToggleFavorite: () async {
                await viewModel.toggleCurrentLocationFavorite();
                if (!context.mounted) return;
                final added = viewModel.isCurrentLocationFavorite;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        added
                            ? '${selected.name} disimpan ke favorit'
                            : '${selected.name} dihapus dari favorit',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              onOpenSearch: onOpenSearch,
              onRefresh: viewModel.fetchWeatherForSelectedLocation,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WeatherDetailsSection(weather: weather, visual: visual),
                      const SizedBox(height: 16),
                      _DailyForecastSection(forecasts: weather.dailyForecasts),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphericHeader extends StatelessWidget {
  final LocationModel location;
  final WeatherData weather;
  final WeatherVisual visual;
  final bool isFavorite;
  final List<LocationModel> favorites;
  final ValueChanged<LocationModel> onSelectFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenSearch;
  final VoidCallback onRefresh;

  const _AtmosphericHeader({
    required this.location,
    required this.weather,
    required this.visual,
    required this.isFavorite,
    required this.favorites,
    required this.onSelectFavorite,
    required this.onToggleFavorite,
    required this.onOpenSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = weather.current;
    final today = weather.todayForecast;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: visual.skyGradient,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CityDropdownSelector(
                          currentLocation: location,
                          favorites: favorites,
                          onSelectCity: onSelectFavorite,
                          onOpenSearch: onOpenSearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderActionButton(
                        tooltip: isFavorite
                            ? 'Hapus dari Favorit'
                            : 'Simpan ke Favorit',
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: isFavorite
                            ? const Color(0xFFFF6B81)
                            : Colors.white,
                        onPressed: onToggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      _HeaderActionButton(
                        tooltip: 'Cari Kota & Favorit',
                        icon: Icons.search_rounded,
                        onPressed: onOpenSearch,
                      ),
                      const SizedBox(width: 8),
                      _HeaderActionButton(
                        tooltip: 'Perbarui Cuaca',
                        icon: Icons.refresh_rounded,
                        onPressed: onRefresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${current.temperature2m.toStringAsFixed(1)}°C',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              visual.label,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today != null
                                  ? 'Terasa ${current.apparentTemperature.toStringAsFixed(1)}°  •  ${today.temperature2mMin.toStringAsFixed(0)}° / ${today.temperature2mMax.toStringAsFixed(0)}°'
                                  : 'Terasa ${current.apparentTemperature.toStringAsFixed(1)}°',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      WeatherIllustration(type: visual.artType, size: 112),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pembaruan pukul ${WeatherHelper.formatTimeOnly(current.time)} ${weather.timezoneAbbreviation}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pemilih kota berbentuk dropdown saat nama kota aktif diketuk.
/// Menampilkan daftar kota favorit yang tersimpan serta opsi cari kota lain.
class _CityDropdownSelector extends StatelessWidget {
  final LocationModel currentLocation;
  final List<LocationModel> favorites;
  final ValueChanged<LocationModel> onSelectCity;
  final VoidCallback onOpenSearch;

  const _CityDropdownSelector({
    required this.currentLocation,
    required this.favorites,
    required this.onSelectCity,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: 'Pilih kota tersimpan',
      offset: const Offset(0, 46),
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (value) {
        if (value == '__search__') {
          onOpenSearch();
          return;
        }
        final matched = favorites.where((c) => c.uniqueKey == value).firstOrNull;
        if (matched != null) {
          onSelectCity(matched);
        }
      },
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<String>>[];

        if (favorites.isEmpty) {
          entries.add(
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'Belum ada kota favorit tersimpan',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        } else {
          for (final city in favorites) {
            final isSelected = city == currentLocation;
            entries.add(
              PopupMenuItem<String>(
                value: city.uniqueKey,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            city.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (city.subtitle.isNotEmpty)
                            Text(
                              city.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
        }

        entries.add(const PopupMenuDivider(height: 8));
        entries.add(
          PopupMenuItem<String>(
            value: '__search__',
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Cari & Kelola Lokasi',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );

        return entries;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    currentLocation.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
            if (currentLocation.subtitle.isNotEmpty)
              Text(
                currentLocation.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    this.iconColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 20),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _WeatherDetailsSection extends StatelessWidget {
  final WeatherData weather;
  final WeatherVisual visual;

  const _WeatherDetailsSection({
    required this.weather,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final today = weather.todayForecast;
    final diff = current.apparentTemperature - current.temperature2m;
    final feelsCaption = diff.abs() < 0.8
        ? 'Sesuai suhu aktual'
        : diff > 0
            ? '+${diff.toStringAsFixed(1)}° lebih hangat'
            : '${diff.toStringAsFixed(1)}° lebih sejuk';

    final windCaption = current.windSpeed10m < 12
        ? 'Sepoi ringan'
        : current.windSpeed10m < 25
            ? 'Angin sedang'
            : 'Cukup kencang';

    final items = [
      WeatherDetailItem(
        icon: Icons.device_thermostat_rounded,
        label: 'Suhu Dirasakan',
        value: '${current.apparentTemperature.toStringAsFixed(1)} °C',
        caption: feelsCaption,
      ),
      WeatherDetailItem(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.relativeHumidity2m}%',
        caption: current.relativeHumidity2m >= 80 ? 'Udara lembap' : 'Kondisi nyaman',
      ),
      WeatherDetailItem(
        icon: Icons.air_rounded,
        label: 'Kecepatan Angin',
        value: '${current.windSpeed10m.toStringAsFixed(1)} km/j',
        caption: windCaption,
      ),
      WeatherDetailItem(
        icon: Icons.shower_outlined,
        label: 'Curah Hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
        caption: current.precipitation > 0 ? 'Presipitasi aktif' : 'Tidak ada hujan',
      ),
      WeatherDetailItem(
        icon: Icons.umbrella_outlined,
        label: 'Peluang Hujan',
        value: today != null ? '${today.precipitationProbabilityMax}%' : '-',
        caption: 'Maks. hari ini',
      ),
      WeatherDetailItem(
        icon: visual.compactIcon,
        label: 'Kode Cuaca',
        value: 'WMO ${current.weatherCode}',
        caption: visual.label,
      ),
    ];

    return WeatherDetailsPanel(items: items);
  }
}

class _DailyForecastSection extends StatelessWidget {
  final List<DailyForecast> forecasts;

  const _DailyForecastSection({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekMin = forecasts.isEmpty
        ? 0.0
        : forecasts.map((e) => e.temperature2mMin).reduce(math.min);
    final weekMax = forecasts.isEmpty
        ? 0.0
        : forecasts.map((e) => e.temperature2mMax).reduce(math.max);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prakiraan ${forecasts.length} Hari Ke Depan',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (forecasts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Data prakiraan harian tidak tersedia.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forecasts.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              ),
              itemBuilder: (context, index) => DailyForecastTile(
                forecast: forecasts[index],
                index: index,
                weekMinTemp: weekMin,
                weekMaxTemp: weekMax,
              ),
            ),
        ],
      ),
    );
  }
}
