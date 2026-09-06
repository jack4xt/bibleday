import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'services/backup_service.dart';
import 'services/backup_worker.dart';
import 'services/bible_database_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';

const _importChannel = MethodChannel('cz.bibleday.app/import');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Linux/desktop vyžaduje FFI inicializaci pro sqflite
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Zkontroluj jestli je čas na automatickou zálohu při startu appky.
  try {
    await BackupWorkerScheduler.checkAndRunAutoBackup();
  } catch (_) {
    // Ignoruj chyby zálohy při startu
  }

  // Inicializace notifikací
  try {
    await NotificationService.initialize();
  } catch (_) {
    // Ignoruj chyby notifikací na platformách bez podpory
  }

  runApp(const BibleDayApp());
}

class BibleDayApp extends StatefulWidget {
  const BibleDayApp({super.key});

  static _BibleDayAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BibleDayAppState>();

  @override
  State<BibleDayApp> createState() => _BibleDayAppState();
}

class _BibleDayAppState extends State<BibleDayApp> with WidgetsBindingObserver {
  final _settings = SettingsService();
  final _backup = BackupService();
  bool _loading = true;
  bool _onboardingDone = false;
  double _fontScale = 1.0;
  bool _isDarkTheme = true;
  bool _importingCsp = false;
  int _cspProgress = 0;
  int _cspTotal = 66;

  // Klíč pro navigátor, abychom mohli zobrazit SnackBar odkudkoli (i bez context z buildu)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingImport();
      BackupWorkerScheduler.checkAndRunAutoBackup().catchError((_) {});
    }
  }

  Future<void> _init() async {
    final done = await _settings.isOnboardingDone();
    final fontSize = await _settings.getFontSize();
    final isDark = await _settings.isDarkTheme();

    // Zobraz UI okamžitě
    setState(() {
      _onboardingDone = done;
      _fontScale = fontSize;
      _isDarkTheme = isDark;
      _loading = false;
    });

    await _checkPendingImport();

    // Import ČSP na pozadí — TIŠE, bez blokování UI
    // Spustíme až po zobrazení UI pomocí Future.microtask
    Future.microtask(() async {
      final cspAvailable =
          await BibleDatabaseService.instance.isTranslationAvailable('csp');
      if (!cspAvailable) {
        try {
          await BibleDatabaseService.instance.importCspFromAssets();
        } catch (_) {}
      }
    });
  }

  Future<void> _checkPendingImport() async {
    try {
      final path = await _importChannel.invokeMethod<String>('getPendingImportPath');
      if (path == null) return;

      final success = await _backup.importFromPath(path);
      final l = navigatorKey.currentContext != null
          ? AppLocalizations.of(navigatorKey.currentContext!)
          : null;

      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(
          success
              ? (l?.backupImportSuccess ?? 'Backup imported successfully ✓')
              : (l?.backupImportError ?? 'Error importing backup'),
        ),
        backgroundColor: success ? AppTheme.neonGold : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ));

      if (success) {
        // Restartuj appku do hlavní obrazovky s čerstvě naimportovanými daty
        setState(() {});
      }
    } catch (_) {
      // platform channel nedostupný (např. na desktopu) — ignoruj
    }
  }

  void updateFontSize(double scale) {
    setState(() => _fontScale = scale);
  }

  void updateTheme(bool isDark) {
    setState(() => _isDarkTheme = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'BibleDay',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs'),
        Locale('en'),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_fontScale),
          ),
          child: child!,
        );
      },
      home: _loading
          ? Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: _importingCsp
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.neonGold),
                          const SizedBox(height: 24),
                          Text(
                            'Připravuji Český studijní překlad...',
                            style: TextStyle(
                              color: AppTheme.neonGold,
                              fontFamily: 'Cinzel',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_cspProgress / $_cspTotal knih',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: _cspTotal > 0 ? _cspProgress / _cspTotal : 0,
                              color: AppTheme.neonGold,
                              backgroundColor: AppTheme.divider,
                            ),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(color: AppTheme.neonGold),
              ),
            )
          : _onboardingDone
              ? const MainScreen()
              : OnboardingScreen(
                  onDone: () => setState(() => _onboardingDone = true),
                ),
    );
  }
}
