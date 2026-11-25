import 'package:flutter/material.dart';

import '../views/widgets/weather_illustration.dart';

/// Informasi visual dan teks deskripsi untuk kode cuaca WMO Open-Meteo.
class WeatherVisual {
  final String label;
  final WeatherArtType artType;
  final IconData compactIcon;
  final Color accentColor;
  final List<Color> skyGradient;

  const WeatherVisual({
    required this.label,
    required this.artType,
    required this.compactIcon,
    required this.accentColor,
    required this.skyGradient,
  });
}

/// Utilitas pemetaan kode cuaca WMO dan pemformatan tanggal berbahasa Indonesia.
class WeatherHelper {
  WeatherHelper._();

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static WeatherVisual describeWeatherCode(int code) {
    if (code == 0) {
      return const WeatherVisual(
        label: 'Cerah',
        artType: WeatherArtType.clearSun,
        compactIcon: Icons.wb_sunny_rounded,
        accentColor: Color(0xFFF59E0B),
        skyGradient: [Color(0xFF0E7490), Color(0xFF0284C7), Color(0xFF38BDF8)],
      );
    }
    if (code == 1 || code == 2) {
      return const WeatherVisual(
        label: 'Cerah Berawan',
        artType: WeatherArtType.partlyCloudy,
        compactIcon: Icons.wb_cloudy_rounded,
        accentColor: Color(0xFF0284C7),
        skyGradient: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
      );
    }
    if (code == 3) {
      return const WeatherVisual(
        label: 'Berawan',
        artType: WeatherArtType.overcast,
        compactIcon: Icons.cloud_rounded,
        accentColor: Color(0xFF64748B),
        skyGradient: [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
      );
    }
    if (code == 45 || code == 48) {
      return const WeatherVisual(
        label: 'Berkabut',
        artType: WeatherArtType.fog,
        compactIcon: Icons.dehaze_rounded,
        accentColor: Color(0xFF64748B),
        skyGradient: [Color(0xFF3F4E5A), Color(0xFF526473), Color(0xFF7B8E9E)],
      );
    }
    if (code >= 51 && code <= 57) {
      return const WeatherVisual(
        label: 'Gerimis',
        artType: WeatherArtType.drizzle,
        compactIcon: Icons.water_drop_outlined,
        accentColor: Color(0xFF3B82F6),
        skyGradient: [Color(0xFF1E3A8A), Color(0xFF2B52B5), Color(0xFF4E79DC)],
      );
    }
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      final isHeavy = code == 65 || code == 82;
      return WeatherVisual(
        label: isHeavy ? 'Hujan Lebat' : 'Hujan',
        artType: isHeavy ? WeatherArtType.heavyRain : WeatherArtType.rain,
        compactIcon: Icons.water_drop_rounded,
        accentColor: const Color(0xFF2563EB),
        skyGradient: const [
          Color(0xFF172554),
          Color(0xFF1E3A8A),
          Color(0xFF3B5998),
        ],
      );
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return const WeatherVisual(
        label: 'Hujan Salju',
        artType: WeatherArtType.snow,
        compactIcon: Icons.ac_unit_rounded,
        accentColor: Color(0xFF0EA5E9),
        skyGradient: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF7DD3FC)],
      );
    }
    if (code >= 95 && code <= 99) {
      return const WeatherVisual(
        label: 'Badai Petir',
        artType: WeatherArtType.thunderstorm,
        compactIcon: Icons.bolt_rounded,
        accentColor: Color(0xFF6366F1),
        skyGradient: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF3730A3)],
      );
    }
    return const WeatherVisual(
      label: 'Berawan',
      artType: WeatherArtType.overcast,
      compactIcon: Icons.cloud_rounded,
      accentColor: Color(0xFF3B82F6),
      skyGradient: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF60A5FA)],
    );
  }

  static String formatDayLabel(DateTime date, {int index = 0}) {
    if (index == 0) return 'Hari Ini';
    if (index == 1) return 'Besok';
    return _dayNames[date.weekday - 1];
  }

  static String formatShortDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]}';
  }

  static String formatTimeOnly(String isoTime) {
    final parsed = DateTime.tryParse(isoTime);
    if (parsed == null) return '-';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
