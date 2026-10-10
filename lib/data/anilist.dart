import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Catalogo reale degli anime da AniList (https://anilist.co), API pubblica.
/// L'app mostra schede, copertine e calendario; per vedere gli episodi
/// rimanda alle piattaforme ufficiali indicate da AniList.
class AniListClient {
  AniListClient({http.Client? client}) : _client = client ?? http.Client();

  static final _endpoint = Uri.parse('https://graphql.anilist.co');
  static const _timeout = Duration(seconds: 20);
  static const _cacheFor = Duration(minutes: 10);

  final http.Client _client;
  final Map<String, (DateTime, Object)> _cache = {};

  static const _card = '''
fragment card on Media {
  id
  title { romaji english native }
  coverImage { large extraLarge color }
  format status episodes season seasonYear averageScore genres isAdult
  nextAiringEpisode { episode airingAt }
}''';

  Future<Map<String, dynamic>> _query(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final key = jsonEncode([query, variables]);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.$1) < _cacheFor) {
      return cached.$2 as Map<String, dynamic>;
    }
    final response = await _client
        .post(
          _endpoint,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'query': query, 'variables': variables}),
        )
        .timeout(_timeout);
    if (response.statusCode == 429) {
      throw const AniListException(
        'Troppe richieste ad AniList: riprova tra un minuto.',
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body is! Map || body['data'] == null) {
      throw AniListException('AniList non risponde (${response.statusCode}).');
    }
    final data = body['data'] as Map<String, dynamic>;
    _cache[key] = (DateTime.now(), data);
    return data;
  }

  /// Una pagina di anime: per tendenza, stagione, conclusi o ricerca.
  Future<AnimePage> browse({
    required AnimeCategory category,
    int page = 1,
    String? search,
  }) async {
    final season = currentSeason(DateTime.now());
    final vars = <String, dynamic>{
      'page': page,
      'sort': [category.sort],
      'status': category.status,
      'season': category == AnimeCategory.season ? season.$1 : null,
      'seasonYear': category == AnimeCategory.season ? season.$2 : null,
      'search': (search == null || search.trim().isEmpty)
          ? null
          : search.trim(),
    };
    if (vars['search'] != null) vars['sort'] = ['SEARCH_MATCH'];
    final data = await _query('''
query (\$page: Int, \$sort: [MediaSort], \$status: MediaStatus,
       \$season: MediaSeason, \$seasonYear: Int, \$search: String) {
  Page(page: \$page, perPage: 30) {
    pageInfo { hasNextPage }
    media(type: ANIME, sort: \$sort, status: \$status, season: \$season,
          seasonYear: \$seasonYear, search: \$search, isAdult: false) { ...card }
  }
}
$_card''', vars);
    final p = data['Page'] as Map<String, dynamic>;
    return AnimePage([
      for (final m in p['media'] as List)
        AnimeSummary.fromJson(m as Map<String, dynamic>),
    ], hasNextPage: (p['pageInfo'] as Map)['hasNextPage'] == true);
  }

  /// Episodi in uscita tra [from] e [to], in ordine di orario.
  Future<List<AiringItem>> schedule(DateTime from, DateTime to) async {
    final items = <AiringItem>[];
    for (var page = 1; page <= 8; page++) {
      final data = await _query(
        '''
query (\$page: Int, \$from: Int, \$to: Int) {
  Page(page: \$page, perPage: 50) {
    pageInfo { hasNextPage }
    airingSchedules(airingAt_greater: \$from, airingAt_lesser: \$to, sort: TIME) {
      episode airingAt media { ...card }
    }
  }
}
$_card''',
        {
          'page': page,
          'from': from.millisecondsSinceEpoch ~/ 1000,
          'to': to.millisecondsSinceEpoch ~/ 1000,
        },
      );
      final p = data['Page'] as Map<String, dynamic>;
      for (final s in p['airingSchedules'] as List) {
        final item = AiringItem.fromJson(s as Map<String, dynamic>);
        if (!item.anime.isAdult) items.add(item);
      }
      if ((p['pageInfo'] as Map)['hasNextPage'] != true) break;
    }
    return items;
  }

  Future<AnimeDetail> detail(int id) async {
    final data = await _query(
      '''
query (\$id: Int) {
  Media(id: \$id) {
    ...card
    bannerImage
    description(asHtml: false)
    duration
    studios(isMain: true) { nodes { name } }
    startDate { year month day }
    trailer { id site }
    externalLinks { site url type language }
    streamingEpisodes { title thumbnail url site }
  }
}
$_card''',
      {'id': id},
    );
    return AnimeDetail.fromJson(data['Media'] as Map<String, dynamic>);
  }

  void close() => _client.close();
}

class AniListException implements Exception {
  const AniListException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum AnimeCategory {
  trending('Di tendenza', 'TRENDING_DESC', null),
  season('Stagione', 'POPULARITY_DESC', null),
  airing('In corso', 'POPULARITY_DESC', 'RELEASING'),
  upcoming('In arrivo', 'POPULARITY_DESC', 'NOT_YET_RELEASED'),
  finished('Concluse', 'SCORE_DESC', 'FINISHED');

  const AnimeCategory(this.label, this.sort, this.status);
  final String label;
  final String sort;
  final String? status;
}

/// Stagione anime corrente (WINTER/SPRING/SUMMER/FALL) e anno.
(String, int) currentSeason(DateTime now) {
  const seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  return (seasons[(now.month - 1) ~/ 3], now.year);
}

String seasonLabel(String? season, int? year) {
  const names = {
    'WINTER': 'Inverno',
    'SPRING': 'Primavera',
    'SUMMER': 'Estate',
    'FALL': 'Autunno',
  };
  if (season == null && year == null) return '';
  return [names[season] ?? '', if (year != null) '$year'].join(' ').trim();
}

String statusLabel(String? status) => switch (status) {
  'RELEASING' => 'In corso',
  'FINISHED' => 'Conclusa',
  'NOT_YET_RELEASED' => 'In arrivo',
  'CANCELLED' => 'Cancellata',
  'HIATUS' => 'In pausa',
  _ => '',
};

String formatLabel(String? format) => switch (format) {
  'TV' => 'Serie TV',
  'TV_SHORT' => 'Corto TV',
  'MOVIE' => 'Film',
  'SPECIAL' => 'Speciale',
  'OVA' => 'OVA',
  'ONA' => 'ONA',
  'MUSIC' => 'Musicale',
  _ => format ?? '',
};

Color? _hex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

class AnimeSummary {
  const AnimeSummary({
    required this.id,
    required this.title,
    this.nativeTitle,
    this.cover,
    this.coverLarge,
    this.color,
    this.format,
    this.status,
    this.episodes,
    this.season,
    this.seasonYear,
    this.score,
    this.genres = const [],
    this.isAdult = false,
    this.nextEpisode,
    this.nextAiringAt,
  });

  factory AnimeSummary.fromJson(Map<String, dynamic> j) {
    final t = (j['title'] as Map?) ?? const {};
    final c = (j['coverImage'] as Map?) ?? const {};
    final next = j['nextAiringEpisode'] as Map?;
    return AnimeSummary(
      id: j['id'] as int,
      title:
          (t['english'] as String?) ??
          (t['romaji'] as String?) ??
          'Senza titolo',
      nativeTitle:
          (t['english'] != null ? t['romaji'] : t['native']) as String?,
      cover: c['large'] as String?,
      coverLarge: (c['extraLarge'] ?? c['large']) as String?,
      color: _hex(c['color'] as String?),
      format: j['format'] as String?,
      status: j['status'] as String?,
      episodes: j['episodes'] as int?,
      season: j['season'] as String?,
      seasonYear: j['seasonYear'] as int?,
      score: j['averageScore'] as int?,
      genres: [for (final g in (j['genres'] as List? ?? const [])) g as String],
      isAdult: j['isAdult'] == true,
      nextEpisode: next?['episode'] as int?,
      nextAiringAt: next == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (next['airingAt'] as int) * 1000,
            ),
    );
  }

  final int id;
  final String title;
  final String? nativeTitle;
  final String? cover;
  final String? coverLarge;
  final Color? color;
  final String? format;
  final String? status;
  final int? episodes;
  final String? season;
  final int? seasonYear;

  /// Voto medio 0..100.
  final int? score;
  final List<String> genres;
  final bool isAdult;
  final int? nextEpisode;
  final DateTime? nextAiringAt;
}

class StreamingLink {
  const StreamingLink(this.site, this.url, this.language);
  final String site;
  final String url;
  final String? language;
}

class OfficialEpisode {
  const OfficialEpisode(this.title, this.url, this.site, this.thumbnail);
  final String title;
  final String url;
  final String site;
  final String? thumbnail;
}

class AnimeDetail {
  const AnimeDetail({
    required this.summary,
    this.banner,
    this.description,
    this.duration,
    this.studios = const [],
    this.startYear,
    this.trailerUrl,
    this.streaming = const [],
    this.officialEpisodes = const [],
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> j) {
    final trailer = j['trailer'] as Map?;
    String? trailerUrl;
    if (trailer != null && trailer['id'] != null) {
      trailerUrl = switch (trailer['site']) {
        'youtube' => 'https://www.youtube.com/watch?v=${trailer['id']}',
        'dailymotion' => 'https://www.dailymotion.com/video/${trailer['id']}',
        _ => null,
      };
    }
    return AnimeDetail(
      summary: AnimeSummary.fromJson(j),
      banner: j['bannerImage'] as String?,
      description: cleanDescription(j['description'] as String?),
      duration: j['duration'] as int?,
      studios: [
        for (final n in ((j['studios'] as Map?)?['nodes'] as List? ?? const []))
          (n as Map)['name'] as String,
      ],
      startYear: (j['startDate'] as Map?)?['year'] as int?,
      trailerUrl: trailerUrl,
      streaming: [
        for (final l in (j['externalLinks'] as List? ?? const []))
          if ((l as Map)['type'] == 'STREAMING' && l['url'] != null)
            StreamingLink(
              l['site'] as String,
              l['url'] as String,
              l['language'] as String?,
            ),
      ],
      officialEpisodes: [
        for (final e in (j['streamingEpisodes'] as List? ?? const []))
          if ((e as Map)['url'] != null)
            OfficialEpisode(
              (e['title'] as String?) ?? 'Episodio',
              e['url'] as String,
              (e['site'] as String?) ?? '',
              e['thumbnail'] as String?,
            ),
      ],
    );
  }

  final AnimeSummary summary;
  final String? banner;
  final String? description;
  final int? duration;
  final List<String> studios;
  final int? startYear;
  final String? trailerUrl;
  final List<StreamingLink> streaming;
  final List<OfficialEpisode> officialEpisodes;
}

class AiringItem {
  const AiringItem(this.anime, this.episode, this.airingAt);

  factory AiringItem.fromJson(Map<String, dynamic> j) => AiringItem(
    AnimeSummary.fromJson(j['media'] as Map<String, dynamic>),
    j['episode'] as int,
    DateTime.fromMillisecondsSinceEpoch((j['airingAt'] as int) * 1000),
  );

  final AnimeSummary anime;
  final int episode;
  final DateTime airingAt;
}

class AnimePage {
  const AnimePage(this.items, {required this.hasNextPage});
  final List<AnimeSummary> items;
  final bool hasNextPage;
}

/// Le descrizioni di AniList contengono qualche tag HTML: li togliamo.
String? cleanDescription(String? raw) {
  if (raw == null) return null;
  final text = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'")
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return text.isEmpty ? null : text;
}

/// "tra 2 g 4 h", "tra 35 min", "uscito".
String countdown(DateTime when, {DateTime? now}) {
  final d = when.difference(now ?? DateTime.now());
  if (d.isNegative) return 'uscito';
  if (d.inDays > 0) return 'tra ${d.inDays} g ${d.inHours % 24} h';
  if (d.inHours > 0) return 'tra ${d.inHours} h ${d.inMinutes % 60} min';
  return 'tra ${d.inMinutes.clamp(1, 59)} min';
}
