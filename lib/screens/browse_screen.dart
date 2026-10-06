import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../theme.dart';
import '../widgets/cards.dart';

enum SortMode {
  popular('Popolarità'),
  newest('Più recenti'),
  rating('Valutazione'),
  alpha('A-Z');

  const SortMode(this.label);
  final String label;
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, this.standaloneSearch = false});

  /// Aperto dalla lente della home: tastiera subito attiva.
  final bool standaloneSearch;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _query = TextEditingController();
  String? _genre;
  SortMode _sort = SortMode.popular;
  bool _dubOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Series> get _results {
    var list = Catalog.search(_query.text);
    if (_genre != null) {
      list = list.where((s) => s.genres.contains(_genre)).toList();
    }
    if (_dubOnly) list = list.where((s) => s.dubbed).toList();
    switch (_sort) {
      case SortMode.popular:
        break; // search() restituisce già per popolarità
      case SortMode.newest:
        list.sort((a, b) => b.year.compareTo(a.year));
      case SortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortMode.alpha:
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.standaloneSearch,
        title: TextField(
          controller: _query,
          autofocus: widget.standaloneSearch,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cerca titoli, generi, studi…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Cancella',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_query.clear),
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
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final g in [null, ...Catalog.genres])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g ?? 'Tutti'),
                        selected: _genre == g,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _genre = g),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${results.length} titoli',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Solo DUB'),
                    selected: _dubOnly,
                    onSelected: (v) => setState(() => _dubOnly = v),
                  ),
                  PopupMenuButton<SortMode>(
                    tooltip: 'Ordina',
                    initialValue: _sort,
                    onSelected: (m) => setState(() => _sort = m),
                    itemBuilder: (_) => [
                      for (final m in SortMode.values)
                        PopupMenuItem(value: m, child: Text(m.label)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(Icons.sort, size: 18),
                          const SizedBox(width: 4),
                          Text(_sort.label),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Nessun risultato. Prova con un altro titolo o genere.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.5,
                ),
                itemCount: results.length,
                itemBuilder: (_, i) =>
                    PosterCard(series: results[i], width: null),
              ),
            ),
        ],
      ),
    );
  }
}
