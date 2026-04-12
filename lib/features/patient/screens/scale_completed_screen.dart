// lib/features/patient/screens/scale_completed_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';

// ═══════════════════════════════════════════════════════
// SCALE COMPLETED SCREEN
// Tela de confirmação após enviar uma escala
// ═══════════════════════════════════════════════════════

class ScaleCompletedScreen extends StatelessWidget {
  final bool hasCritical;
  final String scaleName;

  const ScaleCompletedScreen({
    super.key,
    required this.hasCritical,
    required this.scaleName,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Sempre vai para home, nunca volta pra tela de resposta
        context.replace('/app');
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSizes.xxl),

                  // ══════════════════════════════════════
                  // ÍCONE DE SUCESSO
                  // ══════════════════════════════════════
                  Container(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.success,
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // ══════════════════════════════════════
                  // MENSAGEM
                  // ══════════════════════════════════════
                  Text(
                    'Escala enviada!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.sm),

                  Text(
                    'Suas respostas da escala "$scaleName" foram enviadas com sucesso ao seu psicólogo.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // ══════════════════════════════════════
                  // AVISO IMPORTANTE (se item crítico)
                  // ══════════════════════════════════════
                  if (hasCritical) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.error,
                                size: 22,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'Informação importante',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'Identificamos respostas que indicam sofrimento significativo. '
                            'Seu psicólogo será notificado e entrará em contato.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Divider(),
                          const SizedBox(height: AppSizes.sm),

                          // CVV
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                  AppSizes.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                                child: const Text(
                                  '☎️',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CVV — Centro de Valorização da Vida',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      'Ligue 188 (24h, gratuito) ou acesse cvv.org.br',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                  ],

                  // ══════════════════════════════════════
                  // DICA DE AUTO-CUIDADO
                  // ══════════════════════════════════════
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Dica de auto-cuidado',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          _getRandomTip(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // ══════════════════════════════════════
                  // BOTÃO VOLTAR PARA HOME
                  // ══════════════════════════════════════
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Usa replace ao invés de go para garantir que 
                        // a home seja reconstruída e mostre escalas atualizadas
                        context.replace('/app');
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Voltar para Home'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DICAS ALEATÓRIAS
  // ══════════════════════════════════════
  String _getRandomTip() {
    final tips = [
      'Que tal fazer uma pausa de 5 minutos e respirar profundamente?',
      'Beber um copo d\'água e alongar o corpo pode ajudar a clarear a mente.',
      'Tente escrever 3 coisas pelas quais você é grato(a) hoje.',
      'Uma caminhada curta de 10 minutos pode melhorar seu humor.',
      'Converse com alguém de confiança sobre como você está se sentindo.',
      'Ouça uma música que te traz boas memórias.',
      'Pratique a técnica 5-4-3-2-1: nomeie 5 coisas que vê, 4 que toca, 3 que ouve, 2 que cheira e 1 que saboreia.',
      'Respire fundo 3 vezes: inspire por 4 segundos, segure por 4, expire por 6.',
    ];

    // Usa DateTime para variar a dica
    final index = DateTime.now().millisecondsSinceEpoch % tips.length;
    return tips[index];
  }
}
