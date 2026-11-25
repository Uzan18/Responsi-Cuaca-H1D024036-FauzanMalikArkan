import 'package:flutter/material.dart';

/// Data satu item detail cuaca untuk ditampilkan dalam panel arsitektural.
class WeatherDetailItem {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const WeatherDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });
}

/// Panel detail kondisi cuaca terpadu dalam satu kartu bersih dengan pembatas
/// tipis (hairline grid), tanpa kotak-kotak terpisah atau aksen berlebih.
class WeatherDetailsPanel extends StatelessWidget {
  final List<WeatherDetailItem> items;

  const WeatherDetailsPanel({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<WeatherDetailItem>>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        items.sublist(i, i + 2 > items.length ? items.length : i + 2),
      );
    }

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
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F5F9),
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _DetailCell(item: rows[r][0])),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  Expanded(
                    child: rows[r].length > 1
                        ? _DetailCell(item: rows[r][1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final WeatherDetailItem item;

  const _DetailCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 14,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: const Color(0xFF0F172A),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            item.caption,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
