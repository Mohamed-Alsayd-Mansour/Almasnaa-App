import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'html_print_service.dart';

class PrintTemplateStore {
  PrintTemplateStore._();

  static const _key = 'html_print_templates_v1';

  static Future<List<HtmlPrintTemplate>> loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => HtmlPrintTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(HtmlPrintTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustom();
    final next = [...current.where((e) => e.id != template.id), template];
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustom();
    await prefs.setString(
      _key,
      jsonEncode(current.where((e) => e.id != id).map((e) => e.toJson()).toList()),
    );
  }
}
