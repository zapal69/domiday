import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Системное меню «Поделиться» для картинки, собранной в приложении.
/// Сети нет: файл пишется в кэш приложения и отдаётся выбранному
/// приложению через FileProvider. Возвращает false, если меню не открылось.
abstract interface class ShareService {
  Future<bool> shareImage(Uint8List png, String fileName, String title);

  /// Открыть адрес (mailto: или https:) в другом приложении — почте или
  /// браузере. Само приложение в сеть не ходит: адрес передаётся системе.
  Future<bool> openUrl(String url);
}

class ChannelShareService implements ShareService {
  static const _channel = MethodChannel('domiday/share');
  const ChannelShareService();

  @override
  Future<bool> shareImage(Uint8List png, String fileName, String title) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/share/$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png, flush: true);
    final ok = await _channel.invokeMethod<bool>('shareImage', {
      'path': file.path,
      'title': title,
    });
    return ok ?? false;
  }

  @override
  Future<bool> openUrl(String url) async =>
      await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
}

class FakeShareService implements ShareService {
  Uint8List? shared;
  String? fileName;
  String? title;
  bool fail = false;
  final opened = <String>[];
  @override
  Future<bool> openUrl(String url) async {
    if (fail) return false;
    opened.add(url);
    return true;
  }

  @override
  Future<bool> shareImage(Uint8List png, String fileName, String title) async {
    if (fail) throw StateError('share failed');
    shared = png;
    this.fileName = fileName;
    this.title = title;
    return true;
  }
}
