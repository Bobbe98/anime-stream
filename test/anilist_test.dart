import 'package:aniwave/data/anilist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_anilist.dart';

void main() {
  test('legge una pagina del catalogo', () async {
    final page = await fakeAniList().browse(category: AnimeCategory.trending);
    expect(page.items.map((a) => a.title), ['Test Blade', 'Test Garden']);
    expect(page.items.first.score, 81);
    expect(page.items.first.nextEpisode, 4);
    expect(page.hasNextPage, isFalse);
  });

  test('scheda: solo i link STREAMING, trailer e testo pulito', () async {
    final d = await fakeAniList().detail(1);
    expect(d.streaming.map((l) => l.site), ['Crunchyroll']);
    expect(d.trailerUrl, 'https://www.youtube.com/watch?v=abc123');
    expect(d.description, 'A made-up story.\n\nSecond line.');
    expect(d.studios, ['Studio Test']);
    expect(d.officialEpisodes.single.url, 'https://example.com/ep1');
  });

  test('calendario delle uscite', () async {
    final now = DateTime.now();
    final items = await fakeAniList().schedule(
      now,
      now.add(const Duration(days: 7)),
    );
    expect(items.single.episode, 4);
    expect(items.single.anime.title, 'Test Blade');
  });

  test('errore 429 diventa un messaggio chiaro', () async {
    expect(
      () => fakeAniList(status: 429).browse(category: AnimeCategory.trending),
      throwsA(isA<AniListException>()),
    );
  });

  test('stagione corrente, etichette e conto alla rovescia', () {
    expect(currentSeason(DateTime(2026, 10, 10)), ('FALL', 2026));
    expect(currentSeason(DateTime(2026, 2, 1)), ('WINTER', 2026));
    expect(seasonLabel('FALL', 2026), 'Autunno 2026');
    final now = DateTime(2026, 1, 1, 12);
    expect(countdown(DateTime(2026, 1, 3, 16), now: now), 'tra 2 g 4 h');
    expect(countdown(DateTime(2026, 1, 1, 12, 35), now: now), 'tra 35 min');
    expect(countdown(DateTime(2026, 1, 1, 11), now: now), 'uscito');
  });
}
