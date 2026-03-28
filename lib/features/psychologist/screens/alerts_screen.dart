// lib/features/psychologist/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/alert_provider.dart';
import '../widgets/alert_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(alertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          if (alertState.actionableCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSizes.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${alertState.actionableCount} pendentes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: alertState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alertState.alerts.isEmpty
              ? _buildEmptyState(context)
              : _buildAlertsList(context, ref, alertState),
    );
  }

  // ══════════════════════════════════════
  // LISTA DE ALERTAS
  // ══════════════════════════════════════
  Widget _buildAlertsList(
    BuildContext context,
    WidgetRef ref,
    AlertState alertState,
  ) {
    // Separar por categoria
    final criticals = alertState.alerts
        .where((a) => a.severity == AlertSeverity.critical)
        .toList();
    final warnings = alertState.alerts
        .where((a) => a.severity == AlertSeverity.warning)
        .toList();
    final inactives = alertState.alerts
        .where((a) => a.severity == AlertSeverity.inactive)
        .toList();
    final positives = alertState.alerts
        .where((a) => a.severity == AlertSeverity.positive)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════
          // RESUMO
          // ══════════════════════════════════════
          _buildSummaryRow(context, alertState),

          const SizedBox(height: AppSizes.lg),

          // ══════════════════════════════════════
          // CRÍTICOS
          // ══════════════════════════════════════
          if (criticals.isNotEmpty) ...[
            _buildSectionHeader(context, '🔴 Críticos', criticals.length),
            const SizedBox(height: AppSizes.sm),
            ...criticals.map((alert) => AlertCard(
                  alert: alert,
                  onTap: () => _goToPatient(context, ref, alert),
                )),
            const SizedBox(height: AppSizes.lg),
          ],

          // ══════════════════════════════════════
          // ATENÇÃO
          // ══════════════════════════════════════
          if (warnings.isNotEmpty) ...[
            _buildSectionHeader(context, '🟡 Atenção', warnings.length),
            const SizedBox(height: AppSizes.sm),
            ...warnings.map((alert) => AlertCard(
                  alert: alert,
                  onTap: () => _goToPatient(context, ref, alert),
                )),
            const SizedBox(height: AppSizes.lg),
          ],

          // ══════════════════════════════════════
          // INATIVIDADE
          // ══════════════════════════════════════
          if (inactives.isNotEmpty) ...[
            _buildSectionHeader(context, '🟠 Inatividade', inactives.length),
            const SizedBox(height: AppSizes.sm),
            ...inactives.map((alert) => AlertCard(
                  alert: alert,
                  onTap: () => _goToPatient(context, ref, alert),
                )),
            const SizedBox(height: AppSizes.lg),
          ],

          // ══════════════════════════════════════
          // POSITIVOS
          // ══════════════════════════════════════
          if (positives.isNotEmpty) ...[
            _buildSectionHeader(context, '🟢 Positivos', positives.length),
            const SizedBox(height: AppSizes.sm),
            ...positives.map((alert) => AlertCard(
                  alert: alert,
                  onTap: () => _goToPatient(context, ref, alert),
                )),
          ],

          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // RESUMO TOP
  // ══════════════════════════════════════
  Widget _buildSummaryRow(BuildContext context, AlertState state) {
    return Row(
      children: [
        _MiniStat(
          emoji: '🔴',
          count: state.criticalCount,
          label: 'Críticos',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(width: AppSizes.sm),
        _MiniStat(
          emoji: '🟡',
          count: state.warningCount,
          label: 'Atenção',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: AppSizes.sm),
        _MiniStat(
          emoji: '🟠',
          count: state.inactiveCount,
          label: 'Inativos',
          color: const Color(0xFFF97316),
        ),
        const SizedBox(width: AppSizes.sm),
        _MiniStat(
          emoji: '🟢',
          count: state.positiveCount,
          label: 'Positivos',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // ESTADO VAZIO
  // ══════════════════════════════════════
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Tudo tranquilo! ✨',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Nenhum alerta no momento.\nSeus pacientes estão bem.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // NAVEGAR PARA PACIENTE
  // ══════════════════════════════════════
  void _goToPatient(BuildContext context, WidgetRef ref, AlertItem alert) {
    // Precisamos do Map do paciente para a rota
    // Construímos um mínimo para navegação
    context.push('/psi/patient', extra: {
      'id': alert.patientId,
      'full_name': alert.patientName,
      'status': 'active',
    });
  }
}

// ══════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color color;

  const _MiniStat({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.sm,
          horizontal: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}