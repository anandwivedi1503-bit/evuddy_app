import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/evuddy_api.dart';

/// Polls evuddy.com so the app matches the website festive calendar.
class BrandCalendar extends ChangeNotifier {
  BrandCalendar._();
  static final BrandCalendar instance = BrandCalendar._();

  BrandCampaign? campaign;
  Timer? _poll;

  Future<void> start() async {
    await refresh();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(minutes: 10), (_) => refresh());
  }

  Future<void> refresh() async {
    final next = await EvuddyApi.festiveToday();
    final id = next?.id ?? '';
    final prev = campaign?.id ?? '';
    campaign = next;
    if (id != prev) notifyListeners();
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
  }
}