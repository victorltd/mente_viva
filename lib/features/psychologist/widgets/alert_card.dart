// lib/features/psychologist/widgets/alert_card.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/alert_provider.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════
              // INDICADOR DE SEVERIDADE
              // ══════════════════════════════════════
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: alert.severity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: Text(
                    alert.severity.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // ══════════════════════════════════════
              // CONTEÚDO
              // ══════════════════════════════════════
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + Badge severidade
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: alert.severity.color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alert.severity.color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            alert.severity.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: alert.severity.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),

                    // Descrição
                    Text(
                      alert.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    // Paciente
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alert.patientName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSizes.sm),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}