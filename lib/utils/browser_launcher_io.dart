import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

/// يحفظ تقرير HTML في مجلد مؤقت ثم يفتحه في المتصفح الافتراضي.
///
/// - أندرويد / iOS: يُفتح الملف عبر FileProvider (open_filex) لأن روابط
///   file:// محظورة على أندرويد الحديث.
/// - ويندوز / ماك / لينكس: يُفتح بالتطبيق الافتراضي لملفات HTML.
Future<void> openHtmlInBrowser({required String html, required String fileName}) async {
  // اسم ملف بحروف إنجليزية فقط لتجنب مشاكل المسارات العربية.
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final dir = await Directory.systemTemp.createTemp('almasnaa_print_');
  final file = File('${dir.path}${Platform.pathSeparator}almasnaa-report-$stamp.html');
  await file.writeAsString(html, encoding: utf8, flush: true);
  final path = file.path;

  if (Platform.isAndroid || Platform.isIOS) {
    final result = await OpenFilex.open(path, type: 'text/html');
    if (result.type != ResultType.done) {
      throw StateError(
        result.type == ResultType.noAppToOpen
            ? 'لا يوجد متصفح لفتح ملف HTML على هذا الجهاز.'
            : 'تعذر فتح التقرير: ${result.message}',
      );
    }
    return;
  }

  ProcessResult? result;
  if (Platform.isWindows) {
    result = await Process.run('rundll32', ['url.dll,FileProtocolHandler', path]);
  } else if (Platform.isMacOS) {
    result = await Process.run('open', [path]);
  } else if (Platform.isLinux) {
    result = await Process.run('xdg-open', [path]);
  }
  if (result != null && result.exitCode == 0) return;

  // محاولة أخيرة عبر url_launcher.
  if (!await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication)) {
    throw StateError('تعذر فتح ملف HTML في المتصفح.');
  }
}
