import 'dart:typed_data';

export 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart';

/// يحفظ bytes في ملف يختاره المستخدم.
Future<bool> saveBytesToFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  return false;
}
