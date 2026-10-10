import 'package:aniwave/data/anilist.dart';
import 'package:aniwave/main.dart';
import 'package:aniwave/state/app_state.dart';
import 'package:aniwave/state/downloads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_anilist.dart';

Future<void> _pumpApp(WidgetTester tester, Size logicalSize) async {
  tester.view.physicalSize = logicalSize * 2.5;
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AniListClient>(create: (_) => fakeAniList()),
        ChangeNotifierProvider(create: (_) => AppState(prefs)),
        ChangeNotifierProvider(create: (_) => DownloadManager(prefs)),
      ],
      child: const AniWaveApp(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('home, navigazione e scheda serie', (tester) async {
    await _pumpApp(tester, const Size(432, 960));

    expect(find.text('AniWave'), findsOneWidget);
    expect(find.text('Simulcast di stagione'), findsOneWidget);

    // Apre la prima serie del carosello e la aggiunge alla lista.
    await tester.tap(find.text('La Lama del Crepuscolo').first);
    await tester.pumpAndSettle();
    expect(find.text('Episodi'), findsOneWidget);
    expect(find.byTooltip('Scarica'), findsWidgets);
    await tester.tap(find.byTooltip('Aggiungi alla lista'));
    await tester.pump();
    expect(find.byTooltip('Rimuovi dalla lista'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // La serie compare nella tab Liste, che ha anche la sezione Download.
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('La Lama del Crepuscolo'), findsWidgets);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nessun episodio scaricato'), findsOneWidget);

    // Ricerca e filtro "Concluse" dalla tab Sfoglia.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'volpe');
    await tester.pump();
    expect(find.text('1 titoli'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Concluse'));
    await tester.pump();
    expect(find.text('5 titoli'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // Anime reali (AniList finto): uscite, scheda e "Dove guardarlo".
    await tester.tap(find.text('Anime'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Oggi'), findsOneWidget);
    expect(find.text('Test Blade'), findsWidgets);
    await tester.tap(find.text('Test Blade').first);
    await tester.pumpAndSettle();
    expect(find.text('Dove guardarlo'), findsOneWidget);
    expect(find.text('Crunchyroll'), findsOneWidget);
    expect(find.text('Guarda il trailer'), findsOneWidget);
    await tester.tap(find.byTooltip('Aggiungi alla lista'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Di tendenza'));
    await tester.pumpAndSettle();
    expect(find.text('Test Garden'), findsWidgets);

    // Calendario: passa da "In corso" a "Concluse" e sceglie il sabato.
    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    final saturday = find.textContaining('Sab');
    await tester.ensureVisible(saturday);
    await tester.pumpAndSettle();
    await tester.tap(saturday);
    await tester.pumpAndSettle();
    expect(find.text('La Lama del Crepuscolo'), findsOneWidget);
    await tester.tap(find.text('Concluse').last);
    await tester.pumpAndSettle();
    expect(find.text('Ultimo Set'), findsOneWidget);
    expect(find.text('La Lama del Crepuscolo'), findsNothing);

    // Account: impostazioni dei sottotitoli.
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Lingua dei sottotitoli'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
  });

  testWidgets('schermo stretto (360 px) senza testo che esce', (tester) async {
    await _pumpApp(tester, const Size(360, 740));
    await tester.tap(find.text('La Lama del Crepuscolo').first);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    for (final tab in ['Anime', 'Calendario', 'Liste', 'Account']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
  });
}
