import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openHtmlInBrowser({required String html, required String fileName}) async {
  final bytes = Uint8List.fromList(utf8.encode(html));
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'حفظ تقرير HTML',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['html'],
    bytes: bytes,
  );
  if (path == null) return;
  await File(path).writeAsBytes(bytes);
  final uri = Uri.file(path);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('تعذر فتح ملف HTML في المتصفح.');
  }
}
