// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_service.dart';
import 'app.dart';

void main() async {
  // ══════════════════════════════════════
  // INICIALIZAÇÕES
  // ══════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Orientação vertical apenas (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Supabase
  await SupabaseService.initialize();

  // ══════════════════════════════════════
  // RODAR APP
  // ══════════════════════════════════════
  runApp(
    const ProviderScope(
      child: MenteVivaApp(),
    ),
  );
}