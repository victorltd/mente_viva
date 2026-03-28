// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'config/constants/app_constants.dart';

class MenteVivaApp extends ConsumerWidget {
  const MenteVivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // ══════════════════════════════════════
      // CONFIG BÁSICA
      // ══════════════════════════════════════
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ══════════════════════════════════════
      // TEMA
      // ══════════════════════════════════════
      theme: AppTheme.lightTheme,

      // ══════════════════════════════════════
      // ROTAS
      // ══════════════════════════════════════
      routerConfig: AppRouter.router,

      // ══════════════════════════════════════
      // LOCALIZAÇÃO (PT-BR)
      // ══════════════════════════════════════
      locale: const Locale('pt', 'BR'),
    );
  }
}