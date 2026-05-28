import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/navigation/app_router.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Future.wait([
    initializeDateFormatting('es_CO', null),
    Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    ),
  ]);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  FlutterNativeSplash.remove();
  runApp(const GestiaApp());
}

class GestiaApp extends StatelessWidget {
  const GestiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gestia',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
