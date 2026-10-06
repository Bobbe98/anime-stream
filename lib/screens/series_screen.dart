import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/series_art.dart';

const _weekdays = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key, required this.series});

  final Series series;

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late int _season;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _season = context.read<AppState>().upNext(widget.series).season;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.series;
    final state = context.watch<AppState>();
    final next = state.upNext(s);
    final started = state.hasStarted(s);
    final inList = state.inWatchlist(s.id);
    final episodes = s.episodesOf(_season);
    final similar = Catalog.similarTo(s);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: SeriesArt(series: s, wide: true, showTitle: false),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    s.originalTitle,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Tag(s.ageRating, color: AppColors.surfaceHigh),
                      Text('${s.year}'),
                      const Text('•'),
                      Text(s.studio),
                      const Text('•'),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.premium,
                      ),
                      Text(s.rating.toStringAsFixed(1)),
                      if (s.dubbed) const Tag('DUB'),
                    ],
                  ),
                  if (s.isSimulcast) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.accent2,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Simulcast: nuovo episodio ogni '
                            '${_weekdays[s.simulcastWeekday! - 1].toLowerCase()} '
                            'alle ${s.simulcastTime}',
                            style: const TextStyle(
                              color: AppColors.accent2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => playEpisode(context, next),
                          icon: Icon(
                            state.isLocked(next)
                                ? Icons.lock
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            '${started ? 'Continua' : 'Inizia'} ${next.code}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: inList
                            ? 'Rimuovi dalla lista'
                            : 'Aggiungi alla lista',
                        onPressed: () => state.toggleWatchlist(s.id),
                        icon: Icon(
                          inList ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.synopsis,
                          maxLines: _expanded ? null : 3,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.4),
                        ),
                        Text(
                          _expanded ? 'Meno' : 'Altro',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [for (final g in s.genres) Chip(label: Text(g))],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Episodi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (s.seasons.length > 1)
                        DropdownButton<int>(
                          value: _season,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final n in s.seasons)
                              DropdownMenuItem(
                                value: n,
                                child: Text('Stagione $n'),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _season = v ?? _season),
                        )
                      else
                        const Text(
                          'Stagione 1',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: episodes.length,
            itemBuilder: (_, i) => _EpisodeTile(episode: episodes[i]),
          ),
          SliverToBoxAdapter(
            child: SeriesRow(title: 'Più come questo', items: similar),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return InkWell(
      onTap: () => playEpisode(context, episode),
      onLongPress: () => _showOptions(context, state),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: EpisodeThumb(episode: episode)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E${episode.number} - ${episode.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.synopsis,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Opzioni',
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context, state),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, AppState state) {
    final watched = state.isWatched(episode);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Riproduci'),
              onTap: () {
                Navigator.pop(sheet);
                playEpisode(context, episode);
              },
            ),
            ListTile(
              leading: Icon(
                watched ? Icons.visibility_off : Icons.check_circle_outline,
              ),
              title: Text(
                watched ? 'Segna come non visto' : 'Segna come visto',
              ),
              onTap: () {
                state.markWatched(episode, !watched);
                Navigator.pop(sheet);
              },
            ),
          ],
        ),
      ),
    );
  }
}
