import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/series_art.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static const _days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return DefaultTabController(
      length: 7,
      initialIndex: today - 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Calendario simulcast',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (var i = 0; i < 7; i++)
                Tab(text: i + 1 == today ? '${_days[i]} • oggi' : _days[i]),
            ],
          ),
        ),
        body: TabBarView(
          children: [for (var d = 1; d <= 7; d++) _DayList(weekday: d)],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.weekday});

  final int weekday;

  @override
  Widget build(BuildContext context) {
    final items = Catalog.simulcastOn(weekday);
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text(
              'Nessuna uscita in questo giorno',
              style: TextStyle(color: AppColors.textMuted),
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
        return InkWell(
          onTap: () => openSeries(context, s),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  s.simulcastTime ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent2,
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
                      'Ultimo: ${latest.code} - ${latest.title}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (s.dubbed) const Tag('DUB'),
                        if (state.isLocked(latest))
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
