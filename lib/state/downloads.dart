import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';

enum DownloadStatus { queued, downloading, done, failed }

class DownloadItem {
  DownloadItem(this.episodeId, {this.status = DownloadStatus.queued});

  final String episodeId;
  DownloadStatus status;
  int received = 0;
  int? total;
  String? path;
  String? error;

  /// 0..1, oppure `null` se il server non indica la dimensione.
  double? get progress =>
      (total == null || total == 0) ? null : (received / total!).clamp(0, 1);

  Episode? get episode => Catalog.episodeById(episodeId);
}

/// Scarica gli episodi sul dispositivo per vederli offline.
/// Massimo [maxParallel] download contemporanei, gli altri restano in coda.
class DownloadManager extends ChangeNotifier {
  DownloadManager(
    this._prefs, {
    http.Client Function()? clientFactory,
    Future<Directory> Function()? directory,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _directory = directory ?? _defaultDirectory {
    _load();
  }

  static const _key = 'aniwave_downloads_v1';
  static const maxParallel = 2;

  /// Sul web non c'è un file system dove salvare i video.
  static bool get supported => !kIsWeb;

  final SharedPreferences _prefs;
  final http.Client Function() _clientFactory;
  final Future<Directory> Function() _directory;

  final Map<String, DownloadItem> _items = {};
  final Map<String, StreamSubscription<List<int>>> _subs = {};
  final Map<String, IOSink> _sinks = {};
  final Map<String, http.Client> _clients = {};
  final Map<String, Completer<void>> _done = {};
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/downloads').create(recursive: true);
  }

  DownloadItem? itemOf(String episodeId) => _items[episodeId];

  bool isDownloaded(String episodeId) =>
      _items[episodeId]?.status == DownloadStatus.done;

  String? localPath(String episodeId) =>
      isDownloaded(episodeId) ? _items[episodeId]!.path : null;

  List<DownloadItem> get completed =>
      _items.values.where((i) => i.status == DownloadStatus.done).toList();

  List<DownloadItem> get pending =>
      _items.values.where((i) => i.status != DownloadStatus.done).toList();

  int get totalBytes => completed.fold(0, (sum, i) => sum + i.received);

  int get _active =>
      _items.values.where((i) => i.status == DownloadStatus.downloading).length;

  /// Mette in coda il download; non fa nulla se è già scaricato o in corso.
  void enqueue(Episode e) {
    final existing = _items[e.id];
    if (existing != null && existing.status != DownloadStatus.failed) return;
    _items[e.id] = DownloadItem(e.id);
    notifyListeners();
    _pump();
  }

  void retry(String episodeId) {
    final item = _items[episodeId];
    if (item?.status != DownloadStatus.failed) return;
    item!
      ..status = DownloadStatus.queued
      ..error = null
      ..received = 0;
    notifyListeners();
    _pump();
  }

  void _pump() {
    for (final item in _items.values.toList()) {
      if (_active >= maxParallel) return;
      if (item.status == DownloadStatus.queued) _start(item);
    }
  }

  Future<void> _start(DownloadItem item) async {
    final episode = item.episode;
    if (episode == null) {
      _items.remove(item.episodeId);
      return;
    }
    item.status = DownloadStatus.downloading;
    notifyListeners();

    final client = _clientFactory();
    _clients[item.episodeId] = client;
    try {
      final dir = await _directory();
      final file = File('${dir.path}/${episode.id}.mp4');
      final part = File('${file.path}.part');
      final response = await client.send(
        http.Request('GET', Uri.parse(episode.videoUrl)),
      );
      if (response.statusCode != 200) {
        throw HttpException('Errore del server (${response.statusCode})');
      }
      if (!_items.containsKey(item.episodeId)) return; // annullato
      item.total = response.contentLength;
      final sink = part.openWrite();
      _sinks[item.episodeId] = sink;
      final done = Completer<void>();
      _done[item.episodeId] = done;
      _subs[item.episodeId] = response.stream.listen(
        (chunk) {
          sink.add(chunk);
          item.received += chunk.length;
          _throttledNotify();
        },
        onError: (Object e) {
          if (!done.isCompleted) done.completeError(e);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      await done.future;
      await sink.close();
      await part.rename(file.path);
      item
        ..status = DownloadStatus.done
        ..path = file.path
        ..total = item.received;
      _persist();
    } catch (e) {
      try {
        await _sinks[item.episodeId]?.close();
      } catch (_) {}
      if (_items.containsKey(item.episodeId)) {
        item
          ..status = DownloadStatus.failed
          ..error = '$e';
      }
    } finally {
      _cleanup(item.episodeId);
      notifyListeners();
      _pump();
    }
  }

  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotify) > const Duration(milliseconds: 250)) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  void _cleanup(String id) {
    _done.remove(id);
    _subs.remove(id);
    _sinks.remove(id);
    _clients.remove(id)?.close();
  }

  /// Annulla un download in corso o in coda.
  Future<void> cancel(String episodeId) async {
    final item = _items.remove(episodeId);
    if (item == null) return;
    await _subs[episodeId]?.cancel();
    final done = _done[episodeId];
    if (done != null && !done.isCompleted) {
      done.completeError(StateError('annullato'));
    }
    _clients[episodeId]?.close();
    _cleanup(episodeId);
    try {
      final dir = await _directory();
      final part = File('${dir.path}/$episodeId.mp4.part');
      if (await part.exists()) await part.delete();
    } catch (_) {}
    notifyListeners();
    _pump();
  }

  /// Elimina un episodio scaricato (o annulla se è ancora in corso).
  Future<void> delete(String episodeId) async {
    final item = _items[episodeId];
    if (item == null) return;
    if (item.status != DownloadStatus.done) return cancel(episodeId);
    _items.remove(episodeId);
    final path = item.path;
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _persist();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    for (final id in _items.keys.toList()) {
      await delete(id);
    }
  }

  void _persist() {
    _prefs.setString(
      _key,
      jsonEncode([
        for (final i in completed)
          {'id': i.episodeId, 'path': i.path, 'bytes': i.received},
      ]),
    );
  }

  void _load() {
    if (!supported) return;
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      for (final entry in jsonDecode(raw) as List) {
        final map = entry as Map<String, dynamic>;
        final path = map['path'] as String?;
        // Se il file è stato rimosso (es. pulizia della memoria) lo dimentichiamo.
        if (path == null || !File(path).existsSync()) continue;
        _items[map['id'] as String] =
            DownloadItem(map['id'] as String, status: DownloadStatus.done)
              ..path = path
              ..received = (map['bytes'] as num?)?.toInt() ?? 0
              ..total = (map['bytes'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('AniWave: elenco download non valido, lo ignoro ($e)');
    }
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    for (final c in _clients.values) {
      c.close();
    }
    super.dispose();
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
