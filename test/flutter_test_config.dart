import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Шрифт Manrope из pubspec в тестах не подгружается сам: без него
/// заголовки в golden-эталонах рисуются квадратами. Загружаем из файла
/// перед всеми тестами.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final bytes = File('assets/fonts/Manrope.ttf').readAsBytesSync();
  final loader = FontLoader('Manrope')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
  await testMain();
}
