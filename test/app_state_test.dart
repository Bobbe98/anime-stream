import 'package:aniwave/data/catalog.dart';
import 'package:aniwave/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _newState() async {
  SharedPreferences.setMockInitialValues({});
  return AppState(await SharedPreferences.getInstance());
}

void main() {
  test('il catalogo ha id unici e almeno un episodio per serie', () {
    final ids = Catalog.all.map((s) => s.id).toSet();
    expect(ids.length, Catalog.all.length);
    for (final s in Catalog.all) {
      expect(s.episodes, isNotEmpty);
    }
  });

  test('la ricerca ignora maiuscole e accenti', () {
    expect(Catalog.search('NEO KYOTO').first.id, 'stelle-neo-kyoto');
    expect(Catalog.search('tasogare').first.id, 'lama-crepuscolo');
    expect(Catalog.search('xyz-nessun-titolo'), isEmpty);
  });

  test('lista: aggiungi e rimuovi', () async {
    final state = await _newState();
    state.toggleWatchlist('club-te');
    expect(state.inWatchlist('club-te'), isTrue);
    state.toggleWatchlist('club-te');
    expect(state.inWatchlist('club-te'), isFalse);
  });

  test('continua a guardare propone l\'episodio successivo', () async {
    final state = await _newState();
    final series = Catalog.byId('ultimo-set');
    final first = series.episodes[0];

    state.saveProgress(first, const Duration(minutes: 2));
    expect(state.continueWatching.single.id, first.id);
    expect(state.upNext(series).id, first.id);

    state.markWatched(first, true);
    expect(state.continueWatching.single.id, series.episodes[1].id);
    expect(state.upNext(series).id, series.episodes[1].id);
  });

  test(
    'gli episodi premium sono bloccati finché non si attiva Premium',
    () async {
      final state = await _newState();
      final locked = Catalog.byId('lama-crepuscolo').episodes.last;
      expect(locked.premium, isTrue);
      expect(state.isLocked(locked), isTrue);
      state.premium = true;
      expect(state.isLocked(locked), isFalse);
    },
  );

  test('lo stato viene salvato e ricaricato', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = AppState(prefs)
      ..toggleWatchlist('detective-kagerou')
      ..profileName = 'Roberto';
    final ep = Catalog.byId('detective-kagerou').episodes.first;
    a.saveProgress(ep, const Duration(minutes: 3));

    final b = AppState(prefs);
    expect(b.inWatchlist('detective-kagerou'), isTrue);
    expect(b.profileName, 'Roberto');
    expect(b.progressOf(ep), const Duration(minutes: 3));
  });
}
