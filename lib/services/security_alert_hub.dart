import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rapido-style in-app security & trip alerts (local until push is wired).
class SecurityAlertHub {
  SecurityAlertHub._();
  static final SecurityAlertHub instance = SecurityAlertHub._();

  static const _prefsKey = 'evuddy_security_alerts_v1';
  final ValueNotifier<int> unread = ValueNotifier(0);

  List<SecurityAlert> _items = [];

  Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        _items = [];
        _syncUnread();
        return;
      }
      final list = jsonDecode(raw);
      if (list is! List) return;
      _items = list
          .whereType<Map>()
          .map((m) => SecurityAlert.fromJson(m.cast<String, dynamic>()))
          .toList();
      _syncUnread();
    } catch (_) {}
  }

  List<SecurityAlert> get all => List.unmodifiable(_items);

  Future<void> push({
    required String title,
    required String body,
    String category = 'trip',
    bool security = false,
  }) async {
    final alert = SecurityAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      category: category,
      security: security,
      createdAt: DateTime.now(),
      read: false,
    );
    _items.insert(0, alert);
    if (_items.length > 40) _items = _items.sublist(0, 40);
    await _persist();
  }

  Future<void> markRead(String id) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(read: true);
        break;
      }
    }
    await _persist();
  }

  Future<void> markAllRead() async {
    _items = [for (final a in _items) a.copyWith(read: true)];
    await _persist();
  }

  Future<void> _persist() async {
    _syncUnread();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _prefsKey,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _syncUnread() {
    unread.value = _items.where((a) => !a.read).length;
  }
}

class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.security,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool security;
  final DateTime createdAt;
  final bool read;

  SecurityAlert copyWith({bool? read}) => SecurityAlert(
        id: id,
        title: title,
        body: body,
        category: category,
        security: security,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'security': security,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory SecurityAlert.fromJson(Map<String, dynamic> j) => SecurityAlert(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Alert',
        body: j['body']?.toString() ?? '',
        category: j['category']?.toString() ?? 'trip',
        security: j['security'] == true,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        read: j['read'] == true,
      );
}
