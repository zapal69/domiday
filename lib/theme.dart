import 'package:flutter/material.dart';

/// Фирменные цвета Domiday. Одинаковы в обеих темах.
const kYellow = Color(0xFFF4CB45);
const kCharcoal = Color(0xFF272821);
const kCream = Color(0xFFF7F5ED);

/// Шрифт заголовков и чисел (переменный, ось wght). Текст — Roboto.
const kDisplayFont = 'Manrope';

/// Стиль заголовка/числа: Manrope нужной насыщенности. Переменному шрифту
/// вес задаётся осью, поэтому fontWeight дублируется в fontVariations.
TextStyle display({
  required double size,
  FontWeight weight = FontWeight.w800,
  double? height,
  double letterSpacing = -0.5,
  Color? color,
}) => TextStyle(
  fontFamily: kDisplayFont,
  fontSize: size,
  fontWeight: weight,
  fontVariations: [FontVariation('wght', weight.value.toDouble())],
  height: height,
  letterSpacing: letterSpacing,
  color: color,
);

/// Радиусы и отступы, общие для экранов.
const kRadiusHero = 24.0;
const kRadiusCard = 22.0;
const kRadiusButton = 18.0;
const kGutter = 20.0;

/// Цвета, которых нет в стандартной ColorScheme: акцентная «тёмная» карточка
/// и категории дней. Берутся через `DomidayColors.of(context)`, чтобы тёмная
/// тема не хардкодила уголь поверх почти такого же фона.
@immutable
class DomidayColors extends ThemeExtension<DomidayColors> {
  /// Фон, основной и приглушённый текст акцентной карточки.
  final Color hero;
  final Color heroInk;
  final Color heroMuted;

  /// Категории дней: дома, вне дома, день в двух странах, неизвестно,
  /// ещё не наступившие.
  final Color home;
  final Color away;
  final Color both;
  final Color unknown;
  final Color future;

  /// Тонкая рамка будущего дня: в тёмной теме без неё клетки сливаются.
  final Color futureLine;

  /// Фон полосы прогресса.
  final Color track;

  /// «Вторая» карточка: мягкая подложка внутри экрана (блок определения).
  final Color soft;

  /// Календарь: заливка дней дома (цвет текста темы — уголь на светлой,
  /// светлая на тёмной), палитра для
  /// зарубежных стран по порядку убывания дней и цвет «других» стран.
  final Color homeCell;
  final List<Color> countryPalette;
  final Color otherCountry;

  const DomidayColors({
    required this.hero,
    required this.heroInk,
    required this.heroMuted,
    required this.home,
    required this.away,
    required this.both,
    required this.unknown,
    required this.future,
    required this.futureLine,
    required this.track,
    required this.soft,
    required this.homeCell,
    required this.countryPalette,
    required this.otherCountry,
  });

  /// Цвет страны по её месту среди зарубежных стран года; -1 — «другие».
  Color countryColor(int slot) => slot < 0 || slot >= countryPalette.length
      ? otherCountry
      : countryPalette[slot];

  static const light = DomidayColors(
    hero: kCharcoal,
    heroInk: kCream,
    heroMuted: Color(0xFFDFDFD5),
    home: kCharcoal,
    away: kYellow,
    both: Color(0xFFE8532F),
    unknown: Color(0xFFC9C2AE),
    future: Color(0xFFF3F1E8),
    futureLine: Color(0xFFE4E0D1),
    track: Color(0xFFEAE2D4),
    soft: Color(0xFFEDEADF),
    homeCell: kCharcoal,
    countryPalette: [
      Color(0xFFF4CB45),
      Color(0xFF3BA99C),
      Color(0xFF8E6BD6),
      Color(0xFF4A86E0),
      Color(0xFF5FAF4E),
      Color(0xFFE06AA8),
    ],
    otherCountry: Color(0xFFB9B09A),
  );

  static const dark = DomidayColors(
    hero: Color(0xFF2C2D27),
    heroInk: kCream,
    heroMuted: Color(0xFFCFC6B4),
    home: Color(0xFFE4E1D3),
    away: kYellow,
    both: Color(0xFFFF6B3D),
    unknown: Color(0xFF5C594D),
    future: Color(0xFF262720),
    futureLine: Color(0xFF3A3B33),
    track: Color(0xFF38342B),
    soft: Color(0xFF31322B),
    homeCell: Color(0xFFE4E1D3),
    countryPalette: [
      Color(0xFFF4CB45),
      Color(0xFF5CC9BB),
      Color(0xFFB294F0),
      Color(0xFF7AA8F5),
      Color(0xFF8BD07A),
      Color(0xFFF08CC4),
    ],
    otherCountry: Color(0xFF8B8470),
  );

  static DomidayColors of(BuildContext context) =>
      Theme.of(context).extension<DomidayColors>() ?? light;

  @override
  DomidayColors copyWith({
    Color? hero,
    Color? heroInk,
    Color? heroMuted,
    Color? home,
    Color? away,
    Color? both,
    Color? unknown,
    Color? future,
    Color? futureLine,
    Color? track,
    Color? soft,
    Color? homeCell,
    List<Color>? countryPalette,
    Color? otherCountry,
  }) => DomidayColors(
    hero: hero ?? this.hero,
    heroInk: heroInk ?? this.heroInk,
    heroMuted: heroMuted ?? this.heroMuted,
    home: home ?? this.home,
    away: away ?? this.away,
    both: both ?? this.both,
    unknown: unknown ?? this.unknown,
    future: future ?? this.future,
    futureLine: futureLine ?? this.futureLine,
    track: track ?? this.track,
    soft: soft ?? this.soft,
    homeCell: homeCell ?? this.homeCell,
    countryPalette: countryPalette ?? this.countryPalette,
    otherCountry: otherCountry ?? this.otherCountry,
  );

  @override
  DomidayColors lerp(DomidayColors? other, double t) {
    if (other == null) return this;
    return DomidayColors(
      hero: Color.lerp(hero, other.hero, t)!,
      heroInk: Color.lerp(heroInk, other.heroInk, t)!,
      heroMuted: Color.lerp(heroMuted, other.heroMuted, t)!,
      home: Color.lerp(home, other.home, t)!,
      away: Color.lerp(away, other.away, t)!,
      both: Color.lerp(both, other.both, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
      future: Color.lerp(future, other.future, t)!,
      futureLine: Color.lerp(futureLine, other.futureLine, t)!,
      track: Color.lerp(track, other.track, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      homeCell: Color.lerp(homeCell, other.homeCell, t)!,
      countryPalette: t < 0.5 ? countryPalette : other.countryPalette,
      otherCountry: Color.lerp(otherCountry, other.otherCountry, t)!,
    );
  }
}

ThemeData domidayTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark ? DomidayColors.dark : DomidayColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: kYellow,
    brightness: brightness,
    primary: dark ? kYellow : kCharcoal,
    onPrimary: dark ? kCharcoal : kCream,
    secondary: kYellow,
    onSecondary: kCharcoal,
    surface: dark ? const Color(0xFF20211D) : kCream,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.4,
      ),
      // merge: цвет текста темы остаётся, меняются шрифт и размер.
      headlineMedium: base.textTheme.headlineMedium?.merge(
        display(size: 28, height: 1.15),
      ),
      titleLarge: base.textTheme.titleLarge?.merge(
        display(size: 22, height: 1.2),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2C2D27) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kYellow,
        foregroundColor: kCharcoal,
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF2C2D27) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
    ),
  );
}
