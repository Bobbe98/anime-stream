import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/series_art.dart';
import 'browse_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final continueWatching = context.watch<AppState>().continueWatching;
    final premium = context.select<AppState, bool>((s) => s.premium);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const AppLogo(),
            actions: [
              if (!premium)
                IconButton(
                  tooltip: 'Prova Premium',
                  onPressed: () => showPremiumSheet(context),
                  icon: const Icon(
                    Icons.workspace_premium,
                    color: AppColors.premium,
                  ),
                ),
              IconButton(
                tooltip: 'Cerca',
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BrowseScreen(standaloneSearch: true),
                  ),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: _HeroCarousel()),
          SliverList.list(
            children: [
              if (continueWatching.isNotEmpty) ...[
                const SectionHeader('Continua a guardare'),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: continueWatching.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        ContinueCard(episode: continueWatching[i]),
                  ),
                ),
              ],
              SeriesRow(
                title: 'Simulcast di stagione',
                subtitle: 'Nuovi episodi ogni settimana, poco dopo il Giappone',
                items: Catalog.simulcasts,
              ),
              SeriesRow(title: 'I più popolari', items: Catalog.popular),
              SeriesRow(title: 'Novità', items: Catalog.newest),
              SeriesRow(title: 'Doppiati in italiano', items: Catalog.dubbed),
              for (final g in const [
                'Azione',
                'Romantico',
                'Fantasy',
                'Commedia',
              ])
                SeriesRow(title: g, items: Catalog.byGenre(g)),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.waves, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ShaderMask(
            shaderCallback: AppColors.brandGradient.createShader,
            child: const Text(
              'AniWave',
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  late final List<Series> _items = Catalog.popular.take(5).toList();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _items.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 440,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _HeroItem(series: _items[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _items.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.accent : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroItem extends StatelessWidget {
  const _HeroItem({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final next = state.upNext(series);
    final inList = state.inWatchlist(series.id);
    return GestureDetector(
      onTap: () => openSeries(context, series),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SeriesArt(series: series, showTitle: false, wide: true),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg],
                stops: [0.4, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    if (series.isSimulcast)
                      const Tag('SIMULCAST', color: AppColors.accent2),
                    if (series.isNew) const Tag('NUOVO'),
                    Tag(series.ageRating, color: AppColors.surfaceHigh),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  series.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  series.genres.join(' • '),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  series.synopsis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => playEpisode(context, next),
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Guarda ${next.code}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => state.toggleWatchlist(series.id),
                      icon: Icon(inList ? Icons.check : Icons.add),
                      label: Text(inList ? 'In lista' : 'Lista'),
                    ),
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
