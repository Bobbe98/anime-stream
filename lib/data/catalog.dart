import 'package:flutter/material.dart';

/// Video demo: cortometraggi open della Blender Foundation (licenza
/// Creative Commons), ospitati da Internet Archive, con la loro durata reale.
const _archive = 'https://archive.org/download/';
const _videos = <(String, Duration)>[
  (
    'BigBuckBunny_124/Content/big_buck_bunny_720p_surround.mp4',
    Duration(minutes: 9, seconds: 56),
  ),
  ('ElephantsDream/ed_1024_512kb.mp4', Duration(minutes: 10, seconds: 53)),
  ('Sintel/sintel-2048-stereo_512kb.mp4', Duration(minutes: 14, seconds: 48)),
  (
    'Tears-of-Steel/tears_of_steel_720p.mp4',
    Duration(minutes: 12, seconds: 14),
  ),
];

const _synopsisTemplates = [
  'Una nuova minaccia mette alla prova i legami del gruppo: "{t}" segna una svolta che nessuno si aspettava.',
  'Tra segreti svelati e vecchi rancori, il protagonista deve scegliere da che parte stare. Episodio: "{t}".',
  'Un incontro inatteso cambia le carte in tavola. In "{t}" niente sarà più come prima.',
  'Allenamenti, risate e un finale col fiato sospeso: questo è "{t}".',
  'Il passato torna a bussare alla porta. "{t}" rivela un frammento della verità.',
];

int _stableHash(String s) =>
    s.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

class Episode {
  const Episode({
    required this.id,
    required this.seriesId,
    required this.season,
    required this.number,
    required this.title,
    required this.synopsis,
    required this.duration,
    required this.videoUrl,
    this.premium = false,
  });

  final String id;
  final String seriesId;
  final int season;
  final int number;
  final String title;
  final String synopsis;
  final Duration duration;
  final String videoUrl;
  final bool premium;

  String get code => 'S$season E$number';
}

class Series {
  Series({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.synopsis,
    required this.genres,
    required this.year,
    required this.rating,
    required this.popularity,
    required this.studio,
    required this.ageRating,
    required this.palette,
    required this.emblem,
    required List<List<String>> seasons,
    this.weekday,
    this.airTime,
    this.finished = false,
    this.dubbed = false,
    this.isNew = false,
    this.freeEpisodesPerSeason,
  }) : episodes = _buildEpisodes(id, seasons, freeEpisodesPerSeason);

  final String id;
  final String title;
  final String originalTitle;
  final String synopsis;
  final List<String> genres;
  final int year;
  final double rating;
  final int popularity;
  final String studio;
  final String ageRating;
  final List<Color> palette;
  final IconData emblem;

  /// Giorno di uscita settimanale (DateTime.monday..DateTime.sunday).
  /// Per le serie concluse è il giorno in cui andavano in onda.
  final int? weekday;
  final String? airTime;

  /// `true` se la serie ha trasmesso tutti gli episodi.
  final bool finished;
  final bool dubbed;
  final bool isNew;

  /// Episodi gratuiti per stagione; i successivi richiedono Premium.
  /// `null` = tutto gratis.
  final int? freeEpisodesPerSeason;
  final List<Episode> episodes;

  bool get isSimulcast => !finished && weekday != null;
  List<int> get seasons =>
      episodes.map((e) => e.season).toSet().toList()..sort();
  List<Episode> episodesOf(int season) =>
      episodes.where((e) => e.season == season).toList();

  static List<Episode> _buildEpisodes(
    String id,
    List<List<String>> seasons,
    int? free,
  ) {
    final result = <Episode>[];
    var index = 0;
    for (var s = 0; s < seasons.length; s++) {
      for (var n = 0; n < seasons[s].length; n++) {
        final title = seasons[s][n];
        final hash = _stableHash('$id-$index');
        final video = _videos[hash % _videos.length];
        result.add(
          Episode(
            id: '$id-s${s + 1}e${n + 1}',
            seriesId: id,
            season: s + 1,
            number: n + 1,
            title: title,
            synopsis: _synopsisTemplates[hash % _synopsisTemplates.length]
                .replaceAll('{t}', title),
            duration: video.$2,
            videoUrl: '$_archive${video.$1}',
            premium: free != null && n >= free,
          ),
        );
        index++;
      }
    }
    return result;
  }
}

class Catalog {
  static final List<Series> all = [
    Series(
      id: 'lama-crepuscolo',
      title: 'La Lama del Crepuscolo',
      originalTitle: 'Tasogare no Yaiba',
      synopsis:
          'Ren, ultimo erede di una scuola di spada dimenticata, deve proteggere '
          'la città di confine dagli spiriti che emergono al calar del sole. '
          'Ogni tramonto è una battaglia, ogni alba una promessa.',
      genres: ['Azione', 'Fantasy', 'Soprannaturale'],
      year: 2026,
      rating: 4.9,
      popularity: 98,
      studio: 'Studio Hoshikaze',
      ageRating: '14+',
      palette: [Color(0xFFF97316), Color(0xFF7C2D12), Color(0xFF1E1B4B)],
      emblem: Icons.flare,
      weekday: DateTime.saturday,
      airTime: '17:30',
      dubbed: true,
      isNew: true,
      freeEpisodesPerSeason: 3,
      seasons: [
        [
          'Il sole che muore',
          'La scuola senza allievi',
          'Patto di cenere',
          'Ombre sul ponte rosso',
          'Il maestro cieco',
          'Lama contro lama',
        ],
      ],
    ),
    Series(
      id: 'stelle-neo-kyoto',
      title: 'Stelle di Neo-Kyoto',
      originalTitle: 'Neo-Kyōto Stardust',
      synopsis:
          'Nel 2199 la metropoli galleggiante di Neo-Kyoto è difesa da piloti '
          'adolescenti a bordo di colossi meccanici. Aya entra nella squadra '
          'per scoprire cosa è successo a sua sorella.',
      genres: ['Sci-Fi', 'Mecha', 'Azione'],
      year: 2025,
      rating: 4.7,
      popularity: 91,
      studio: 'Orbit Works',
      ageRating: '12+',
      palette: [Color(0xFF06B6D4), Color(0xFF1E3A8A), Color(0xFF020617)],
      emblem: Icons.rocket_launch,
      dubbed: true,
      weekday: DateTime.thursday,
      airTime: '23:00',
      finished: true,
      seasons: [
        [
          'Decollo',
          'Sincronia al 40%',
          'Pioggia di metallo',
          'La sorella perduta',
          'Protocollo Aurora',
          'Cieli divisi',
          'Il nucleo',
          'Stelle che cadono',
        ],
        [
          'Ritorno in orbita',
          'Nuovi piloti',
          'Il traditore',
          'Neo-Kyoto brucia',
          'Ultima sincronia',
        ],
      ],
      freeEpisodesPerSeason: 4,
    ),
    Series(
      id: 'club-te',
      title: 'Il Club del Tè delle Sette',
      originalTitle: 'Shichiji no Ocha-bu',
      synopsis:
          'Cinque studentesse, un club scolastico in via di chiusura e una '
          'teiera magica che esaudisce un piccolo desiderio al giorno. '
          'Commedia leggera e piena di cuore.',
      genres: ['Slice of Life', 'Commedia'],
      year: 2024,
      rating: 4.5,
      popularity: 74,
      studio: 'Petal Animation',
      ageRating: 'T',
      palette: [Color(0xFFF9A8D4), Color(0xFFA78BFA), Color(0xFF312E81)],
      emblem: Icons.emoji_food_beverage,
      weekday: DateTime.tuesday,
      airTime: '22:30',
      finished: true,
      seasons: [
        [
          'Benvenute al club',
          'Il primo desiderio',
          'Biscotti e bugie',
          'Gita al mare',
          'Il festival culturale',
          'Arrivederci, teiera?',
        ],
      ],
    ),
    Series(
      id: 'volpe-bianca',
      title: 'Lo Spirito della Volpe Bianca',
      originalTitle: 'Shiroi Kitsune no Kami',
      synopsis:
          'Mio eredita un santuario di montagna e scopre di essere legata a '
          'uno spirito volpe brontolone. Insieme dovranno riportare la pace '
          'tra il mondo degli umani e quello degli yokai.',
      genres: ['Soprannaturale', 'Romantico', 'Fantasy'],
      year: 2025,
      rating: 4.8,
      popularity: 88,
      studio: 'Studio Hoshikaze',
      ageRating: '12+',
      palette: [Color(0xFFE2E8F0), Color(0xFF64748B), Color(0xFF0F172A)],
      emblem: Icons.pets,
      weekday: DateTime.wednesday,
      airTime: '16:00',
      isNew: true,
      freeEpisodesPerSeason: 3,
      seasons: [
        [
          'Il santuario dimenticato',
          'Nove code',
          'La festa delle lanterne',
          'Patto di sangue',
          'Il bosco degli yokai',
        ],
      ],
    ),
    Series(
      id: 'ultimo-set',
      title: 'Ultimo Set',
      originalTitle: 'Last Set!',
      synopsis:
          'La squadra di pallavolo del liceo Kaminari ha sei mesi per '
          'qualificarsi al torneo nazionale, o verrà sciolta. Il problema? '
          'Hanno solo cinque giocatori.',
      genres: ['Sport', 'Commedia', 'Drammatico'],
      year: 2024,
      rating: 4.6,
      popularity: 82,
      studio: 'Rally Studio',
      ageRating: 'T',
      palette: [Color(0xFFFACC15), Color(0xFFEA580C), Color(0xFF431407)],
      emblem: Icons.sports_volleyball,
      dubbed: true,
      weekday: DateTime.saturday,
      airTime: '18:30',
      finished: true,
      seasons: [
        [
          'Cinque più uno',
          'La schiacciata impossibile',
          'Amichevole contro i campioni',
          'Il libero',
          'Ritiro estivo',
          'Prima partita ufficiale',
          'Match point',
        ],
      ],
    ),
    Series(
      id: 'cuori-orbita',
      title: 'Cuori in Orbita',
      originalTitle: 'Kidō no Kokoro',
      synopsis:
          "Su una stazione spaziale scolastica, un'ingegnera geniale e un "
          'pilota distratto vengono costretti a lavorare insieme. '
          'Una storia d\'amore a gravità zero.',
      genres: ['Romantico', 'Sci-Fi', 'Commedia'],
      year: 2026,
      rating: 4.4,
      popularity: 79,
      studio: 'Orbit Works',
      ageRating: 'T',
      palette: [Color(0xFFFB7185), Color(0xFF8B5CF6), Color(0xFF1E1B4B)],
      emblem: Icons.favorite,
      weekday: DateTime.friday,
      airTime: '18:00',
      isNew: true,
      freeEpisodesPerSeason: 2,
      seasons: [
        [
          'Gravità zero',
          'Modulo B-7',
          'Un appuntamento sulla Luna',
          'Tempesta solare',
        ],
      ],
    ),
    Series(
      id: 'drago-ferro',
      title: 'Cronache del Drago di Ferro',
      originalTitle: 'Tetsuryū Senki',
      synopsis:
          'Un impiegato di Osaka si risveglia in un mondo fantasy nel corpo '
          'di un drago meccanico. Invece di conquistare il regno, decide di '
          'aprire un\'officina.',
      genres: ['Isekai', 'Fantasy', 'Commedia'],
      year: 2025,
      rating: 4.3,
      popularity: 86,
      studio: 'Gearbox Anime',
      ageRating: '12+',
      palette: [Color(0xFF94A3B8), Color(0xFF166534), Color(0xFF052E16)],
      emblem: Icons.precision_manufacturing,
      weekday: DateTime.tuesday,
      airTime: '17:00',
      dubbed: true,
      seasons: [
        [
          'Risveglio a vapore',
          'La prima riparazione',
          'Il cavaliere senza spada',
          'Officina del drago',
          'La gilda dei mercanti',
          'Fiamme e bulloni',
        ],
        [
          'Il regno del nord',
          'Ingranaggi antichi',
          'La principessa meccanica',
          'Guerra di brevetti',
        ],
      ],
      freeEpisodesPerSeason: 4,
    ),
    Series(
      id: 'detective-kagerou',
      title: 'Detective Kagerou',
      originalTitle: 'Tantei Kagerō',
      synopsis:
          'Un detective che vede gli ultimi dieci secondi di memoria delle '
          'vittime risolve casi impossibili nella Tokyo degli anni \'20. '
          'Ma chi indaga su di lui?',
      genres: ['Mistero', 'Thriller', 'Drammatico'],
      year: 2023,
      rating: 4.7,
      popularity: 77,
      studio: 'Noir Frame',
      ageRating: '16+',
      palette: [Color(0xFFB91C1C), Color(0xFF292524), Color(0xFF0C0A09)],
      emblem: Icons.search,
      weekday: DateTime.friday,
      airTime: '01:00',
      finished: true,
      seasons: [
        [
          'Dieci secondi',
          'Il tram delle 23:40',
          'La maschera di porcellana',
          'Ombre nel teatro',
          'Il cliente senza volto',
          'Memoria rubata',
          'Verità',
        ],
      ],
    ),
    Series(
      id: 'cucina-celeste',
      title: 'Cucina Celeste',
      originalTitle: 'Tenkū Kitchen',
      synopsis:
          'Il ristorante più piccolo del cielo serve una sola portata al '
          'giorno a divinità affamate. Il giovane cuoco Haru non può '
          'permettersi di sbagliare.',
      genres: ['Gourmet', 'Slice of Life', 'Fantasy'],
      year: 2026,
      rating: 4.5,
      popularity: 70,
      studio: 'Petal Animation',
      ageRating: 'T',
      palette: [Color(0xFF34D399), Color(0xFF0EA5E9), Color(0xFF082F49)],
      emblem: Icons.ramen_dining,
      weekday: DateTime.monday,
      airTime: '19:00',
      isNew: true,
      seasons: [
        [
          'Il brodo degli dei',
          'Onigiri di nuvola',
          'Il dio del tuono è a dieta',
          'Dessert di luna',
        ],
      ],
    ),
    Series(
      id: 'requiem-cyber',
      title: 'Requiem Cyber',
      originalTitle: 'Saibā Rekuiemu',
      synopsis:
          'In una città dove i ricordi si vendono al mercato nero, una '
          'hacker senza passato accetta il colpo che potrebbe restituirle '
          'la propria identità.',
      genres: ['Sci-Fi', 'Thriller', 'Azione'],
      year: 2024,
      rating: 4.6,
      popularity: 84,
      studio: 'Noir Frame',
      ageRating: '16+',
      palette: [Color(0xFF22D3EE), Color(0xFFD946EF), Color(0xFF0F0A1E)],
      emblem: Icons.memory,
      weekday: DateTime.thursday,
      airTime: '21:00',
      dubbed: true,
      freeEpisodesPerSeason: 3,
      seasons: [
        [
          'Boot',
          'Mercato dei ricordi',
          'Firewall',
          'Glitch',
          'Root access',
          'Shutdown',
        ],
      ],
    ),
    Series(
      id: 'accademia-elementi',
      title: 'Accademia degli Elementi',
      originalTitle: 'Gensō Gakuen',
      synopsis:
          'All\'accademia di magia elementale, Kai è l\'unico studente senza '
          'un elemento. Ma forse la sua "assenza" è il potere più raro di tutti.',
      genres: ['Fantasy', 'Azione', 'Scolastico'],
      year: 2025,
      rating: 4.4,
      popularity: 89,
      studio: 'Gearbox Anime',
      ageRating: '12+',
      palette: [Color(0xFF60A5FA), Color(0xFFF43F5E), Color(0xFF172554)],
      emblem: Icons.auto_awesome,
      weekday: DateTime.sunday,
      airTime: '15:30',
      dubbed: true,
      freeEpisodesPerSeason: 3,
      seasons: [
        [
          'L\'esame d\'ingresso',
          'Classe Zero',
          'Duello di fuoco',
          'Il torneo dei quattro venti',
          'Vuoto',
        ],
      ],
    ),
    Series(
      id: 'onde-estive',
      title: 'Onde d\'Estate',
      originalTitle: 'Natsu no Nami',
      synopsis:
          "Un'estate in un paesino di mare, una tavola da surf ritrovata e "
          'un gruppo di amici che sa che dopo settembre nulla sarà uguale.',
      genres: ['Drammatico', 'Romantico', 'Slice of Life'],
      year: 2023,
      rating: 4.8,
      popularity: 68,
      studio: 'Rally Studio',
      ageRating: 'T',
      palette: [Color(0xFF38BDF8), Color(0xFFFDE68A), Color(0xFF0C4A6E)],
      emblem: Icons.surfing,
      weekday: DateTime.sunday,
      airTime: '17:00',
      finished: true,
      seasons: [
        [
          'La tavola blu',
          'Fuochi d\'artificio',
          'Il faro',
          'Tempesta di agosto',
          'Settembre',
        ],
      ],
    ),
  ];

  static Series byId(String id) => all.firstWhere((s) => s.id == id);

  static Episode? episodeById(String id) {
    for (final s in all) {
      for (final e in s.episodes) {
        if (e.id == id) return e;
      }
    }
    return null;
  }

  static List<String> get genres {
    final set = <String>{for (final s in all) ...s.genres};
    return set.toList()..sort();
  }

  static List<Series> get popular =>
      [...all]..sort((a, b) => b.popularity.compareTo(a.popularity));

  static List<Series> get newest => [...all]
    ..sort((a, b) {
      if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
      return b.year.compareTo(a.year);
    });

  static List<Series> get simulcasts =>
      all.where((s) => s.isSimulcast).toList();

  static List<Series> get dubbed => all.where((s) => s.dubbed).toList();

  static List<Series> byGenre(String genre) =>
      popular.where((s) => s.genres.contains(genre)).toList();

  static List<Series> get finishedSeries =>
      popular.where((s) => s.finished).toList();

  /// Serie del giorno: in onda (`finished: false`) o concluse (`true`).
  static List<Series> onWeekday(int weekday, {required bool finished}) =>
      all.where((s) => s.weekday == weekday && s.finished == finished).toList()
        ..sort((a, b) => (a.airTime ?? '').compareTo(b.airTime ?? ''));

  static List<Series> similarTo(Series series) => popular
      .where(
        (s) =>
            s.id != series.id && s.genres.any((g) => series.genres.contains(g)),
      )
      .toList();

  static String normalize(String text) {
    const from = 'àáâäèéêëìíîïòóôöùúûüōū';
    const to = 'aaaaeeeeiiiioooouuuuou';
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? to[i] : ch);
    }
    return buffer.toString();
  }

  static List<Series> search(String query) {
    final q = normalize(query.trim());
    if (q.isEmpty) return popular;
    return popular.where((s) {
      final haystack = normalize(
        [s.title, s.originalTitle, s.studio, ...s.genres].join(' '),
      );
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();
  }
}
