import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';

/// Stato dell'utente: lista, progressi, cronologia e impostazioni.
/// Tutto viene salvato in locale con SharedPreferences.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  static const _key = 'aniwave_state_v1';
  static const watchedThreshold = 0.9;
  static const _maxHistory = 100;

  final SharedPreferences _prefs;

  final Set<String> _watchlist = {};
  final Map<String, int> _progress = {};
  final List<String> _history = [];
  bool _premium = false;
  bool _autoplay = true;
  String _profileName = 'Otaku';
  int _avatar = 0;

  bool get premium => _premium;
  bool get autoplay => _autoplay;
  String get profileName => _profileName;
  int get avatar => _avatar;

  List<Series> get watchlist =>
      Catalog.all.where((s) => _watchlist.contains(s.id)).toList();

  List<Episode> get history =>
      _history.map(Catalog.episodeById).whereType<Episode>().toList();

  bool inWatchlist(String seriesId) => _watchlist.contains(seriesId);

  void toggleWatchlist(String seriesId) {
    if (!_watchlist.remove(seriesId)) _watchlist.add(seriesId);
    _commit();
  }

  bool isLocked(Episode e) => e.premium && !_premium;

  Duration progressOf(Episode e) => Duration(seconds: _progress[e.id] ?? 0);

  double fractionOf(Episode e) {
    final total = e.duration.inSeconds;
    if (total == 0) return 0;
    return ((_progress[e.id] ?? 0) / total).clamp(0.0, 1.0);
  }

  bool isWatched(Episode e) => fractionOf(e) >= watchedThreshold;

  /// Punto da cui riprendere la riproduzione (zero se già visto).
  Duration resumePositionOf(Episode e) =>
      isWatched(e) ? Duration.zero : progressOf(e);

  /// [deferNotify] serve quando si salva da un `dispose`, dove non si
  /// possono ricostruire altri widget in modo sincrono.
  void saveProgress(
    Episode e,
    Duration position, {
    Duration? total,
    bool deferNotify = false,
  }) {
    var seconds = position.inSeconds;
    // Se il video reale dura diversamente da quanto indicato a catalogo,
    // riportiamo la posizione sulla durata di catalogo.
    if (total != null && total.inSeconds > 0) {
      seconds = (position.inSeconds / total.inSeconds * e.duration.inSeconds)
          .round();
    }
    _progress[e.id] = seconds;
    _history
      ..remove(e.id)
      ..insert(0, e.id);
    if (_history.length > _maxHistory) {
      _history.removeRange(_maxHistory, _history.length);
    }
    _commit(deferNotify: deferNotify);
  }

  void markWatched(Episode e, bool watched) {
    if (watched) {
      _progress[e.id] = e.duration.inSeconds;
      _history
        ..remove(e.id)
        ..insert(0, e.id);
    } else {
      _progress.remove(e.id);
    }
    _commit();
  }

  void clearHistory() {
    _history.clear();
    _progress.clear();
    _commit();
  }

  Episode? episodeAfter(Episode e) {
    final eps = Catalog.byId(e.seriesId).episodes;
    final i = eps.indexWhere((x) => x.id == e.id);
    return (i >= 0 && i + 1 < eps.length) ? eps[i + 1] : null;
  }

  /// L'episodio da proporre per una serie: quello in corso, il successivo
  /// all'ultimo visto, oppure il primo.
  Episode upNext(Series s) {
    for (final id in _history) {
      final e = Catalog.episodeById(id);
      if (e == null || e.seriesId != s.id) continue;
      if (!isWatched(e)) return e;
      return episodeAfter(e) ?? e;
    }
    return s.episodes.first;
  }

  bool hasStarted(Series s) =>
      _history.any((id) => Catalog.episodeById(id)?.seriesId == s.id);

  /// Una voce per serie, ordinate dalla più recente.
  List<Episode> get continueWatching {
    final seen = <String>{};
    final result = <Episode>[];
    for (final id in _history) {
      final e = Catalog.episodeById(id);
      if (e == null || !seen.add(e.seriesId)) continue;
      if (!isWatched(e)) {
        result.add(e);
      } else {
        final next = episodeAfter(e);
        if (next != null && !isWatched(next)) result.add(next);
      }
    }
    return result;
  }

  set premium(bool value) {
    _premium = value;
    _commit();
  }

  set autoplay(bool value) {
    _autoplay = value;
    _commit();
  }

  set profileName(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    _profileName = v;
    _commit();
  }

  set avatar(int value) {
    _avatar = value;
    _commit();
  }

  void _commit({bool deferNotify = false}) {
    if (deferNotify) {
      Future.microtask(notifyListeners);
    } else {
      notifyListeners();
    }
    _prefs.setString(
      _key,
      jsonEncode({
        'watchlist': _watchlist.toList(),
        'progress': _progress,
        'history': _history,
        'premium': _premium,
        'autoplay': _autoplay,
        'profileName': _profileName,
        'avatar': _avatar,
      }),
    );
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _watchlist.addAll((data['watchlist'] as List? ?? []).cast<String>());
      _progress.addAll(
        (data['progress'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ),
      );
      _history.addAll((data['history'] as List? ?? []).cast<String>());
      _premium = data['premium'] as bool? ?? false;
      _autoplay = data['autoplay'] as bool? ?? true;
      _profileName = data['profileName'] as String? ?? 'Otaku';
      _avatar = data['avatar'] as int? ?? 0;
    } catch (e) {
      debugPrint('AniWave: stato salvato non valido, lo ignoro ($e)');
    }
  }
}
