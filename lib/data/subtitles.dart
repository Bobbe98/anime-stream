import 'package:flutter/painting.dart';
import 'package:video_player/video_player.dart';

import 'catalog.dart';

class SubtitleLanguage {
  const SubtitleLanguage(
    this.code,
    this.name,
    this.italianName, {
    this.rtl = false,
  });

  final String code;

  /// Nome della lingua nella lingua stessa (es. "Deutsch").
  final String name;
  final String italianName;
  final bool rtl;

  TextDirection get direction => rtl ? TextDirection.rtl : TextDirection.ltr;
}

/// Una traccia di sottotitoli pronta da mostrare nel player.
class SubtitleTrack {
  const SubtitleTrack(this.language, this.captions);

  final SubtitleLanguage language;
  final List<Caption> captions;

  /// Il sottotitolo da mostrare in [position], o `null`.
  String? textAt(Duration position) {
    var lo = 0;
    var hi = captions.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = captions[mid];
      if (position < c.start) {
        hi = mid - 1;
      } else if (position > c.end) {
        lo = mid + 1;
      } else {
        return c.text;
      }
    }
    return null;
  }
}

class Subtitles {
  static const off = 'off';

  static const languages = [
    SubtitleLanguage('it', 'Italiano', 'Italiano'),
    SubtitleLanguage('en', 'English', 'Inglese'),
    SubtitleLanguage('es', 'Español', 'Spagnolo'),
    SubtitleLanguage('fr', 'Français', 'Francese'),
    SubtitleLanguage('de', 'Deutsch', 'Tedesco'),
    SubtitleLanguage('pt', 'Português', 'Portoghese'),
    SubtitleLanguage('ja', '日本語', 'Giapponese'),
    SubtitleLanguage('ko', '한국어', 'Coreano'),
    SubtitleLanguage('zh', '中文', 'Cinese'),
    SubtitleLanguage('ru', 'Русский', 'Russo'),
    SubtitleLanguage('ar', 'العربية', 'Arabo', rtl: true),
    SubtitleLanguage('hi', 'हिन्दी', 'Hindi'),
    SubtitleLanguage('tr', 'Türkçe', 'Turco'),
    SubtitleLanguage('pl', 'Polski', 'Polacco'),
    SubtitleLanguage('nl', 'Nederlands', 'Olandese'),
    SubtitleLanguage('sv', 'Svenska', 'Svedese'),
    SubtitleLanguage('id', 'Bahasa Indonesia', 'Indonesiano'),
    SubtitleLanguage('vi', 'Tiếng Việt', 'Vietnamita'),
    SubtitleLanguage('th', 'ไทย', 'Thailandese'),
    SubtitleLanguage('el', 'Ελληνικά', 'Greco'),
    SubtitleLanguage('uk', 'Українська', 'Ucraino'),
    SubtitleLanguage('ro', 'Română', 'Rumeno'),
    SubtitleLanguage('cs', 'Čeština', 'Ceco'),
    SubtitleLanguage('hu', 'Magyar', 'Ungherese'),
    SubtitleLanguage('he', 'עברית', 'Ebraico', rtl: true),
  ];

  static SubtitleLanguage? byCode(String code) {
    for (final l in languages) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// Battute dimostrative: [0] titolo, [1..5] dialoghi a rotazione, [6] finale.
  static const _lines = <String, List<String>>{
    'it': [
      'Episodio {n}: {t}',
      'Il vento sta cambiando.',
      'Ormai non possiamo tornare indietro.',
      'Resta vicino a me, qualunque cosa accada.',
      'Hai sentito? Sta arrivando qualcosa.',
      'Questa volta combattiamo insieme.',
      'Continua…',
    ],
    'en': [
      'Episode {n}: {t}',
      'The wind is changing.',
      "There's no turning back now.",
      'Stay close to me, whatever happens.',
      "Did you hear that? Something's coming.",
      'This time, we fight together.',
      'To be continued…',
    ],
    'es': [
      'Episodio {n}: {t}',
      'El viento está cambiando.',
      'Ya no podemos dar marcha atrás.',
      'Quédate cerca de mí, pase lo que pase.',
      '¿Lo has oído? Algo se acerca.',
      'Esta vez luchamos juntos.',
      'Continuará…',
    ],
    'fr': [
      'Épisode {n} : {t}',
      'Le vent tourne.',
      'On ne peut plus faire marche arrière.',
      "Reste près de moi, quoi qu'il arrive.",
      'Tu as entendu ? Quelque chose approche.',
      'Cette fois, on se bat ensemble.',
      'À suivre…',
    ],
    'de': [
      'Folge {n}: {t}',
      'Der Wind dreht sich.',
      'Jetzt gibt es kein Zurück mehr.',
      'Bleib bei mir, egal was passiert.',
      'Hast du das gehört? Da kommt etwas.',
      'Diesmal kämpfen wir zusammen.',
      'Fortsetzung folgt…',
    ],
    'pt': [
      'Episódio {n}: {t}',
      'O vento está mudando.',
      'Agora não há mais volta.',
      'Fique perto de mim, aconteça o que acontecer.',
      'Você ouviu isso? Algo está vindo.',
      'Desta vez, lutamos juntos.',
      'Continua…',
    ],
    'ja': [
      '第{n}話「{t}」',
      '風向きが変わってきた。',
      'もう後戻りはできない。',
      '何があっても、そばにいて。',
      '今の聞こえた？何かが来る。',
      '今度こそ、一緒に戦おう。',
      'つづく…',
    ],
    'ko': [
      '제{n}화: {t}',
      '바람이 바뀌고 있어.',
      '이제 돌아갈 수 없어.',
      '무슨 일이 있어도 내 곁에 있어 줘.',
      '방금 들었어? 뭔가 오고 있어.',
      '이번엔 함께 싸우자.',
      '다음 화에 계속…',
    ],
    'zh': [
      '第{n}集：{t}',
      '风向变了。',
      '我们已经无法回头了。',
      '无论发生什么，都待在我身边。',
      '你听到了吗？有什么东西来了。',
      '这一次，我们一起战斗。',
      '未完待续……',
    ],
    'ru': [
      'Серия {n}: {t}',
      'Ветер меняется.',
      'Пути назад уже нет.',
      'Будь рядом, что бы ни случилось.',
      'Ты слышал? Что-то приближается.',
      'На этот раз мы сражаемся вместе.',
      'Продолжение следует…',
    ],
    'ar': [
      'الحلقة {n}: {t}',
      'الرياح تتغير.',
      'لا مجال للعودة الآن.',
      'ابقَ بقربي مهما حدث.',
      'هل سمعت ذلك؟ هناك شيء قادم.',
      'هذه المرة سنقاتل معًا.',
      'يتبع…',
    ],
    'hi': [
      'एपिसोड {n}: {t}',
      'हवा बदल रही है।',
      'अब पीछे मुड़ना संभव नहीं है।',
      'कुछ भी हो, मेरे पास रहना।',
      'तुमने सुना? कुछ आ रहा है।',
      'इस बार हम साथ मिलकर लड़ेंगे।',
      'जारी रहेगा…',
    ],
    'tr': [
      'Bölüm {n}: {t}',
      'Rüzgâr dönüyor.',
      'Artık geri dönüş yok.',
      'Ne olursa olsun yanımda kal.',
      'Duydun mu? Bir şey geliyor.',
      'Bu sefer birlikte savaşıyoruz.',
      'Devam edecek…',
    ],
    'pl': [
      'Odcinek {n}: {t}',
      'Wiatr się zmienia.',
      'Nie ma już odwrotu.',
      'Zostań przy mnie, cokolwiek się stanie.',
      'Słyszałeś? Coś się zbliża.',
      'Tym razem walczymy razem.',
      'Ciąg dalszy nastąpi…',
    ],
    'nl': [
      'Aflevering {n}: {t}',
      'De wind draait.',
      'Er is geen weg meer terug.',
      'Blijf bij me, wat er ook gebeurt.',
      'Hoorde je dat? Er komt iets aan.',
      'Deze keer vechten we samen.',
      'Wordt vervolgd…',
    ],
    'sv': [
      'Avsnitt {n}: {t}',
      'Vinden vänder.',
      'Nu finns det ingen återvändo.',
      'Stanna nära mig, vad som än händer.',
      'Hörde du? Något närmar sig.',
      'Den här gången kämpar vi tillsammans.',
      'Fortsättning följer…',
    ],
    'id': [
      'Episode {n}: {t}',
      'Angin mulai berubah.',
      'Sekarang kita tidak bisa kembali.',
      'Tetaplah di dekatku, apa pun yang terjadi.',
      'Kamu dengar itu? Ada sesuatu yang datang.',
      'Kali ini, kita bertarung bersama.',
      'Bersambung…',
    ],
    'vi': [
      'Tập {n}: {t}',
      'Gió đang đổi chiều.',
      'Giờ không thể quay lại được nữa.',
      'Hãy ở bên tôi, dù có chuyện gì xảy ra.',
      'Bạn có nghe thấy không? Có thứ gì đang đến.',
      'Lần này, chúng ta cùng chiến đấu.',
      'Còn tiếp…',
    ],
    'th': [
      'ตอนที่ {n}: {t}',
      'ลมกำลังเปลี่ยนทิศ',
      'ตอนนี้เราถอยกลับไม่ได้แล้ว',
      'อยู่ข้างฉันนะ ไม่ว่าจะเกิดอะไรขึ้น',
      'ได้ยินไหม? มีบางอย่างกำลังมา',
      'ครั้งนี้เราจะสู้ไปด้วยกัน',
      'โปรดติดตามตอนต่อไป…',
    ],
    'el': [
      'Επεισόδιο {n}: {t}',
      'Ο άνεμος αλλάζει.',
      'Δεν υπάρχει πια γυρισμός.',
      'Μείνε κοντά μου, ό,τι κι αν συμβεί.',
      'Το άκουσες; Κάτι έρχεται.',
      'Αυτή τη φορά πολεμάμε μαζί.',
      'Συνεχίζεται…',
    ],
    'uk': [
      'Серія {n}: {t}',
      'Вітер змінюється.',
      'Шляху назад уже немає.',
      'Будь поруч, що б не сталося.',
      'Ти чув? Щось наближається.',
      'Цього разу ми боремося разом.',
      'Далі буде…',
    ],
    'ro': [
      'Episodul {n}: {t}',
      'Vântul se schimbă.',
      'Acum nu mai există cale de întoarcere.',
      'Rămâi lângă mine, orice s-ar întâmpla.',
      'Ai auzit? Ceva se apropie.',
      'De data asta luptăm împreună.',
      'Va urma…',
    ],
    'cs': [
      'Epizoda {n}: {t}',
      'Vítr se mění.',
      'Teď už není cesty zpět.',
      'Zůstaň u mě, ať se stane cokoli.',
      'Slyšel jsi to? Něco se blíží.',
      'Tentokrát bojujeme spolu.',
      'Pokračování příště…',
    ],
    'hu': [
      '{n}. rész: {t}',
      'Fordul a szél.',
      'Most már nincs visszaút.',
      'Maradj mellettem, bármi történjék.',
      'Hallottad? Valami közeledik.',
      'Ezúttal együtt harcolunk.',
      'Folytatása következik…',
    ],
    'he': [
      'פרק {n}: {t}',
      'הרוח משתנה.',
      'אין דרך חזרה עכשיו.',
      'תישאר קרוב אליי, לא משנה מה יקרה.',
      'שמעת את זה? משהו מתקרב.',
      'הפעם נילחם ביחד.',
      'המשך יבוא…',
    ],
  };

  static const _cueLength = Duration(seconds: 4);
  static const _cueEvery = Duration(seconds: 20);

  /// Traccia dimostrativa per [episode] in [code], distribuita sull'intera
  /// durata del video. Funziona anche offline (non scarica nulla).
  static SubtitleTrack demo(
    Episode episode,
    String code,
    Duration videoLength,
  ) {
    final language = byCode(code) ?? languages.first;
    final lines = _lines[language.code]!;
    final length = videoLength > Duration.zero ? videoLength : episode.duration;
    final captions = <Caption>[];
    var n = 1;

    void add(Duration start, String text) {
      captions.add(
        Caption(number: n++, start: start, end: start + _cueLength, text: text),
      );
    }

    add(
      const Duration(seconds: 2),
      lines[0]
          .replaceAll('{n}', '${episode.number}')
          .replaceAll('{t}', episode.title),
    );
    final finale = length - const Duration(seconds: 8);
    var i = 0;
    for (
      var t = const Duration(seconds: 12);
      t + _cueLength < finale;
      t += _cueEvery
    ) {
      add(t, lines[1 + i % 5]);
      i++;
    }
    if (finale > const Duration(seconds: 8)) add(finale, lines[6]);
    return SubtitleTrack(language, captions);
  }

  /// Converte una traccia in WebVTT (il formato usato dai file reali).
  static String toWebVtt(SubtitleTrack track) {
    final b = StringBuffer('WEBVTT\n\n');
    for (final c in track.captions) {
      b
        ..writeln(c.number)
        ..writeln('${_vttTime(c.start)} --> ${_vttTime(c.end)}')
        ..writeln(c.text)
        ..writeln();
    }
    return b.toString();
  }

  /// Legge un file WebVTT reale (per quando i sottotitoli arrivano dal server).
  static SubtitleTrack parseWebVtt(SubtitleLanguage language, String vtt) =>
      SubtitleTrack(language, WebVTTCaptionFile(vtt).captions);

  static String _vttTime(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}.$ms';
  }
}
