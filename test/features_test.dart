import 'dart:io';

import 'package:aniwave/data/catalog.dart';
import 'package:aniwave/data/subtitles.dart';
import 'package:aniwave/state/downloads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('serie concluse', () {
    test('ogni serie ha un giorno; concluse e in corso sono separate', () {
      for (final s in Catalog.all) {
        expect(s.weekday, isNotNull, reason: s.id);
        expect(s.isSimulcast, !s.finished, reason: s.id);
      }
      expect(Catalog.finishedSeries, isNotEmpty);
      expect(Catalog.finishedSeries.every((s) => s.finished), isTrue);
    });

    test('il filtro per giorno restituisce solo il tipo richiesto', () {
      var total = 0;
      for (var d = 1; d <= 7; d++) {
        final done = Catalog.onWeekday(d, finished: true);
        final airing = Catalog.onWeekday(d, finished: false);
        expect(done.every((s) => s.finished && s.weekday == d), isTrue);
        expect(airing.every((s) => !s.finished && s.weekday == d), isTrue);
        total += done.length + airing.length;
      }
      expect(total, Catalog.all.length);
    });
  });

  group('sottotitoli', () {
    final episode = Catalog.all.first.episodes.first;

    test('tutte le lingue hanno le battute', () {
      for (final l in Subtitles.languages) {
        final track = Subtitles.demo(episode, l.code, episode.duration);
        expect(track.captions.length, greaterThan(5), reason: l.code);
        expect(track.textAt(const Duration(seconds: 3)), contains('1'));
      }
      expect(Subtitles.languages.length, greaterThanOrEqualTo(25));
    });

    test('textAt trova il sottotitolo giusto o niente', () {
      final track = Subtitles.demo(episode, 'en', episode.duration);
      expect(
        track.textAt(const Duration(seconds: 13)),
        'The wind is changing.',
      );
      expect(track.textAt(const Duration(seconds: 9)), isNull);
    });

    test('le lingue da destra a sinistra sono indicate', () {
      expect(Subtitles.byCode('ar')!.rtl, isTrue);
      expect(Subtitles.byCode('ja')!.rtl, isFalse);
    });

    test('WebVTT: esporta e rilegge la stessa traccia', () {
      final track = Subtitles.demo(episode, 'ja', episode.duration);
      final parsed = Subtitles.parseWebVtt(
        track.language,
        Subtitles.toWebVtt(track),
      );
      expect(parsed.captions.length, track.captions.length);
      expect(parsed.captions[1].text, track.captions[1].text);
      expect(parsed.captions[1].start, track.captions[1].start);
    });
  });

  group('download', () {
    late Directory dir;
    final episode = Catalog.all.first.episodes.first;
    final bytes = List<int>.generate(5000, (i) => i % 256);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('aniwave_test');
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => dir.delete(recursive: true));

    MockClient okClient() => MockClient.streaming(
      (request, _) async => http.StreamedResponse(
        Stream.fromIterable([bytes.sublist(0, 2000), bytes.sublist(2000)]),
        200,
        contentLength: bytes.length,
      ),
    );

    Future<void> waitFor(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('scarica, salva sul disco e lo ricorda al riavvio', () async {
      final prefs = await SharedPreferences.getInstance();
      final m = DownloadManager(
        prefs,
        clientFactory: okClient,
        directory: () async => dir,
      );
      m.enqueue(episode);
      await waitFor(() => m.isDownloaded(episode.id));

      expect(m.isDownloaded(episode.id), isTrue);
      final path = m.localPath(episode.id)!;
      expect(await File(path).readAsBytes(), bytes);
      expect(m.totalBytes, bytes.length);

      final reloaded = DownloadManager(prefs, directory: () async => dir);
      expect(reloaded.isDownloaded(episode.id), isTrue);

      await reloaded.delete(episode.id);
      expect(File(path).existsSync(), isFalse);
      expect(reloaded.isDownloaded(episode.id), isFalse);
    });

    test('un errore del server segna il download come fallito', () async {
      final prefs = await SharedPreferences.getInstance();
      final m = DownloadManager(
        prefs,
        clientFactory: () => MockClient((_) async => http.Response('', 404)),
        directory: () async => dir,
      );
      m.enqueue(episode);
      await waitFor(
        () => m.itemOf(episode.id)?.status == DownloadStatus.failed,
      );
      expect(m.itemOf(episode.id)!.status, DownloadStatus.failed);
      expect(m.isDownloaded(episode.id), isFalse);
    });

    test('al massimo due download contemporanei', () async {
      final prefs = await SharedPreferences.getInstance();
      final m = DownloadManager(
        prefs,
        clientFactory: () => MockClient.streaming(
          (_, _) async => http.StreamedResponse(const Stream.empty(), 200),
        ),
        directory: () async => dir,
      );
      final eps = Catalog.byId('stelle-neo-kyoto').episodes.take(4);
      for (final e in eps) {
        m.enqueue(e);
      }
      final downloading = m.pending
          .where((i) => i.status == DownloadStatus.downloading)
          .length;
      expect(downloading, DownloadManager.maxParallel);
      await waitFor(() => m.completed.length == 4);
      expect(m.completed.length, 4);
    });
  });
}
