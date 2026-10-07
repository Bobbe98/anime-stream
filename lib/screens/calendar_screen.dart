import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/series_art.dart';

/// Cosa mostrare per ogni giorno della settimana.
enum CalendarFilter { airing, finished }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  static const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFilter _filter = CalendarFilter.airing;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final finished = _filter == CalendarFilter.finished;
    return DefaultTabController(
      length: 7,
      initialIndex: today - 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Calendario',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<CalendarFilter>(
                      segments: const [
                        ButtonSegment(
                          value: CalendarFilter.airing,
                          icon: Icon(Icons.live_tv),
                          label: Text('In corso'),
                        ),
                        ButtonSegment(
                          value: CalendarFilter.finished,
                          icon: Icon(Icons.check_circle_outline),
                          label: Text('Concluse'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (v) =>
                          setState(() => _filter = v.first),
                    ),
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (var i = 0; i < 7; i++)
                      Tab(
                        text: i + 1 == today
                            ? '${CalendarScreen.days[i]} • oggi'
                            : CalendarScreen.days[i],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            for (var d = 1; d <= 7; d++)
              _DayList(weekday: d, finished: finished),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.weekday, required this.finished});

  final int weekday;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final items = Catalog.onWeekday(weekday, finished: finished);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              finished
                  ? 'Nessuna serie conclusa in questo giorno'
                  : 'Nessuna uscita in questo giorno',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    final state = context.watch<AppState>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final s = items[i];
        final latest = s.episodes.last;
        final watched = s.episodes.where(state.isWatched).length;
        return InkWell(
          onTap: () => openSeries(context, s),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  s.airTime ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: finished ? AppColors.textMuted : AppColors.accent2,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SeriesArt(series: s, showTitle: false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      finished
                          ? 'Completa: ${s.seasons.length} '
                                '${s.seasons.length == 1 ? 'stagione' : 'stagioni'}, '
                                '${s.episodes.length} episodi'
                          : 'Ultimo: ${latest.code} - ${latest.title}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (finished && watched > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: watched / s.episodes.length,
                        minHeight: 3,
                        backgroundColor: Colors.white12,
                        color: AppColors.accent2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visti $watched di ${s.episodes.length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (finished)
                          const Tag('CONCLUSA', color: AppColors.surfaceHigh),
                        if (s.dubbed) const Tag('DUB'),
                        if (!finished && state.isLocked(latest))
                          const Tag(
                            'PREMIUM',
                            color: AppColors.premium,
                            dark: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: state.inWatchlist(s.id)
                    ? 'Rimuovi dalla lista'
                    : 'Aggiungi alla lista',
                onPressed: () => state.toggleWatchlist(s.id),
                icon: Icon(
                  state.inWatchlist(s.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
