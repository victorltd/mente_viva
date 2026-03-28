// lib/providers/alert_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/checkin_model.dart';

// ══════════════════════════════════════
// ALERT MODEL (calculado, não salvo no DB)
// ══════════════════════════════════════
enum AlertSeverity {
  critical, // 🔴 mood = 1
  warning,  // 🟡 mood ≤ 2 por 2+ dias
  inactive, // 🟠 3+ dias sem check-in
  positive; // 🟢 melhora consistente

  String get emoji {
    switch (this) {
      case AlertSeverity.critical:
        return '🔴';
      case AlertSeverity.warning:
        return '🟡';
      case AlertSeverity.inactive:
        return '🟠';
      case AlertSeverity.positive:
        return '🟢';
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.critical:
        return 'Crítico';
      case AlertSeverity.warning:
        return 'Atenção';
      case AlertSeverity.inactive:
        return 'Inatividade';
      case AlertSeverity.positive:
        return 'Positivo';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.inactive:
        return const Color(0xFFF97316);
      case AlertSeverity.positive:
        return const Color(0xFF10B981);
    }
  }

  /// Para ordenar: critical primeiro
  int get priority {
    switch (this) {
      case AlertSeverity.critical:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.inactive:
        return 2;
      case AlertSeverity.positive:
        return 3;
    }
  }
}

@immutable
class AlertItem {
  final String patientId;
  final String patientName;
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime detectedAt;

  const AlertItem({
    required this.patientId,
    required this.patientName,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedAt,
  });
}

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class AlertState {
  final bool isLoading;
  final List<AlertItem> alerts;
  final String? error;

  const AlertState({
    this.isLoading = false,
    this.alerts = const [],
    this.error,
  });

  AlertState copyWith({
    bool? isLoading,
    List<AlertItem>? alerts,
    String? error,
    bool clearError = false,
  }) {
    return AlertState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  int get totalAlerts => alerts.length;

  int get criticalCount =>
      alerts.where((a) => a.severity == AlertSeverity.critical).length;

  int get warningCount =>
      alerts.where((a) => a.severity == AlertSeverity.warning).length;

  int get inactiveCount =>
      alerts.where((a) => a.severity == AlertSeverity.inactive).length;

  int get positiveCount =>
      alerts.where((a) => a.severity == AlertSeverity.positive).length;

  /// Alertas que precisam de ação (não inclui positivos)
  int get actionableCount => criticalCount + warningCount + inactiveCount;

  /// Alertas de um paciente específico
  List<AlertItem> alertsForPatient(String patientId) =>
      alerts.where((a) => a.patientId == patientId).toList();

  /// Tem alerta para um paciente?
  bool hasAlertForPatient(String patientId) =>
      alerts.any((a) => a.patientId == patientId);

  /// Maior severidade de um paciente
  AlertSeverity? worstSeverityForPatient(String patientId) {
    final patientAlerts = alertsForPatient(patientId);
    if (patientAlerts.isEmpty) return null;
    patientAlerts.sort((a, b) => a.severity.priority.compareTo(b.severity.priority));
    return patientAlerts.first.severity;
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class AlertNotifier extends Notifier<AlertState> {
  @override
  AlertState build() {
    return const AlertState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR ALERTAS PARA TODOS OS PACIENTES
  // ══════════════════════════════════════
  Future<void> loadAlerts(List<Map<String, dynamic>> patients) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final allAlerts = <AlertItem>[];

      for (final patient in patients) {
        final patientId = patient['id'] as String;
        final patientName = patient['full_name'] as String? ?? 'Paciente';
        final status = patient['status'] as String? ?? 'pending';

        // Só analisa pacientes ativos
        if (status != 'active') continue;

        // Buscar últimos 14 dias de check-ins
        final response = await _client
            .from('checkins')
            .select()
            .eq('patient_id', patientId)
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 14))
                  .toIso8601String(),
            )
            .order('created_at', ascending: false);

        final checkins = (response as List)
            .map((json) => CheckinModel.fromJson(json))
            .toList();

        // Calcular alertas para este paciente
        final patientAlerts = _analyzePatient(
          patientId: patientId,
          patientName: patientName,
          checkins: checkins,
        );

        allAlerts.addAll(patientAlerts);
      }

      // Ordenar: críticos primeiro
      allAlerts.sort((a, b) =>
          a.severity.priority.compareTo(b.severity.priority));

      state = state.copyWith(
        alerts: allAlerts,
        isLoading: false,
      );

      debugPrint('=== ${allAlerts.length} ALERTAS DETECTADOS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao analisar alertas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // ANALISAR UM PACIENTE
  // ══════════════════════════════════════
  List<AlertItem> _analyzePatient({
    required String patientId,
    required String patientName,
    required List<CheckinModel> checkins,
  }) {
    final alerts = <AlertItem>[];
    final now = DateTime.now();

    // ─────────────────────────────────────
    // 🔴 CRÍTICO: humor = 1
    // ─────────────────────────────────────
    if (checkins.isNotEmpty && checkins.first.moodScore == 1) {
      final lastCheckin = checkins.first;
      // Só alerta se foi nas últimas 48h
      if (now.difference(lastCheckin.createdAt).inHours <= 48) {
        alerts.add(AlertItem(
          patientId: patientId,
          patientName: patientName,
          severity: AlertSeverity.critical,
          title: 'Humor muito baixo',
          description:
              '$patientName registrou humor 1 (muito mal) '
              '${_timeAgo(lastCheckin.createdAt)}',
          detectedAt: lastCheckin.createdAt,
        ));
      }
    }

    // ─────────────────────────────────────
    // 🟡 ATENÇÃO: humor ≤ 2 por 2+ dias seguidos
    // ─────────────────────────────────────
    if (checkins.length >= 2) {
      // Agrupar por dia (pegar o mais recente de cada dia)
      final dailyCheckins = _uniqueDaily(checkins);

      int consecutiveLow = 0;
      for (final checkin in dailyCheckins) {
        if (checkin.moodScore <= 2) {
          consecutiveLow++;
        } else {
          break;
        }
      }

      if (consecutiveLow >= 2) {
        alerts.add(AlertItem(
          patientId: patientId,
          patientName: patientName,
          severity: AlertSeverity.warning,
          title: 'Humor baixo persistente',
          description:
              '$patientName está com humor ≤ 2 há $consecutiveLow dias seguidos',
          detectedAt: now,
        ));
      }
    }

    // ─────────────────────────────────────
    // 🟠 INATIVIDADE: 3+ dias sem check-in
    // ─────────────────────────────────────
    if (checkins.isEmpty) {
      alerts.add(AlertItem(
        patientId: patientId,
        patientName: patientName,
        severity: AlertSeverity.inactive,
        title: 'Paciente inativo',
        description:
            '$patientName não faz check-in há mais de 14 dias',
        detectedAt: now,
      ));
    } else {
      final lastCheckin = checkins.first;
      final daysSince = now.difference(lastCheckin.createdAt).inDays;

      if (daysSince >= 3) {
        alerts.add(AlertItem(
          patientId: patientId,
          patientName: patientName,
          severity: AlertSeverity.inactive,
          title: 'Paciente inativo',
          description:
              '$patientName não faz check-in há $daysSince dias',
          detectedAt: lastCheckin.createdAt,
        ));
      }
    }

    // ─────────────────────────────────────
    // 🟢 POSITIVO: melhora consistente
    // ─────────────────────────────────────
    if (checkins.length >= 5) {
      final dailyCheckins = _uniqueDaily(checkins);

      if (dailyCheckins.length >= 5) {
        final recent3 = dailyCheckins.take(3).toList();
        final older3 = dailyCheckins.skip(3).take(3).toList();

        if (recent3.isNotEmpty && older3.isNotEmpty) {
          final recentAvg = recent3.fold<int>(0, (s, c) => s + c.moodScore) /
              recent3.length;
          final olderAvg = older3.fold<int>(0, (s, c) => s + c.moodScore) /
              older3.length;

          if (recentAvg >= olderAvg + 1.0 && recentAvg >= 3.5) {
            alerts.add(AlertItem(
              patientId: patientId,
              patientName: patientName,
              severity: AlertSeverity.positive,
              title: 'Melhora consistente!',
              description:
                  '$patientName está apresentando melhora no humor '
                  '(média ${recentAvg.toStringAsFixed(1)} nos últimos dias)',
              detectedAt: now,
            ));
          }
        }
      }
    }

    return alerts;
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  List<CheckinModel> _uniqueDaily(List<CheckinModel> checkins) {
    final Map<String, CheckinModel> dailyMap = {};
    for (final checkin in checkins) {
      final key =
          '${checkin.createdAt.year}-${checkin.createdAt.month}-${checkin.createdAt.day}';
      if (!dailyMap.containsKey(key)) {
        dailyMap[key] = checkin;
      }
    }
    final list = dailyMap.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return 'há ${diff.inDays} dias';
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final alertProvider =
    NotifierProvider<AlertNotifier, AlertState>(AlertNotifier.new);