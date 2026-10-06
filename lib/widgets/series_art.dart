import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';

/// Copertina generata: gradiente della serie, motivi geometrici ed emblema.
/// Nessuna immagine esterna, quindi nessun problema di copyright.
class SeriesArt extends StatelessWidget {
  const SeriesArt({
    super.key,
    required this.series,
    this.showTitle = true,
    this.wide = false,
    this.variant = 0,
    this.label,
  });

  final Series series;
  final bool showTitle;
  final bool wide;
  final int variant;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest.shortestSide.isFinite
            ? c.biggest.shortestSide
            : 120.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: series.palette,
            ),
          ),
          child: CustomPaint(
            painter: _ArtPainter(seed: series.id.hashCode ^ variant),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: wide
                      ? const Alignment(0.8, -0.5)
                      : const Alignment(0, -0.3),
                  child: Icon(
                    series.emblem,
                    size: size * (wide ? 0.55 : 0.42),
                    color: Colors.white.withValues(alpha: 0.85),
                    shadows: const [
                      Shadow(blurRadius: 24, color: Colors.black54),
                    ],
                  ),
                ),
                if (label != null)
                  Center(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                        shadows: const [
                          Shadow(blurRadius: 12, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                if (showTitle)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      series.title.toUpperCase(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (size * 0.11).clamp(9.0, 22.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        height: 1.05,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final paint = Paint()..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      paint
        ..strokeWidth = 1 + rnd.nextDouble() * 3
        ..color = Colors.white.withValues(alpha: 0.05 + rnd.nextDouble() * 0.1);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        size.shortestSide * (0.2 + rnd.nextDouble() * 0.6),
        paint,
      );
    }

    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = size.shortestSide * 0.05;
    final offset = rnd.nextDouble() * size.width;
    for (var i = -2; i < 3; i++) {
      final x = offset + i * size.shortestSide * 0.25;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }

    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black87],
        stops: [0.45, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.seed != seed;
}
