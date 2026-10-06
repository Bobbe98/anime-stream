import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../screens/player_screen.dart';
import '../screens/series_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'series_art.dart';

void openSeries(BuildContext context, Series series) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => SeriesScreen(series: series)));
}

/// Apre il player, oppure propone Premium se l'episodio è bloccato.
Future<void> playEpisode(BuildContext context, Episode episode) async {
  final state = context.read<AppState>();
  if (state.isLocked(episode)) {
    await showPremiumSheet(context);
    if (state.isLocked(episode) || !context.mounted) return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PlayerScreen(episode: episode)));
}

Future<void> showPremiumSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppColors.premium,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Episodio Premium',
            textAlign: TextAlign.center,
            style: Theme.of(sheetContext).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Con AniWave Fan sblocchi tutti gli episodi, subito dopo '
            "l'uscita in Giappone e senza pubblicità.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.premium,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              sheetContext.read<AppState>().premium = true;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Premium attivato (modalità demo, nessun pagamento)',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bolt),
            label: const Text('Prova gratis (demo)'),
          ),
        ],
      ),
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(
    this.text, {
    super.key,
    this.color = AppColors.accent,
    this.dark = false,
  });

  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class PosterCard extends StatelessWidget {
  const PosterCard({super.key, required this.series, this.width = 128});

  final Series series;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final inList = context.select<AppState, bool>(
      (s) => s.inWatchlist(series.id),
    );
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openSeries(context, series),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SeriesArt(series: series),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (series.isNew)
                            const Tag('NUOVO', color: AppColors.accent2),
                          if (series.dubbed) const Tag('DUB'),
                        ],
                      ),
                    ),
                    if (inList)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.bookmark,
                          color: AppColors.premium,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              series.dubbed ? 'Sub | Dub' : 'Sottotitolato',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.onMore});

  final String title;
  final String? subtitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (onMore != null)
            TextButton(onPressed: onMore, child: const Text('Vedi tutto')),
        ],
      ),
    );
  }
}

class SeriesRow extends StatelessWidget {
  const SeriesRow({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Series> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, subtitle: subtitle),
        SizedBox(
          height: 262,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => PosterCard(series: items[i]),
          ),
        ),
      ],
    );
  }
}

/// Miniatura 16:9 di un episodio con barra di avanzamento.
class EpisodeThumb extends StatelessWidget {
  const EpisodeThumb({super.key, required this.episode, this.showLock = true});

  final Episode episode;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final series = Catalog.byId(episode.seriesId);
    final fraction = state.fractionOf(episode);
    final locked = showLock && state.isLocked(episode);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SeriesArt(
              series: series,
              showTitle: false,
              wide: true,
              variant: episode.number * 97 + episode.season,
              label: '${episode.number}',
            ),
            Positioned(
              right: 6,
              bottom: 8,
              child: Tag(_fmt(episode.duration), color: Colors.black87),
            ),
            if (locked)
              const Positioned(
                left: 6,
                top: 6,
                child: Tag('PREMIUM', color: AppColors.premium, dark: true),
              )
            else if (state.isWatched(episode))
              const Positioned(
                left: 6,
                top: 6,
                child: Tag('VISTO', color: Colors.black87),
              ),
            if (fraction > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  color: AppColors.accent2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContinueCard extends StatelessWidget {
  const ContinueCard({super.key, required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final series = Catalog.byId(episode.seriesId);
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: () => playEpisode(context, episode),
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                EpisodeThumb(episode: episode),
                const Positioned.fill(
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              series.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${episode.code} · ${episode.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
