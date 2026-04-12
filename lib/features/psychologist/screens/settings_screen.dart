// lib/features/psychologist/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feature_provider.dart';
import '../../../providers/consent_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final featureState = ref.watch(featureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // PERFIL
            // ══════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (authState.profile?.fullName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.profile?.fullName ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.profile?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // ══════════════════════════════════════
            // FUNCIONALIDADES
            // ══════════════════════════════════════
            Text(
              'Funcionalidades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Escolha quais recursos ativar para seus pacientes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.md),

            // Check-ins (sempre ativo)
            _FeatureTile(
              emoji: '😊',
              title: 'Check-ins Emocionais',
              description: 'Pacientes registram humor diário',
              isEnabled: true,
              isLocked: true,
              onChanged: null,
            ),

            // Alertas (sempre ativo)
            _FeatureTile(
              emoji: '🔔',
              title: 'Sistema de Alertas',
              description: 'Notificações sobre seus pacientes',
              isEnabled: true,
              isLocked: true,
              onChanged: null,
            ),

            // Evolução (sempre ativo)
            _FeatureTile(
              emoji: '📈',
              title: 'Evolução do Paciente',
              description: 'Gráficos e insights de progresso',
              isEnabled: true,
              isLocked: true,
              onChanged: null,
            ),

            const Divider(height: AppSizes.xl),

            Text(
              'Recursos opcionais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.md),

            // Tarefas (toggle)
            _FeatureTile(
              emoji: '📋',
              title: 'Tarefas Terapêuticas',
              description:
                  'Crie exercícios e atividades para seus pacientes',
              isEnabled: featureState.tasksEnabled,
              isLocked: false,
              onChanged: (value) {
                ref
                    .read(featureProvider.notifier)
                    .toggleFeature('tasks', value);
              },
            ),

            // Chat (toggle — futuro)
            _FeatureTile(
              emoji: '💬',
              title: 'Chat',
              description: 'Mensagens entre psicólogo e paciente',
              isEnabled: featureState.chatEnabled,
              isLocked: false,
              isComingSoon: true,
              onChanged: null,
            ),

            const SizedBox(height: AppSizes.xl),

            // ══════════════════════════════════════
            // CONTA
            // ══════════════════════════════════════
            Text(
              'Conta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Sair da conta',
                      style: TextStyle(color: AppColors.error),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sair'),
                          content: const Text(
                            'Tem certeza que deseja sair?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Sair'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // SEÇÃO LEGAL E PRIVACIDADE
            // ══════════════════════════════════════
            Text(
              'Legal e Privacidade',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.sm),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Termos de Uso',
                    onTap: () => context.push('/legal/terms'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de Privacidade',
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context,
                    icon: Icons.download_outlined,
                    title: 'Exportar Meus Dados',
                    subtitle: 'Baixe uma cópia dos seus dados',
                    onTap: () => context.push('/legal/export'),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context,
                    icon: Icons.delete_forever_outlined,
                    title: 'Excluir Conta',
                    subtitle: 'Remover permanentemente seus dados',
                    textColor: AppColors.error,
                    onTap: () => context.push('/legal/delete-account'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Versão
            Center(
              child: Text(
                'MenteViva v1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════
// WIDGET: FEATURE TILE
// ══════════════════════════════════════
class _FeatureTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool isEnabled;
  final bool isLocked;
  final bool isComingSoon;
  final ValueChanged<bool>? onChanged;

  const _FeatureTile({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.isLocked,
    this.isComingSoon = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isEnabled && !isComingSoon
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEnabled && !isComingSoon
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: const Text(
                          'Incluso',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isComingSoon) ...[
                      const SizedBox(width: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: const Text(
                          'Em breve',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Toggle
          if (!isLocked && !isComingSoon)
            Switch.adaptive(
              value: isEnabled,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            )
          else if (isLocked)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            )
          else
            Icon(
              Icons.lock_outline,
              color: AppColors.textLight.withOpacity(0.5),
              size: 24,
            ),
        ],
      ),
    );
  }
}