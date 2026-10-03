import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';

Future<void> openHtmlInBrowser({required String html, required String fileName}) async {
  final blob = html.Blob(<dynamic>[utf8.encode(html)], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Timer(const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
}
