import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// خطأ مزامنة برسالة عربية جاهزة للعرض.
class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => message;
}

/// إعدادات الاتصال بمستودع GitHub. تُحفظ محليًا على الجهاز فقط، وبمعزل
/// عن بيانات التطبيق (فلا تدخل في النسخ الاحتياطي ولا تُمسح بـ"حذف الكل").
class GithubSyncConfig {
  final String user;
  final String repo;
  final String token;
  final DateTime? lastSyncAt;

  const GithubSyncConfig({
    required this.user,
    required this.repo,
    required this.token,
    this.lastSyncAt,
  });

  bool get isComplete =>
      user.trim().isNotEmpty && repo.trim().isNotEmpty && token.trim().isNotEmpty;
}

/// مزامنة سحابية مجانية عبر GitHub REST API: تُحفظ نسخة JSON كاملة من
/// البيانات داخل ملف في المستودع، ويمكن رفعها أو تنزيلها يدويًا.
///
/// ملاحظة: GitHub لا يقبل كلمة المرور العادية في الـ API، فالمطلوب
/// "رمز وصول شخصي" (Personal Access Token) بصلاحية Contents: Read/Write.
class GithubSyncService {
  static const defaultUser = 'Mohamed-Alsayd-Mansour';
  static const defaultRepo = 'Almasnaa-App';
  static const filePath = 'cloud-sync/almasnaa-data.json';

  static const _kUser = 'almasnaa_sync_user';
  static const _kRepo = 'almasnaa_sync_repo';
  static const _kToken = 'almasnaa_sync_token';
  static const _kLastSync = 'almasnaa_sync_last';

  Future<GithubSyncConfig> loadConfig() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_kLastSync);
    return GithubSyncConfig(
      user: p.getString(_kUser) ?? defaultUser,
      repo: p.getString(_kRepo) ?? defaultRepo,
      token: p.getString(_kToken) ?? '',
      lastSyncAt: last == null ? null : DateTime.tryParse(last),
    );
  }

  Future<void> saveConfig({
    required String user,
    required String repo,
    required String token,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, user.trim());
    await p.setString(_kRepo, repo.trim());
    await p.setString(_kToken, token.trim());
  }

  Future<void> clearConfig() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [_kUser, _kRepo, _kToken, _kLastSync]) {
      await p.remove(k);
    }
  }

  Future<void> _markSynced() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastSync, DateTime.now().toIso8601String());
  }

  Uri _uri(GithubSyncConfig c) => Uri.https(
        'api.github.com',
        '/repos/${c.user.trim()}/${c.repo.trim()}/contents/$filePath',
      );

  Map<String, String> _headers(GithubSyncConfig c, {String? accept}) => {
        'Authorization': 'Bearer ${c.token.trim()}',
        'Accept': accept ?? 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  SyncException _httpError(http.Response r) {
    switch (r.statusCode) {
      case 401:
        return const SyncException(
            'الرمز غير صحيح أو منتهي الصلاحية. أنشئ رمز وصول جديدًا.');
      case 403:
        return const SyncException(
            'ليس لدى الرمز صلاحية كافية (يلزم Contents: Read and write) أو تم تجاوز حد الطلبات.');
      case 404:
        return const SyncException(
            'تعذر الوصول إلى المستودع. تأكد من اسم المستخدم واسم المستودع وصلاحيات الرمز.');
      case 409:
      case 422:
        return const SyncException(
            'تعارض أثناء الحفظ (تغيّرت النسخة السحابية). أعد المحاولة.');
      default:
        return SyncException('خطأ من GitHub (رمز ${r.statusCode}).');
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(const Duration(seconds: 40));
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('تعذر الاتصال بالإنترنت أو بخادم GitHub.');
    }
  }

  /// يرفع [json] إلى المستودع (ينشئ الملف أو يحدّثه).
  Future<void> upload(GithubSyncConfig c, String json) => _guard(() async {
        // 1) نجلب sha الحالي للملف إن وُجد (مطلوب لتحديث ملف قائم).
        String? sha;
        final meta = await http.get(_uri(c), headers: _headers(c));
        if (meta.statusCode == 200) {
          sha = (jsonDecode(meta.body) as Map)['sha'] as String?;
        } else if (meta.statusCode != 404) {
          throw _httpError(meta);
        }

        // 2) نكتب الملف.
        final body = jsonEncode({
          'message': 'Almasnaa cloud sync ${DateTime.now().toIso8601String()}',
          'content': base64Encode(utf8.encode(json)),
          if (sha != null) 'sha': sha,
        });
        final res = await http.put(
          _uri(c),
          headers: {..._headers(c), 'Content-Type': 'application/json'},
          body: body,
        );
        if (res.statusCode != 200 && res.statusCode != 201) {
          throw _httpError(res);
        }
        await _markSynced();
      });

  /// ينزّل نص JSON من المستودع، أو null إن لم يكن هناك ملف بعد.
  Future<String?> download(GithubSyncConfig c) => _guard(() async {
        final res = await http.get(
          _uri(c),
          headers: _headers(c, accept: 'application/vnd.github.raw+json'),
        );
        if (res.statusCode == 404) {
          // نفرّق بين "لا يوجد ملف" و"لا يوجد وصول" بفحص المستودع نفسه.
          final repo = await http.get(
            Uri.https('api.github.com', '/repos/${c.user.trim()}/${c.repo.trim()}'),
            headers: _headers(c),
          );
          if (repo.statusCode == 200) return null;
          throw _httpError(repo.statusCode == 404 ? res : repo);
        }
        if (res.statusCode != 200) throw _httpError(res);
        await _markSynced();
        return utf8.decode(res.bodyBytes);
      });
}
