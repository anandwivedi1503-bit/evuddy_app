import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/evuddy_api.dart';

/// Today's festival from the same calendar the website uses.
class FestiveToday {
  const FestiveToday({
    required this.date,
    required this.id,
    required this.theme,
    required this.ribbon,
    required this.title,
    required this.body,
    required this.accent,
    required this.sessionKey,
    required this.heroImage,
  });

  final String date;
  final String id;
  final String theme;
  final String ribbon;
  final String title;
  final String body;
  final Color accent;
  final String sessionKey;
  final String heroImage;

  String get heroUrl {
    if (heroImage.isEmpty) return '';
    if (heroImage.startsWith('http')) return heroImage;
    return '${EvuddyApi.origin}$heroImage';
  }

  static const _seenKey = 'evuddy_festive_seen';

  static FestiveToday? parse(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    if (campaign is! Map) return null;
    final title = campaign['welcomeTitle']?.toString().trim() ?? '';
    final body = campaign['welcomeBody']?.toString().trim() ?? '';
    if (title.isEmpty || body.isEmpty) return null;
    final session = campaign['sessionKey']?.toString().trim() ?? '';
    return FestiveToday(
      date: json['date']?.toString() ?? campaign['date']?.toString() ?? '',
      id: campaign['id']?.toString() ?? '',
      theme: campaign['theme']?.toString() ?? '',
      ribbon: campaign['ribbon']?.toString().trim() ?? '',
      title: title,
      body: body,
      accent: _accent(campaign['logoAccent']?.toString()),
      sessionKey: session.isEmpty ? title : session,
      heroImage: campaign['heroImage']?.toString().trim() ?? '',
    );
  }

  static Future<FestiveToday?> load() async {
    try {
      final response = await http
          .get(Uri.parse('${EvuddyApi.origin}/api/festive-today'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      return parse(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> alreadyShown(String sessionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_seenKey) == sessionKey;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markShown(String sessionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenKey, sessionKey);
    } catch (_) {}
  }
}

Color _accent(String? hex) {
  var raw = (hex ?? '').replaceAll('#', '').trim();
  if (raw.length == 6) raw = 'FF$raw';
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return const Color(0xFFF97316);
  return Color(value);
}
