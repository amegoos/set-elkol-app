import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

class AppSettingsService {
  final SupabaseClient _client;

  AppSettingsService(this._client);

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
      final data = await _client.from('app_settings').select();
      final map = Map<String, dynamic>.from(defaultSettings);
      for (final row in (data as List)) {
        final key = row['key'] as String;
        final value = row['value'];
        map[key] =
            value is Map && value.containsKey('val') ? value['val'] : value;
      }
      return map;
    } catch (e) {
      debugPrint('[AppSettingsService] Error fetching settings: $e');
      return defaultSettings;
    }
  }

  Future<bool> updateSetting(String key, dynamic value,
      {String? adminId}) async {
    try {
      await _client.from('app_settings').upsert({
        'key': key,
        'value': value is Map ? value : {'val': value},
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
  final client = ref.watch(supabaseClientProvider);
  return AppSettingsService(client);
});

/// Realtime settings provider that listens to PostgreSQL changes and invalidates immediately
final appSettingsProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final service = ref.watch(appSettingsServiceProvider);

  final controller = StreamController<Map<String, dynamic>>();

  // Initial load
  service.getSettings().then((settings) {
    if (!controller.isClosed) controller.add(settings);
  });

  // Supabase Realtime channel subscription
  try {
    final channel = client
        .channel('public:app_settings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_settings',
          callback: (payload) async {
            debugPrint(
                '[Realtime] app_settings change received: ${payload.eventType}');
            final fresh = await service.getSettings();
            if (!controller.isClosed) controller.add(fresh);
          },
        )
        .subscribe();

    ref.onDispose(() {
      channel.unsubscribe();
      controller.close();
    });
  } catch (e) {
    debugPrint('[Realtime] Failed to subscribe to app_settings: $e');
    ref.onDispose(() => controller.close());
  }

  return controller.stream;
});

final isMaintenanceModeProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.value?['maintenance_mode'] == true;
});
