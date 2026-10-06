import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';

class MyListsScreen extends StatelessWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            ],
          ),
        ),
        body: const TabBarView(children: [_Watchlist(), _History()]),
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

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().watchlist;
    if (list.isEmpty) {
      return const _Empty(
        icon: Icons.bookmark_border,
        text: 'La tua lista è vuota.\nTocca il segnalibro su una serie per salvarla qui.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.5,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => PosterCard(series: list[i], width: null),
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
