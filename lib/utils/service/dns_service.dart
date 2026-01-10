import 'dart:io';
import 'package:flutter/services.dart';

class DndService {
  static const _ch = MethodChannel('app.dnd.control');

  Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return false;
    return await _ch.invokeMethod('hasDndAccess');
  }

  Future<void> openSettings() async {
    if (Platform.isAndroid) await _ch.invokeMethod('openDndSettings');
  }

  Future<void> setSilent() async {
    if (Platform.isAndroid) await _ch.invokeMethod('setSilent');
  }

  Future<void> restore() async {
    if (Platform.isAndroid) await _ch.invokeMethod('restore');
  }
}
