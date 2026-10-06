import 'package:aniwave/main.dart';
import 'package:aniwave/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home, navigazione e scheda serie', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(prefs),
        child: const AniWaveApp(),
      ),
    );
    await tester.pump();

    expect(find.text('AniWave'), findsOneWidget);
    expect(find.text('Simulcast di stagione'), findsOneWidget);

    // Apre la prima serie del carosello e la aggiunge alla lista.
    await tester.tap(find.text('La Lama del Crepuscolo').first);
    await tester.pumpAndSettle();
    expect(find.text('Episodi'), findsOneWidget);
    await tester.tap(find.byTooltip('Aggiungi alla lista'));
    await tester.pump();
    expect(find.byTooltip('Rimuovi dalla lista'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // La serie compare nella tab Liste.
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('La Lama del Crepuscolo'), findsWidgets);

    // Ricerca dalla tab Sfoglia.
    await tester.tap(find.text('Sfoglia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'volpe');
    await tester.pump();
    expect(find.text('1 titoli'), findsOneWidget);

    // Calendario e account si aprono senza errori.
    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    expect(find.text('Calendario simulcast'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Riproduzione automatica'), findsOneWidget);
  });
}
