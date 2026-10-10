import 'dart:convert';

import 'package:aniwave/data/anilist.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Anime inventati per i test: nessuna chiamata di rete vera.
Map<String, dynamic> fakeMedia(int id, String title, {String? status}) => {
  'id': id,
  'title': {'romaji': '$title (romaji)', 'english': title, 'native': null},
  'coverImage': {'large': null, 'extraLarge': null, 'color': '#8b5cf6'},
  'format': 'TV',
  'status': status ?? 'RELEASING',
  'episodes': 12,
  'season': 'FALL',
  'seasonYear': 2026,
  'averageScore': 81,
  'genres': ['Action', 'Fantasy'],
  'isAdult': false,
  'nextAiringEpisode': {
    'episode': 4,
    'airingAt':
        DateTime.now().add(const Duration(hours: 5)).millisecondsSinceEpoch ~/
        1000,
  },
};

AniListClient fakeAniList({int status = 200}) {
  return AniListClient(
    client: MockClient((http.Request req) async {
      if (status != 200) return http.Response('{}', status);
      final query = (jsonDecode(req.body) as Map)['query'] as String;
      Object data;
      if (query.contains('airingSchedules')) {
        final soon = DateTime.now().add(const Duration(minutes: 30));
        data = {
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'airingSchedules': [
              {
                'episode': 4,
                'airingAt': soon.millisecondsSinceEpoch ~/ 1000,
                'media': fakeMedia(1, 'Test Blade'),
              },
            ],
          },
        };
      } else if (query.contains('Media(id:')) {
        data = {
          'Media': {
            ...fakeMedia(1, 'Test Blade'),
            'bannerImage': null,
            'description': 'A <i>made-up</i> story.<br><br>Second line.',
            'duration': 24,
            'studios': {
              'nodes': [
                {'name': 'Studio Test'},
              ],
            },
            'startDate': {'year': 2026, 'month': 10, 'day': 1},
            'trailer': {'id': 'abc123', 'site': 'youtube'},
            'externalLinks': [
              {
                'site': 'Crunchyroll',
                'url': 'https://example.com/a',
                'type': 'STREAMING',
                'language': null,
              },
              {
                'site': 'Twitter',
                'url': 'https://example.com/b',
                'type': 'SOCIAL',
                'language': null,
              },
            ],
            'streamingEpisodes': [
              {
                'title': 'Episode 1 - Made Up',
                'thumbnail': null,
                'url': 'https://example.com/ep1',
                'site': 'Crunchyroll',
              },
            ],
          },
        };
      } else {
        data = {
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'media': [
              fakeMedia(1, 'Test Blade'),
              fakeMedia(2, 'Test Garden', status: 'FINISHED'),
            ],
          },
        };
      }
      return http.Response(
        jsonEncode({'data': data}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}
