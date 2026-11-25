import 'package:flutter/material.dart';

import '../../models/weather_model.dart';
import '../../utils/weather_helper.dart';
import 'weather_illustration.dart';

/// Baris prakiraan cuaca harian dengan ilustrasi vektor kustom dan
/// rentang suhu proporsional terhadap suhu min/max mingguan.
class DailyForecastTile extends StatelessWidget {
  final DailyForecast forecast;
  final int index;
  final double weekMinTemp;
  final double weekMaxTemp;

  const DailyForecastTile({
    super.key,
    required this.forecast,
    required this.index,
    required this.weekMinTemp,
    required this.weekMaxTemp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = WeatherHelper.describeWeatherCode(forecast.weatherCode);

    final totalSpan = (weekMaxTemp - weekMinTemp).abs();
    final safeSpan = totalSpan < 0.5 ? 1.0 : totalSpan;
    final startRatio = ((forecast.temperature2mMin - weekMinTemp) / safeSpan)
        .clamp(0.0, 1.0);
    final endRatio = ((forecast.temperature2mMax - weekMinTemp) / safeSpan)
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WeatherHelper.formatDayLabel(forecast.date, index: index),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  WeatherHelper.formatShortDate(forecast.date),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          WeatherIllustration(type: visual.artType, size: 32),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: forecast.precipitationProbabilityMax > 0
                ? Text(
                    '${forecast.precipitationProbabilityMax}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF0284C7),
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${forecast.temperature2mMin.toStringAsFixed(0)}°',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      final left = startRatio * barWidth;
                      final fillWidth =
                          ((endRatio - startRatio) * barWidth).clamp(8.0, barWidth);

                      return Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: left.clamp(0.0, barWidth - fillWidth),
                              width: fillWidth,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFFF59E0B),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${forecast.temperature2mMax.toStringAsFixed(0)}°',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
