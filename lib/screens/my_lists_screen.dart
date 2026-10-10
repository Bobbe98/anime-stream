import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/anilist.dart';
import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/downloads.dart';
import '../theme.dart';
import '../widgets/anime_cover.dart';
import '../widgets/cards.dart';
import 'anime_screen.dart';

class MyListsScreen extends StatelessWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Le mie liste',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'La mia lista'),
              Tab(text: 'Cronologia'),
              Tab(text: 'Download'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_Watchlist(), _History(), _Downloads()],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Watchlist extends StatelessWidget {
  const _Watchlist();

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 160,
    mainAxisSpacing: 16,
    crossAxisSpacing: 12,
    childAspectRatio: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.watchlist;
    final real = state.realList;
    if (list.isEmpty && real.isEmpty) {
      return const _Empty(
        icon: Icons.bookmark_border,
        text:
            'La tua lista è vuota.\nTocca il segnalibro su una serie o su un '
            'anime per salvarlo qui.',
      );
    }
    return CustomScrollView(
      slivers: [
        if (real.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Anime salvati')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: _grid,
              itemCount: real.length,
              itemBuilder: (context, i) {
                final saved = real[i];
                final summary = AnimeSummary(
                  id: saved.id,
                  title: saved.title,
                  cover: saved.cover,
                  coverLarge: saved.cover,
                );
                return AnimeCard(
                  anime: summary,
                  onTap: () => openAnime(context, summary),
                );
              },
            ),
          ),
        ],
        if (list.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Serie AniWave')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid.builder(
              gridDelegate: _grid,
              itemCount: list.length,
              itemBuilder: (_, i) => PosterCard(series: list[i], width: null),
            ),
          ),
        ],
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history;
    if (history.isEmpty) {
      return const _Empty(
        icon: Icons.history,
        text: 'Non hai ancora guardato nulla.\nGli episodi che guardi compariranno qui.',
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Cancellare la cronologia?'),
                  content: const Text(
                    'Verranno azzerati anche i progressi degli episodi.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Annulla'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: const Text('Cancella'),
                    ),
                  ],
                ),
              );
              if (ok ?? false) state.clearHistory();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Cancella tutto'),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final e = history[i];
              final s = Catalog.byId(e.seriesId);
              return InkWell(
                onTap: () => playEpisode(context, e),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: EpisodeThumb(episode: e)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${e.code} - ${e.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.isWatched(e)
                                ? 'Visto'
                                : 'Restano ${formatDuration(e.duration - state.progressOf(e))}',
                            style: const TextStyle(
                              color: AppColors.accent2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Downloads extends StatelessWidget {
  const _Downloads();

  @override
  Widget build(BuildContext context) {
    if (!DownloadManager.supported) {
      return const _Empty(
        icon: Icons.download_outlined,
        text: 'I download sono disponibili nell\'app per Android e iOS.',
      );
    }
    final downloads = context.watch<DownloadManager>();
    final pending = downloads.pending;
    final done = downloads.completed;
    if (pending.isEmpty && done.isEmpty) {
      return const _Empty(
        icon: Icons.download_outlined,
        text:
            'Nessun episodio scaricato.\nTocca l\'icona di download su un '
            'episodio per guardarlo anche senza connessione.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const Icon(Icons.sd_storage_outlined, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${done.length} episodi · ${formatBytes(downloads.totalBytes)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'In corso',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          for (final item in pending) _DownloadTile(item: item),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Disponibili offline',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          for (final item in done) _DownloadTile(item: item),
        ],
      ],
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final e = item.episode;
    if (e == null) return const SizedBox.shrink();
    final s = Catalog.byId(e.seriesId);
    final downloads = context.read<DownloadManager>();
    final String status;
    switch (item.status) {
      case DownloadStatus.queued:
        status = 'In coda';
      case DownloadStatus.downloading:
        final p = item.progress;
        status = p == null
            ? formatBytes(item.received)
            : '${(p * 100).round()}% · ${formatBytes(item.received)}'
                  ' di ${formatBytes(item.total!)}';
      case DownloadStatus.failed:
        status = 'Non riuscito: tocca per riprovare';
      case DownloadStatus.done:
        status = formatBytes(item.received);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: switch (item.status) {
          DownloadStatus.done => () => playEpisode(context, e),
          DownloadStatus.failed => () => downloads.retry(e.id),
          _ => null,
        },
        child: Row(
          children: [
            SizedBox(width: 120, child: EpisodeThumb(episode: e)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${e.code} - ${e.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if (item.status == DownloadStatus.downloading)
                    LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      color: AppColors.accent2,
                    ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.status == DownloadStatus.failed
                          ? Colors.redAccent
                          : AppColors.accent2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: item.status == DownloadStatus.done
                  ? 'Elimina download'
                  : 'Annulla download',
              icon: Icon(
                item.status == DownloadStatus.done
                    ? Icons.delete_outline
                    : Icons.close,
              ),
              onPressed: () => downloads.delete(e.id),
            ),
          ],
        ),
      ),
    );
  }
}
