import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/anilist.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/anime_cover.dart';
import '../widgets/cards.dart';

Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Impossibile aprire il link')));
  }
}

/// Scheda di un anime reale: info da AniList e link alle piattaforme
/// ufficiali dove guardarlo.
class AnimeDetailScreen extends StatefulWidget {
  const AnimeDetailScreen({super.key, required this.summary});

  final AnimeSummary summary;

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late Future<AnimeDetail> _future;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AniListClient>().detail(widget.summary.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AnimeDetail>(
        future: _future,
        builder: (context, snap) {
          final detail = snap.data;
          final a = detail?.summary ?? widget.summary;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: AppColors.bg,
                actions: [_ListButton(anime: a)],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimeCover(
                        url: detail?.banner ?? a.coverLarge,
                        color: a.color,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, AppColors.bg],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Header(anime: a, detail: detail),
              ),
              if (snap.hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          snap.error is AniListException
                              ? '${snap.error}'
                              : 'Impossibile caricare la scheda completa.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: () => setState(_load),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Riprova'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (detail == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _WhereToWatch(detail: detail)),
                if (detail.description != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trama (in inglese, da AniList)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail.description!,
                              maxLines: _expanded ? null : 5,
                              overflow: _expanded
                                  ? null
                                  : TextOverflow.ellipsis,
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
                    ),
                  ),
                if (detail.officialEpisodes.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionHeader(
                      'Episodi ufficiali',
                      subtitle: 'Si aprono sulla piattaforma che li trasmette',
                    ),
                  ),
                  SliverList.builder(
                    itemCount: detail.officialEpisodes.length,
                    itemBuilder: (context, i) => _OfficialEpisodeTile(
                      episode: detail.officialEpisodes[i],
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Text(
                      'Dati e immagini: AniList.co',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ListButton extends StatelessWidget {
  const _ListButton({required this.anime});

  final AnimeSummary anime;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final inList = state.inRealList(anime.id);
    return IconButton(
      tooltip: inList ? 'Rimuovi dalla lista' : 'Aggiungi alla lista',
      icon: Icon(inList ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () => state.toggleRealList(anime.id, anime.title, anime.cover),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.anime, this.detail});

  final AnimeSummary anime;
  final AnimeDetail? detail;

  @override
  Widget build(BuildContext context) {
    final a = anime;
    final facts = [
      formatLabel(a.format),
      statusLabel(a.status),
      seasonLabel(a.season, a.seasonYear),
      if (a.episodes != null) '${a.episodes} episodi',
      if (detail?.duration != null) '${detail!.duration} min',
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 110,
              height: 160,
              child: AnimeCover(url: a.coverLarge, color: a.color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (a.nativeTitle != null && a.nativeTitle != a.title)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      a.nativeTitle!,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(facts, style: const TextStyle(fontSize: 12)),
                if (detail != null && detail!.studios.isNotEmpty)
                  Text(
                    detail!.studios.join(', '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                if (a.score != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.premium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(a.score! / 10).toStringAsFixed(1)} / 10',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                if (a.nextEpisode != null && a.nextAiringAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Tag(
                      'EP. ${a.nextEpisode} ${countdown(a.nextAiringAt!).toUpperCase()}',
                      color: AppColors.accent2,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final g in a.genres.take(4))
                      Tag(g, color: AppColors.surfaceHigh),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhereToWatch extends StatelessWidget {
  const _WhereToWatch({required this.detail});

  final AnimeDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dove guardarlo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (detail.streaming.isEmpty)
            const Text(
              'AniList non indica ancora piattaforme ufficiali per questo anime.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (l, label) in _labelled(detail.streaming))
                  FilledButton.tonalIcon(
                    onPressed: () => openLink(context, l.url),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(label),
                  ),
              ],
            ),
          if (detail.trailerUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openLink(context, detail.trailerUrl!),
              icon: const Icon(Icons.smart_display_outlined),
              label: const Text('Guarda il trailer'),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Gli episodi si guardano sulle piattaforme ufficiali: alcune sono '
            'gratuite, altre richiedono un abbonamento e la disponibilità '
            'cambia da paese a paese.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Etichette dei link: "YouTube", "YouTube 2"… se lo stesso sito compare
/// più volte (es. canali di paesi diversi).
List<(StreamingLink, String)> _labelled(List<StreamingLink> links) {
  final total = <String, int>{};
  for (final l in links) {
    total[l.site] = (total[l.site] ?? 0) + 1;
  }
  final seen = <String, int>{};
  return [
    for (final l in links)
      (
        l,
        [
          l.site,
          if (total[l.site]! > 1) '${seen[l.site] = (seen[l.site] ?? 0) + 1}',
          if (l.language != null) '(${l.language})',
        ].join(' '),
      ),
  ];
}

class _OfficialEpisodeTile extends StatelessWidget {
  const _OfficialEpisodeTile({required this.episode});

  final OfficialEpisode episode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openLink(context, episode.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 120,
                height: 68,
                child: AnimeCover(url: episode.thumbnail),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Su ${episode.site}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
