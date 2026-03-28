// lib/features/patient/screens/evolution_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';
import '../../../providers/checkin_provider.dart';
import '../../../models/checkin_model.dart';

class EvolutionScreen extends ConsumerStatefulWidget {
  const EvolutionScreen({super.key});

  @override
  ConsumerState<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends ConsumerState<EvolutionScreen> {
  // ══════════════════════════════════════
  // FILTRO DE PERÍODO
  // ══════════════════════════════════════
  int _selectedPeriod = 7; // 7, 30, 90

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Evolução'),
      ),
      body: checkinState.checkins.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ══════════════════════════════════════
                  // SELETOR DE PERÍODO
                  // ══════════════════════════════════════
                  _buildPeriodSelector(),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // CARDS DE ESTATÍSTICAS
                  // ══════════════════════════════════════
                  _buildStatsCards(checkinState),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // GRÁFICO DE HUMOR
                  // ══════════════════════════════════════
                  Text(
                    'Humor ao longo do tempo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _buildMoodChart(checkinState),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // DISTRIBUIÇÃO DE EMOÇÕES
                  // ══════════════════════════════════════
                  Text(
                    'Emoções mais frequentes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _buildEmotionDistribution(checkinState),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // ENERGIA E SONO
                  // ══════════════════════════════════════
                  Text(
                    'Energia & Sono',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _buildEnergySleepChart(checkinState),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // INSIGHTS
                  // ══════════════════════════════════════
                  _buildInsights(checkinState),

                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════
  // FILTRAR CHECK-INS POR PERÍODO
  // ══════════════════════════════════════
  List<CheckinModel> _filteredCheckins(CheckinState state) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _selectedPeriod));

    return state.uniqueDailyCheckins
        .where((c) => c.createdAt.isAfter(cutoff))
        .toList();
  }

  // ══════════════════════════════════════
  // SELETOR DE PERÍODO
  // ══════════════════════════════════════
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _PeriodChip(
          label: '7 dias',
          isSelected: _selectedPeriod == 7,
          onTap: () => setState(() => _selectedPeriod = 7),
        ),
        const SizedBox(width: AppSizes.sm),
        _PeriodChip(
          label: '30 dias',
          isSelected: _selectedPeriod == 30,
          onTap: () => setState(() => _selectedPeriod = 30),
        ),
        const SizedBox(width: AppSizes.sm),
        _PeriodChip(
          label: '90 dias',
          isSelected: _selectedPeriod == 90,
          onTap: () => setState(() => _selectedPeriod = 90),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // CARDS DE ESTATÍSTICAS
  // ══════════════════════════════════════
  Widget _buildStatsCards(CheckinState state) {
    final filtered = _filteredCheckins(state);

    final avgMood = filtered.isEmpty
        ? 0.0
        : filtered.fold<int>(0, (sum, c) => sum + c.moodScore) /
            filtered.length;

    final bestDay = filtered.isEmpty
        ? null
        : filtered.reduce(
            (a, b) => a.moodScore >= b.moodScore ? a : b,
          );

    final worstDay = filtered.isEmpty
        ? null
        : filtered.reduce(
            (a, b) => a.moodScore <= b.moodScore ? a : b,
          );

    // Tendência: comparar média da metade recente vs metade antiga
    String trend = '→';
    Color trendColor = AppColors.textLight;
    if (filtered.length >= 4) {
      final mid = filtered.length ~/ 2;
      final recentAvg =
          filtered.sublist(0, mid).fold<int>(0, (s, c) => s + c.moodScore) /
              mid;
      final olderAvg =
          filtered.sublist(mid).fold<int>(0, (s, c) => s + c.moodScore) /
              (filtered.length - mid);

      if (recentAvg > olderAvg + 0.3) {
        trend = '↑ Melhorando';
        trendColor = AppColors.success;
      } else if (recentAvg < olderAvg - 0.3) {
        trend = '↓ Piorando';
        trendColor = AppColors.error;
      } else {
        trend = '→ Estável';
        trendColor = AppColors.info;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '📊',
                label: 'Humor médio',
                value: avgMood > 0 ? avgMood.toStringAsFixed(1) : '—',
                color: avgMood > 0
                    ? AppColors.moodColor(avgMood.round().clamp(1, 5))
                    : AppColors.textLight,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _StatCard(
                emoji: '🔥',
                label: 'Streak',
                value: '${state.streak} dias',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '📅',
                label: 'Check-ins',
                value: '${filtered.length}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _StatCard(
                emoji: '📈',
                label: 'Tendência',
                value: trend,
                color: trendColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: bestDay != null
                    ? AppConstants.moodEmojis[bestDay.moodScore]!
                    : '😊',
                label: 'Melhor dia',
                value: bestDay != null
                    ? _formatShortDate(bestDay.createdAt)
                    : '—',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _StatCard(
                emoji: worstDay != null
                    ? AppConstants.moodEmojis[worstDay.moodScore]!
                    : '😢',
                label: 'Dia difícil',
                value: worstDay != null
                    ? _formatShortDate(worstDay.createdAt)
                    : '—',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // GRÁFICO DE HUMOR
  // ══════════════════════════════════════
  Widget _buildMoodChart(CheckinState state) {
    final filtered = _filteredCheckins(state);

    if (filtered.length < 2) {
      return _buildNoDataCard('Precisa de pelo menos 2 check-ins para o gráfico');
    }

    // Ordenar por data ASC para o gráfico
    final sorted = List<CheckinModel>.from(filtered)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].moodScore.toDouble()));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
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
              return FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final intVal = value.toInt();
                  if (intVal < 1 || intVal > 5 || value != intVal.toDouble()) {
                    return const SizedBox();
                  }
                  return Text(
                    AppConstants.moodEmojis[intVal] ?? '',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _bottomInterval(sorted.length),
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (value != idx.toDouble()) return const SizedBox();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatChartDate(sorted[idx].createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sorted.length - 1).toDouble(),
          minY: 0.5,
          maxY: 5.5,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= sorted.length) return null;
                  final checkin = sorted[idx];
                  return LineTooltipItem(
                    '${AppConstants.moodEmojis[checkin.moodScore]} '
                    '${AppConstants.moodLabels[checkin.moodScore]}\n'
                    '${_formatFullDate(checkin.createdAt)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sorted.length <= 14,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.moodColor(spot.y.round()),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DISTRIBUIÇÃO DE EMOÇÕES
  // ══════════════════════════════════════
  Widget _buildEmotionDistribution(CheckinState state) {
    final filtered = _filteredCheckins(state);

    if (filtered.isEmpty) {
      return _buildNoDataCard('Sem dados neste período');
    }

    final emotionCount = <String, int>{};
    for (final checkin in filtered) {
      emotionCount[checkin.primaryEmotion] =
          (emotionCount[checkin.primaryEmotion] ?? 0) + 1;
    }

    final sorted = emotionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = filtered.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: sorted.take(5).map((entry) {
          final percentage = (entry.value / total * 100).round();
          final color =
              AppColors.emotions[entry.key] ?? AppColors.textLight;

          final emotionData = AppConstants.emotions.firstWhere(
            (e) => e['key'] == entry.key,
            orElse: () => {'emoji': '❓', 'label': entry.key},
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                Text(
                  emotionData['emoji']!,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            emotionData['label']!,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$percentage% (${entry.value}x)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════
  // ENERGIA & SONO
  // ══════════════════════════════════════
  Widget _buildEnergySleepChart(CheckinState state) {
    final filtered = _filteredCheckins(state);

    final withEnergy = filtered.where((c) => c.energyLevel != null).toList();
    final withSleep = filtered.where((c) => c.sleepQuality != null).toList();

    if (withEnergy.isEmpty && withSleep.isEmpty) {
      return _buildNoDataCard('Sem dados de energia/sono neste período');
    }

    final avgEnergy = withEnergy.isEmpty
        ? 0.0
        : withEnergy.fold<int>(0, (s, c) => s + c.energyLevel!) /
            withEnergy.length;

    final avgSleep = withSleep.isEmpty
        ? 0.0
        : withSleep.fold<int>(0, (s, c) => s + c.sleepQuality!) /
            withSleep.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Energia
          Expanded(
            child: Column(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 32)),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Energia',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  avgEnergy > 0 ? avgEnergy.toStringAsFixed(1) : '—',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  _energyLabel(avgEnergy),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.sm),
                _buildMiniBar(avgEnergy / 5, AppColors.warning),
              ],
            ),
          ),

          // Divisor
          Container(
            width: 1,
            height: 120,
            color: Colors.grey.shade200,
          ),

          // Sono
          Expanded(
            child: Column(
              children: [
                const Text('😴', style: TextStyle(fontSize: 32)),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Sono',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  avgSleep > 0 ? avgSleep.toStringAsFixed(1) : '—',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  _sleepLabel(avgSleep),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.sm),
                _buildMiniBar(avgSleep / 5, AppColors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // INSIGHTS
  // ══════════════════════════════════════
  Widget _buildInsights(CheckinState state) {
    final filtered = _filteredCheckins(state);
    if (filtered.length < 3) return const SizedBox();

    final insights = <Map<String, dynamic>>[];

    // Insight 1: Emoção mais frequente
    final emotionCount = <String, int>{};
    for (final c in filtered) {
      emotionCount[c.primaryEmotion] =
          (emotionCount[c.primaryEmotion] ?? 0) + 1;
    }
    final topEmotion = emotionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final emotionData = AppConstants.emotions.firstWhere(
      (e) => e['key'] == topEmotion.key,
      orElse: () => {'emoji': '❓', 'label': topEmotion.key},
    );
    insights.add({
      'icon': emotionData['emoji'],
      'text':
          'Sua emoção mais frequente é ${emotionData['label']?.toLowerCase()} '
              '(${topEmotion.value}x nos últimos $_selectedPeriod dias)',
    });

    // Insight 2: Melhor dia da semana
    final dayScores = <int, List<int>>{};
    for (final c in filtered) {
      dayScores.putIfAbsent(c.createdAt.weekday, () => []);
      dayScores[c.createdAt.weekday]!.add(c.moodScore);
    }
    if (dayScores.length >= 2) {
      final bestDayEntry = dayScores.entries.reduce((a, b) {
        final avgA = a.value.fold<int>(0, (s, v) => s + v) / a.value.length;
        final avgB = b.value.fold<int>(0, (s, v) => s + v) / b.value.length;
        return avgA > avgB ? a : b;
      });
      insights.add({
        'icon': '📅',
        'text':
            '${_weekDayFull(bestDayEntry.key)} costuma ser seu melhor dia da semana',
      });
    }

    // Insight 3: Streak
    if (state.streak >= 3) {
      insights.add({
        'icon': '🔥',
        'text':
            'Incrível! Você está há ${state.streak} dias consecutivos fazendo check-in!',
      });
    }

    // Insight 4: Tendência
    if (filtered.length >= 6) {
      final mid = filtered.length ~/ 2;
      final recentAvg =
          filtered.sublist(0, mid).fold<int>(0, (s, c) => s + c.moodScore) /
              mid;
      final olderAvg =
          filtered.sublist(mid).fold<int>(0, (s, c) => s + c.moodScore) /
              (filtered.length - mid);
      final diff = recentAvg - olderAvg;

      if (diff > 0.5) {
        insights.add({
          'icon': '🌟',
          'text':
              'Seu humor melhorou ${diff.toStringAsFixed(1)} pontos recentemente. Continue assim!',
        });
      } else if (diff < -0.5) {
        insights.add({
          'icon': '💜',
          'text':
              'Seu humor caiu um pouco. Lembre-se: dias difíceis também passam.',
        });
      }
    }

    if (insights.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights 💡',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.md),
        ...insights.map((insight) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['icon'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    insight['text'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════
  // WIDGETS AUXILIARES
  // ══════════════════════════════════════
  Widget _buildMiniBar(double progress, Color color) {
    return Container(
      width: 80,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 40,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
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
            Icon(
              Icons.timeline_rounded,
              size: 80,
              color: AppColors.textLight.withOpacity(0.4),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Sem dados de evolução',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Faça check-ins diários para acompanhar\nsua evolução ao longo do tempo.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  double _bottomInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    if (dataLength <= 30) return 5;
    return 10;
  }

  String _formatChartDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoje';
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${date.day}/${date.month}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month]}';
  }

  String _weekDayFull(int weekday) {
    const days = {
      1: 'Segunda-feira',
      2: 'Terça-feira',
      3: 'Quarta-feira',
      4: 'Quinta-feira',
      5: 'Sexta-feira',
      6: 'Sábado',
      7: 'Domingo',
    };
    return days[weekday] ?? '';
  }

  String _energyLabel(double avg) {
    if (avg <= 0) return '—';
    if (avg < 2) return 'Muito baixa';
    if (avg < 3) return 'Baixa';
    if (avg < 4) return 'Média';
    if (avg < 4.5) return 'Alta';
    return 'Muito alta';
  }

  String _sleepLabel(double avg) {
    if (avg <= 0) return '—';
    if (avg < 2) return 'Péssimo';
    if (avg < 3) return 'Ruim';
    if (avg < 4) return 'Regular';
    if (avg < 4.5) return 'Bom';
    return 'Excelente';
  }
}

// ══════════════════════════════════════
// WIDGETS EXTRAÍDOS
// ══════════════════════════════════════
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}