import 'package:flutter/material.dart';

/// Флаг страны по коду ISO из assets/flags (PNG 4×3). Без кода или без
/// файла ничего не рисует — место не занимает.
class CountryFlag extends StatelessWidget {
  final String? code;
  final double width;
  const CountryFlag({super.key, required this.code, this.width = 20});

  @override
  Widget build(BuildContext context) {
    final code = this.code;
    if (code == null) return const SizedBox.shrink();
    // Чистый прямоугольник: без рамки и скругления, чтобы светлые поля
    // флагов не получали лишних оттенков.
    return SizedBox(
      key: Key('flag-$code'),
      width: width,
      height: width * 3 / 4,
      child: Image.asset(
        'assets/flags/${code.toLowerCase()}.png',
        fit: BoxFit.fill,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Знак Domiday, как в шапке сайта domiday.com: булавка цветом текста с
/// буквой D цветом фона (геометрия viewBox 64 с сайта).
class DomidayLogo extends StatelessWidget {
  final double size;
  const DomidayLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        ink: theme.colorScheme.onSurface,
        background:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color ink;
  final Color background;
  const _LogoPainter({required this.ink, required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    // M32 60 S12 40 12 26 a20 20 0 0 1 40 0 c0 14 -20 34 -20 34 z
    final pin = Path()
      ..moveTo(32, 60)
      ..cubicTo(32, 60, 12, 40, 12, 26)
      ..arcToPoint(const Offset(52, 26), radius: const Radius.circular(20))
      ..cubicTo(52, 40, 32, 60, 32, 60)
      ..close();
    canvas.drawPath(pin, Paint()..color = ink);
    // Буква D: стойка 27..32 и дуга радиусом 9.
    final d = Path()
      ..moveTo(27, 17)
      ..lineTo(32, 17)
      ..arcToPoint(const Offset(32, 35), radius: const Radius.circular(9))
      ..lineTo(27, 35)
      ..close()
      ..addRect(const Rect.fromLTWH(27, 17, 5, 18));
    canvas.drawPath(d, Paint()..color = background);
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.ink != ink || old.background != background;
}
