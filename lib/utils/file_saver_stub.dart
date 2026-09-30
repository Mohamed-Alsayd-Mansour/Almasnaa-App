import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';

/// نسخة الويب.
///
/// flutter_file_saver يدعم Web أيضًا، ويستخدم
/// نافذة الحفظ في المتصفح إن كانت متاحة.
Future<bool> saveBytesToFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  try {
    await FlutterFileSaver().writeFileAsBytes(
      fileName: fileName,
      bytes: bytes,
    );

    return true;
  } on FileSaverCancelledException {
    return false;
  }
}
