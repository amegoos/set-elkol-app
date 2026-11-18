import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Load .env if present
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize local storage
  await Hive.initFlutter();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully with project: set-elkol');
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SetElKolApp(),
    ),
  );
}

class SetElKolApp extends ConsumerWidget {
  const SetElKolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConstants.appNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      localizationsDelegates: AppLocalizationConfig.delegates,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isDesktopOrWeb = kIsWeb || mediaQuery.size.width > 600;

        Widget content = child ?? const SizedBox.shrink();

        // Responsive Phone Simulator wrapper for Web and Desktop
        if (isDesktopOrWeb) {
          content = Scaffold(
            backgroundColor:
                const Color(0xFF0F172A), // Dark backdrop for preview
            body: Center(
              child: Container(
                width: 430,
                height: 890,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF334155), width: 6),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 35,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.3),
            ),
          ),
          child: content,
        );
      },
    );
  }
}
