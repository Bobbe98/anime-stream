import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/anilist.dart';
import '../theme.dart';
import '../widgets/anime_cover.dart';
import 'anime_detail_screen.dart';

void openAnime(BuildContext context, AnimeSummary anime) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => AnimeDetailScreen(summary: anime)));
}

/// Catalogo reale degli anime (dati AniList).
class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    const categories = AnimeCategory.values;
    return DefaultTabController(
      length: categories.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _search,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cerca tra tutti gli anime…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Cancella',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          bottom: _query.isNotEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(text: 'Uscite'),
                    for (final c in categories)
                      Tab(
                        text: c == AnimeCategory.season
                            ? _seasonTab()
                            : c.label,
                      ),
                  ],
                ),
        ),
        body: _query.isNotEmpty
            ? _AnimeGrid(
                key: ValueKey('search:$_query'),
                category: AnimeCategory.trending,
                search: _query,
              )
            : TabBarView(
                children: [
                  const _ScheduleView(),
                  for (final c in categories) _AnimeGrid(category: c),
                ],
              ),
      ),
    );
  }

  String _seasonTab() {
    final (season, year) = currentSeason(DateTime.now());
    return seasonLabel(season, year);
  }
}

/// Griglia paginata (scorrendo in fondo carica la pagina successiva).
class _AnimeGrid extends StatefulWidget {
  const _AnimeGrid({super.key, required this.category, this.search});

  final AnimeCategory category;
  final String? search;

  @override
  State<_AnimeGrid> createState() => _AnimeGridState();
}

class _AnimeGridState extends State<_AnimeGrid>
    with AutomaticKeepAliveClientMixin {
  final _items = <AnimeSummary>[];
  final _seen = <int>{};
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<AniListClient>().browse(
        category: widget.category,
        page: _page + 1,
        search: widget.search,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _hasMore = page.hasNextPage;
        for (final a in page.items) {
          if (_seen.add(a.id)) _items.add(a);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty) {
      if (_error != null) {
        return _ErrorState(error: _error!, onRetry: _loadMore);
      }
      if (_loading) return const Center(child: CircularProgressIndicator());
      return const Center(
        child: Text(
          'Nessun anime trovato.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 600) _loadMore();
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final a = _items[i];
                return AnimeCard(
                  anime: a,
                  badge: a.nextEpisode != null && a.nextAiringAt != null
                      ? 'Ep. ${a.nextEpisode} ${countdown(a.nextAiringAt!)}'
                      : null,
                  onTap: () => openAnime(context, a),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: _error != null
                    ? TextButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Errore: riprova'),
                      )
                    : _hasMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uscite dei prossimi 7 giorni, un tab per giorno.
class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView>
    with AutomaticKeepAliveClientMixin {
  static const _days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  late Future<List<AiringItem>> _future;
  late final DateTime _start;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day);
    _load();
  }

  void _load() {
    _future = context.read<AniListClient>().schedule(
      _start,
      _start.add(const Duration(days: 7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<AiringItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _ErrorState(
            error: snap.error!,
            onRetry: () => setState(_load),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final byDay = List.generate(7, (_) => <AiringItem>[]);
        for (final item in snap.data!) {
          final local = item.airingAt.toLocal();
          final day = DateTime(
            local.year,
            local.month,
            local.day,
          ).difference(_start).inDays;
          if (day >= 0 && day < 7) byDay[day].add(item);
        }
        return DefaultTabController(
          length: 7,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (var d = 0; d < 7; d++)
                    Tab(
                      text: d == 0
                          ? 'Oggi (${byDay[0].length})'
                          : '${_days[_start.add(Duration(days: d)).weekday - 1]} '
                                '${_start.add(Duration(days: d)).day} '
                                '(${byDay[d].length})',
                    ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final items in byDay) _DaySchedule(items: items),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({required this.items});

  final List<AiringItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nessuna uscita in questo giorno',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = items[i];
        final a = item.anime;
        final t = item.airingAt.toLocal();
        final time =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final aired = item.airingAt.isBefore(DateTime.now());
        return InkWell(
          onTap: () => openAnime(context, a),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: aired ? AppColors.textMuted : AppColors.accent2,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 64,
                  height: 92,
                  child: AnimeCover(url: a.cover, color: a.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Episodio ${item.episode}'
                      '${a.episodes != null ? ' di ${a.episodes}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      aired ? 'Uscito' : 'Esce ${countdown(item.airingAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: aired ? AppColors.textMuted : AppColors.accent2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              error is AniListException ? '$error' : 'Impossibile caricare il catalogo. Controlla la connessione.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
