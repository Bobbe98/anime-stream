import 'package:flutter/material.dart';

import '../data/anilist.dart';
import '../theme.dart';

/// Copertina di un anime reale, caricata dal CDN di AniList.
class AnimeCover extends StatelessWidget {
  const AnimeCover({
    super.key,
    required this.url,
    this.color,
    this.title,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final Color? color;
  final String? title;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(color: color, title: title);
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.color, this.title});

  final Color? color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.surfaceHigh;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.6)!],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: title == null
              ? const Icon(Icons.movie_outlined, color: Colors.white54)
              : Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Scheda verticale (copertina + titolo) di un anime reale.
class AnimeCard extends StatelessWidget {
  const AnimeCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.badge,
  });

  final AnimeSummary anime;
  final VoidCallback onTap;

  /// Testo sopra la copertina, es. "Ep. 3 · 17:30".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimeCover(
                    url: anime.cover,
                    color: anime.color,
                    title: anime.title,
                  ),
                  if (anime.score != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _Pill(
                        icon: Icons.star,
                        text: (anime.score! / 10).toStringAsFixed(1),
                      ),
                    ),
                  if (badge != null)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      right: 6,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Pill(text: badge!, color: AppColors.accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            [
              formatLabel(anime.format),
              if (anime.episodes != null) '${anime.episodes} ep.',
            ].where((s) => s.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon, this.color = Colors.black87});

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: AppColors.premium),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
