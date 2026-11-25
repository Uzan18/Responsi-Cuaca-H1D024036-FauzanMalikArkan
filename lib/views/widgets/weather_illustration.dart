import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Jenis ilustrasi cuaca vektor yang digambar dengan CustomPainter
/// agar tampilan terlihat modern dan natural (bukan ikon kotak standar).
enum WeatherArtType {
  clearSun,
  partlyCloudy,
  overcast,
  fog,
  drizzle,
  rain,
  heavyRain,
  snow,
  thunderstorm,
}

/// Widget ilustrasi cuaca kustom berbasis CustomPainter.
class WeatherIllustration extends StatelessWidget {
  final WeatherArtType type;
  final double size;

  const WeatherIllustration({
    super.key,
    required this.type,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WeatherArtPainter(type: type),
      ),
    );
  }
}

class _WeatherArtPainter extends CustomPainter {
  final WeatherArtType type;

  _WeatherArtPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (type) {
      case WeatherArtType.clearSun:
        _drawSun(canvas, Offset(w * 0.5, h * 0.5), w * 0.28, withRays: true);
        break;
      case WeatherArtType.partlyCloudy:
        _drawSun(canvas, Offset(w * 0.65, h * 0.34), w * 0.20, withRays: true);
        _drawCloud(
          canvas,
          Offset(w * 0.44, h * 0.58),
          w * 0.64,
          const Color(0xFFFFFFFF),
          const Color(0xFFDCE8F8),
        );
        break;
      case WeatherArtType.overcast:
        _drawCloud(
          canvas,
          Offset(w * 0.58, h * 0.38),
          w * 0.48,
          const Color(0xFFD6E2F0),
          const Color(0xFFB7C7DA),
        );
        _drawCloud(
          canvas,
          Offset(w * 0.45, h * 0.56),
          w * 0.66,
          const Color(0xFFFFFFFF),
          const Color(0xFFD9E4F2),
        );
        break;
      case WeatherArtType.fog:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.40),
          w * 0.60,
          const Color(0xFFF3F6FA),
          const Color(0xFFCFD9E6),
        );
        _drawFogLines(canvas, size);
        break;
      case WeatherArtType.drizzle:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.40),
          w * 0.64,
          const Color(0xFFFFFFFF),
          const Color(0xFFCFE0F5),
        );
        _drawRainDrops(canvas, size, count: 3, heavy: false);
        break;
      case WeatherArtType.rain:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.38),
          w * 0.66,
          const Color(0xFFF4F8FE),
          const Color(0xFFBED3EE),
        );
        _drawRainDrops(canvas, size, count: 4, heavy: false);
        break;
      case WeatherArtType.heavyRain:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.37),
          w * 0.68,
          const Color(0xFFE7EFFA),
          const Color(0xFF9FB9DC),
        );
        _drawRainDrops(canvas, size, count: 5, heavy: true);
        break;
      case WeatherArtType.snow:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.39),
          w * 0.64,
          const Color(0xFFFFFFFF),
          const Color(0xFFD9E9FA),
        );
        _drawSnowFlakes(canvas, size);
        break;
      case WeatherArtType.thunderstorm:
        _drawCloud(
          canvas,
          Offset(w * 0.5, h * 0.36),
          w * 0.68,
          const Color(0xFFE2E8F4),
          const Color(0xFF93A5C4),
        );
        _drawLightning(canvas, size);
        _drawRainDrops(canvas, size, count: 2, heavy: false);
        break;
    }
  }

  void _drawSun(
    Canvas canvas,
    Offset center,
    double radius, {
    bool withRays = false,
  }) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.55),
          const Color(0xFFFFB300).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.9));
    canvas.drawCircle(center, radius * 1.9, glowPaint);

    if (withRays) {
      final rayPaint = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.85)
        ..strokeWidth = math.max(1.8, radius * 0.11)
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 8; i++) {
        final angle = (i * math.pi) / 4;
        final start = Offset(
          center.dx + math.cos(angle) * radius * 1.24,
          center.dy + math.sin(angle) * radius * 1.24,
        );
        final end = Offset(
          center.dx + math.cos(angle) * radius * 1.52,
          center.dy + math.sin(angle) * radius * 1.52,
        );
        canvas.drawLine(start, end, rayPaint);
      }
    }

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFEA78), Color(0xFFFFA726)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sunPaint);
  }

  void _drawCloud(
    Canvas canvas,
    Offset center,
    double width,
    Color topColor,
    Color bottomColor,
  ) {
    final h = width * 0.46;
    final left = center.dx - width / 2;
    final bottom = center.dy + h / 2;

    final path = Path()
      ..moveTo(left + h * 0.42, bottom)
      ..lineTo(left + width - h * 0.36, bottom)
      ..arcToPoint(
        Offset(left + width - h * 0.36, bottom - h * 0.62),
        radius: Radius.circular(h * 0.31),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(left + width * 0.56, bottom - h * 0.88),
        radius: Radius.circular(width * 0.22),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(left + h * 0.30, bottom - h * 0.56),
        radius: Radius.circular(width * 0.24),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(left + h * 0.42, bottom),
        radius: Radius.circular(h * 0.29),
        clockwise: false,
      )
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.14), 6, true);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(left, bottom - h, width, h));
    canvas.drawPath(path, paint);
  }

  void _drawRainDrops(
    Canvas canvas,
    Size size, {
    required int count,
    required bool heavy,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..strokeWidth = heavy ? size.width * 0.042 : size.width * 0.036
      ..strokeCap = StrokeCap.round;

    final startX = size.width * 0.28;
    final span = size.width * 0.44;
    final step = count > 1 ? span / (count - 1) : 0.0;
    final topY = size.height * 0.64;
    final length = heavy ? size.height * 0.20 : size.height * 0.14;

    for (var i = 0; i < count; i++) {
      final x = startX + step * i;
      final offsetY = (i.isOdd ? size.height * 0.05 : 0.0);
      canvas.drawLine(
        Offset(x, topY + offsetY),
        Offset(x - size.width * 0.05, topY + offsetY + length),
        paint,
      );
    }
  }

  void _drawFogLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = size.height * 0.048
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.67),
      Offset(size.width * 0.78, size.height * 0.67),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.79),
      Offset(size.width * 0.72, size.height * 0.79),
      paint,
    );
  }

  void _drawSnowFlakes(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE0F2FE);
    final positions = [
      Offset(size.width * 0.33, size.height * 0.70),
      Offset(size.width * 0.50, size.height * 0.77),
      Offset(size.width * 0.67, size.height * 0.70),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, size.width * 0.04, paint);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    final bolt = Path()
      ..moveTo(size.width * 0.53, size.height * 0.56)
      ..lineTo(size.width * 0.43, size.height * 0.72)
      ..lineTo(size.width * 0.52, size.height * 0.72)
      ..lineTo(size.width * 0.46, size.height * 0.88)
      ..lineTo(size.width * 0.61, size.height * 0.67)
      ..lineTo(size.width * 0.52, size.height * 0.67)
      ..close();

    final paint = Paint()..color = const Color(0xFFFCD34D);
    canvas.drawPath(bolt, paint);
  }

  @override
  bool shouldRepaint(covariant _WeatherArtPainter oldDelegate) =>
      oldDelegate.type != type;
}
