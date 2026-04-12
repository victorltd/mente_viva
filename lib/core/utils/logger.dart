// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════
// LOGGER
// Só loga em modo debug (desenvolvimento)
// ═══════════════════════════════════════════════════════

/// Loga apenas em modo debug (desenvolvimento)
/// Em produção (build --release), não faz nada
void log(String message, {String? tag}) {
  if (kDebugMode) {
    if (tag != null) {
      debugPrint('[$tag] $message');
    } else {
      debugPrint(message);
    }
  }
}

/// Log apenas em modo debug com emoji
void logInfo(String message) => log(message);
void logSuccess(String message) => log('✅ $message');
void logWarning(String message) => log('⚠️ $message');
void logError(String message) => log('❌ $message');
void logSection(String title) {
  if (kDebugMode) {
    debugPrint('═' * 60);
    debugPrint(title);
    debugPrint('═' * 60);
  }
}
