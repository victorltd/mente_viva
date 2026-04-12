// lib/features/psychologist/screens/scale_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_response_model.dart';
import '../../../models/scale_template_model.dart';
import '../../../providers/scale_responses_provider.dart';
import '../../../providers/scale_assignments_provider.dart';
import '../../../providers/scale_templates_provider.dart';
import '../../../providers/custom_scales_provider.dart';
import '../../../core/supabase/supabase_service.dart';

// ═══════════════════════════════════════════════════════
// SCALE RESULTS SCREEN
// Gráfico de evolução + histórico de respostas
// ═══════════════════════════════════════════════════════

class ScaleResultsScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const ScaleResultsScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<ScaleResultsScreen> createState() =>
      _ScaleResultsScreenState();
}

class _ScaleResultsScreenState extends ConsumerState<ScaleResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_initialized) return;

    try {
      debugPrint('=== SCALE RESULTS: Carregando respostas ===');
      await ref
          .read(scaleResponsesProvider.notifier)
          .loadForAssignment(widget.assignmentId);

      debugPrint('=== SCALE RESULTS: Carregando info do assignment ===');
      // Carregar info do assignment
      final client = SupabaseService.client;
      final assignmentData = await client
          .from('scale_assignments')
          .select()
          .eq('id', widget.assignmentId)
          .maybeSingle();

      if (assignmentData != null) {
        final isTemplate = assignmentData['scale_template_id'] != null;
        debugPrint('  Is Template: $isTemplate');
        
        if (isTemplate) {
          final templateId = assignmentData['scale_template_id'] as String;
          debugPrint('  Template ID: $templateId');
          await ref
              .read(scaleTemplatesProvider.notifier)
              .getTemplateById(templateId);
        } else {
          final customId = assignmentData['custom_scale_id'] as String;
          debugPrint('  Custom Scale ID: $customId');
          await ref
              .read(customScalesProvider.notifier)
              .getScaleById(customId);
        }
      } else {
        debugPrint('⚠️ Assignment não encontrado!');
      }

      setState(() => _initialized = true);
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO em _loadData: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar resultados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsesState = ref.watch(scaleResponsesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados da Escala'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Evolução'),
            Tab(icon: Icon(Icons.list_alt), text: 'Histórico'),
          ],
        ),
      ),
      body: responsesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : responsesState.responses.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEvolutionTab(responseState: responsesState),
                    _buildHistoryTab(responseState: responsesState),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Nenhuma resposta registrada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'O paciente ainda não respondeu esta escala.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // TAB EVOLUÇÃO
  // ══════════════════════════════════════
  Widget _buildEvolutionTab({
    required ScaleResponsesState responseState,
  }) {
    final evolutionData = responseState.evolutionData;
    final latest = responseState.latestResponse;
    final isImproving = responseState.isImproving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════
          // CARD ÚLTIMO RESULTADO
          // ══════════════════════════════════════
          if (latest != null) _buildLatestResultCard(latest, isImproving),

          const SizedBox(height: AppSizes.md),

          // ══════════════════════════════════════
          // GRÁFICO DE EVOLUÇÃO
          // ══════════════════════════════════════
          Text(
            'Evolução do Score',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          _buildEvolutionChart(evolutionData),

          const SizedBox(height: AppSizes.md),

          // ══════════════════════════════════════
          // SUBESCALAS (se houver)
          // ══════════════════════════════════════
          if (latest != null && latest.subscaleScores.isNotEmpty)
            _buildSubscaleBars(latest),
        ],
      ),
    );
  }

  Widget _buildLatestResultCard(
    ScaleResponseModel latest,
    bool isImproving,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Último Resultado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (isImproving)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_down, size: 14, color: AppColors.success),
                      SizedBox(width: 2),
                      Text(
                        'Melhorando',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              // Score
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${latest.totalScore}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Score',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Severidade
              Expanded(
                child: Column(
                  children: [
                    Text(
                      latest.severityLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Severidade',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Data
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${latest.completedAt.day}/${latest.completedAt.month}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      'Data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(List<ScaleEvolutionPoint> data) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Text('Dados insuficientes para o gráfico'),
        ),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.md, AppSizes.md, AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade100, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (value != idx.toDouble() || idx < 0 || idx >= data.length) {
                    return const SizedBox();
                  }
                  final date = data[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscaleBars(ScaleResponseModel latest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subescalas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: latest.subscaleScores.entries.map((entry) {
              final value = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSubscaleName(entry.key),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (value / 3).clamp(0.0, 1.0), // Normalize
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatSubscaleName(String key) {
    // Simple formatter
    return key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');
  }

  // ══════════════════════════════════════
  // TAB HISTÓRICO
  // ══════════════════════════════════════
  Widget _buildHistoryTab({required ScaleResponsesState responseState}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: responseState.responses.length,
      itemBuilder: (context, index) {
        final response = responseState.responses[index];
        return _HistoryResponseCard(
          response: response,
          onViewDetail: () => _showDetailModal(context, response),
        );
      },
    );
  }

  void _showDetailModal(BuildContext context, ScaleResponseModel response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ScaleResultDetailModal(response: response),
    );
  }
}

// ═══════════════════════════════════════════════════════
// HISTORY RESPONSE CARD
// ═══════════════════════════════════════════════════════

class _HistoryResponseCard extends StatelessWidget {
  final ScaleResponseModel response;
  final VoidCallback onViewDetail;

  const _HistoryResponseCard({
    required this.response,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Date
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    '${response.completedAt.day}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _monthName(response.completedAt.month),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Score: ${response.totalScore}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      if (response.isCritical)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error),
                              SizedBox(width: 2),
                              Text(
                                'Crítico',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    response.severityLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return months[month - 1];
  }
}

// ═══════════════════════════════════════════════════════
// SCALE RESULT DETAIL MODAL
// ═══════════════════════════════════════════════════════

class _ScaleResultDetailModal extends StatelessWidget {
  final ScaleResponseModel response;

  const _ScaleResultDetailModal({required this.response});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Text(
                        'Detalhes da Resposta',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  // Summary
                  _buildSummaryCard(context),
                  const SizedBox(height: AppSizes.md),

                  // Answers
                  Text(
                    'Respostas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...response.answers.entries.map((entry) {
                    final isCritical = response.criticalFlags
                        .any((f) => f.questionId == entry.key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? AppColors.error.withOpacity(0.05)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: isCritical
                              ? Border.all(color: AppColors.error.withOpacity(0.2))
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (isCritical) ...[
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppSizes.sm),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pergunta ${entry.key}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Resposta: ${entry.value}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  // Duration
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tempo gasto:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        response.durationFormatted,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                '${response.totalScore}',
                'Score',
                AppColors.primary,
              ),
              _buildSummaryItem(
                context,
                response.severityLabel,
                'Severidade',
                AppColors.secondary,
              ),
              _buildSummaryItem(
                context,
                '${response.answeredCount}',
                'Respondidas',
                AppColors.info,
              ),
            ],
          ),
          if (response.isCritical) ...[
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      '${response.criticalFlags.length} item(ns) crítico(s) detectado(s)',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
