import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/home_page.dart';
import 'store/item_store.dart';
import 'store/theme_store.dart';
import 'storage/item_repository.dart';

void main() {
  // 全局错误捕获
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}\n${details.stack}');
  };

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final seedColor = const Color(0xFF6D87F5);
    final lightBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    );
    final darkBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemStore(ItemRepository())),
        ChangeNotifierProvider(create: (_) => ThemeStore()),
      ],
      child: Builder(
        builder: (context) {
          final themeStore = context.watch<ThemeStore>();
          return MaterialApp(
            title: '物品记录',
            themeMode: themeStore.themeMode,
            theme: lightBase.copyWith(
              textTheme: GoogleFonts.notoSansScTextTheme(lightBase.textTheme),
            ),
            darkTheme: darkBase.copyWith(
              textTheme: GoogleFonts.notoSansScTextTheme(darkBase.textTheme),
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en'),
            ],
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
