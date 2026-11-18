import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/firebase_providers.dart';

class AppSettingsService {
  final FirebaseDatabase _db;

  AppSettingsService(this._db);

  static const Map<String, dynamic> defaultSettings = {
    'maintenance_mode': false,
    'min_app_version': '1.0.0',
    'welcome_banner_enabled': true,
    'instapay_enabled': true,
    'vodafone_cash_enabled': true,
    'default_delivery_fee': 20.0,
    'delivery_radius_km': 15.0,
    'commission_rate_percent': 10.0,
  };

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final snapshot = await _db.ref('app_settings').get();
      if (snapshot.exists && snapshot.value is Map) {
        final map = Map<String, dynamic>.from(defaultSettings);
        final data = snapshot.value as Map;
        for (final entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          map[key] =
              value is Map && value.containsKey('val') ? value['val'] : value;
        }
        return map;
      }
      return defaultSettings;
    } catch (e) {
      debugPrint('[AppSettingsService] Error fetching settings: $e');
      return defaultSettings;
    }
  }

  Future<bool> updateSetting(String key, dynamic value,
      {String? adminId}) async {
    try {
      await _db.ref('app_settings/$key').set({
        'val': value,
        'updated_at': DateTime.now().toIso8601String(),
        if (adminId != null) 'updated_by': adminId,
      });
      return true;
    } catch (e) {
      debugPrint('[AppSettingsService] Error updating setting: $e');
      return false;
    }
  }
}

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  final db = ref.watch(firebaseDatabaseProvider);
  return AppSettingsService(db);
});

/// Realtime settings provider that listens to Firebase RTDB changes natively
final appSettingsProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final db = ref.watch(firebaseDatabaseProvider);
  final controller = StreamController<Map<String, dynamic>>();

  // Initial default state
  controller.add(AppSettingsService.defaultSettings);

  final sub = db.ref('app_settings').onValue.listen((event) {
    if (event.snapshot.exists && event.snapshot.value is Map) {
      final map = Map<String, dynamic>.from(AppSettingsService.defaultSettings);
      final data = event.snapshot.value as Map;
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        map[key] =
            value is Map && value.containsKey('val') ? value['val'] : value;
      }
      if (!controller.isClosed) controller.add(map);
    }
  }, onError: (err) {
    debugPrint('[Realtime] app_settings error: $err');
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final isMaintenanceModeProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.value?['maintenance_mode'] == true;
});
