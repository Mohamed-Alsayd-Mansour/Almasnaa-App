import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';

/// حفظ ملف باستخدام نافذة الحفظ الأصلية للنظام.
///
/// على Android يستخدم flutter_file_saver
/// ويفتح ACTION_CREATE_DOCUMENT، مما يسمح للمستخدم
/// باختيار مكان الحفظ واسم الملف.
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
    // المستخدم أغلق نافذة الحفظ أو ضغط إلغاء.
    return false;
  }
}
