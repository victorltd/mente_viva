// lib/features/patient/widgets/streak_calendar.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/checkin_model.dart';

class StreakCalendar extends StatelessWidget {
  final List<CheckinModel> checkins;
  final int weeksToShow;

  const StreakCalendar({
    super.key,
    required this.checkins,
    this.weeksToShow = 12,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Criar mapa de datas com check-in
    final checkinDates = <String, int>{};
    for (final checkin in checkins) {
      final date = DateTime(
        checkin.createdAt.year,
        checkin.createdAt.month,
        checkin.createdAt.day,
      );
      final key = date.toIso8601String().split('T')[0];
      checkinDates[key] = checkin.moodScore;
    }

    // Calcular data inicial (início da semana há X semanas)
    final daysBack = weeksToShow * 7;
    var startDate = today.subtract(Duration(days: daysBack));
    // Ajustar para domingo
    startDate = startDate.subtract(Duration(days: startDate.weekday % 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ══════════════════════════════════════
        // HEADER COM MESES
        // ══════════════════════════════════════
        Row(
          children: [
            const SizedBox(width: 28), // Espaço para labels dos dias
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildMonthLabels(startDate, weeksToShow),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.xs),

        // ══════════════════════════════════════
        // GRID DO CALENDÁRIO
        // ══════════════════════════════════════
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Labels dos dias da semana
            Column(
              children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                  .asMap()
                  .entries
                  .map((entry) {
                // Só mostrar alguns dias para economizar espaço
                final show = entry.key == 1 || entry.key == 3 || entry.key == 5;
                return SizedBox(
                  height: 14,
                  width: 24,
                  child: show
                      ? Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textLight,
                              ),
                        )
                      : null,
                );
              }).toList(),
            ),

            // Grid de dias
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: List.generate(weeksToShow, (weekIndex) {
                    return Column(
                      children: List.generate(7, (dayIndex) {
                        final date = startDate.add(
                          Duration(days: weekIndex * 7 + dayIndex),
                        );
                        final key = date.toIso8601String().split('T')[0];
                        final moodScore = checkinDates[key];
                        final isToday = date == today;
                        final isFuture = date.isAfter(today);

                        return _DayCell(
                          date: date,
                          moodScore: moodScore,
                          isToday: isToday,
                          isFuture: isFuture,
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.sm),

        // ══════════════════════════════════════
        // LEGENDA
        // ══════════════════════════════════════
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Menos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              final score = index + 1;
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: AppColors.moodColor(score),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              'Mais',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMonthLabels(DateTime startDate, int weeks) {
    final labels = <Widget>[];
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    int? lastMonth;
    for (int week = 0; week < weeks; week++) {
      final date = startDate.add(Duration(days: week * 7));
      if (date.month != lastMonth) {
        labels.add(
          Text(
            months[date.month - 1],
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
        );
        lastMonth = date.month;
      }
    }

    return labels;
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final int? moodScore;
  final bool isToday;
  final bool isFuture;

  const _DayCell({
    required this.date,
    this.moodScore,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isFuture) {
      color = Colors.transparent;
    } else if (moodScore != null) {
      color = AppColors.moodColor(moodScore!);
    } else {
      color = AppColors.surfaceVariant;
    }

    return Tooltip(
      message: _formatTooltip(),
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
      ),
    );
  }

  String _formatTooltip() {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    if (isFuture) return dateStr;
    if (moodScore == null) return '$dateStr\nSem check-in';

    final moodLabels = {
      1: 'Muito mal',
      2: 'Mal',
      3: 'Mais ou menos',
      4: 'Bem',
      5: 'Muito bem',
    };
    return '$dateStr\n${moodLabels[moodScore]}';
  }
}