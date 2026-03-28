// lib/features/legal/screens/delete_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/consent_provider.dart';
import '../../../providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _reasonController = TextEditingController();
  bool _confirmDelete = false;
  bool _understandConsequences = false;
  bool _isSubmitting = false;

  bool get _canSubmit => _confirmDelete && _understandConsequences;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consentState = ref.watch(consentProvider);

    // Se já tem exclusão pendente
    if (consentState.hasPendingDeletion) {
      return _buildPendingDeletionView(context, consentState);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluir Conta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // WARNING HEADER
            // ══════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Excluir sua conta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Esta ação é irreversível. Todos os seus dados serão '
                    'permanentemente removidos após o período de carência.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // O QUE SERÁ EXCLUÍDO
            // ══════════════════════════════════════
            Text(
              'O que será excluído:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.sm),

            _buildDeleteItem(
              context,
              icon: Icons.person,
              title: 'Perfil e dados pessoais',
              description: 'Nome, e-mail e informações de conta',
            ),
            _buildDeleteItem(
              context,
              icon: Icons.mood,
              title: 'Check-ins emocionais',
              description: 'Todo o histórico de registros de humor',
            ),
            _buildDeleteItem(
              context,
              icon: Icons.assignment,
              title: 'Tarefas e respostas',
              description: 'Todas as tarefas e suas respostas',
            ),
            _buildDeleteItem(
              context,
              icon: Icons.emoji_events,
              title: 'Conquistas',
              description: 'Todos os badges e progresso',
            ),
            _buildDeleteItem(
              context,
              icon: Icons.link_off,
              title: 'Vínculo com psicólogo',
              description: 'Conexão com seu profissional será removida',
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // PERÍODO DE CARÊNCIA
            // ══════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, color: AppColors.info, size: 20),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período de carência: 30 dias',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.info,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Após solicitar a exclusão, você terá 30 dias para '
                          'cancelar a solicitação. Após esse período, os dados '
                          'serão permanentemente removidos.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.info,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // MOTIVO (opcional)
            // ══════════════════════════════════════
            Text(
              'Por que você está saindo? (opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Seu feedback nos ajuda a melhorar...',
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // CONFIRMAÇÕES
            // ══════════════════════════════════════
            _buildCheckbox(
              title: 'Entendo as consequências',
              subtitle:
                  'Sei que todos os meus dados serão permanentemente excluídos '
                  'e não poderão ser recuperados.',
              value: _understandConsequences,
              onChanged: (v) => setState(() => _understandConsequences = v!),
            ),

            _buildCheckbox(
              title: 'Confirmo que desejo excluir',
              subtitle:
                  'Quero prosseguir com a exclusão da minha conta e todos os '
                  'dados associados.',
              value: _confirmDelete,
              onChanged: (v) => setState(() => _confirmDelete = v!),
              isDestructive: true,
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // BOTÃO DE EXCLUSÃO
            // ══════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_isSubmitting
                    ? _requestDeletion
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Solicitar Exclusão'),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Cancelar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // VIEW DE EXCLUSÃO PENDENTE
  // ══════════════════════════════════════
  Widget _buildPendingDeletionView(BuildContext context, ConsentState state) {
    final deletion = state.pendingDeletion!;
    final daysLeft = deletion.daysUntilDeletion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exclusão Solicitada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            const Spacer(),

            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                color: AppColors.warning,
                size: 64,
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            Text(
              'Exclusão em andamento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: AppSizes.sm),

            Text(
              'Sua conta será excluída em $daysLeft dias',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                  ),
            ),

            const SizedBox(height: AppSizes.md),

            Text(
              'Você solicitou a exclusão da sua conta em '
              '${_formatDate(deletion.requestedAt)}. '
              'Seus dados serão permanentemente removidos em '
              '${_formatDate(deletion.scheduledFor)}.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Cancelar exclusão
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cancelDeletion,
                child: const Text('Cancelar Exclusão'),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            Text(
              'Você pode cancelar a exclusão a qualquer momento '
              'durante o período de carência.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.delete_outline,
            color: AppColors.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: value
            ? (isDestructive
                ? AppColors.errorLight
                : AppColors.successLight.withOpacity(0.3))
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: value
              ? color.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: color,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Future<void> _requestDeletion() async {
    setState(() => _isSubmitting = true);

    final success = await ref.read(consentProvider.notifier).requestDeletion(
          reason: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação de exclusão registrada'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao solicitar exclusão. Tente novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar exclusão?'),
        content: const Text(
          'Sua conta e dados serão mantidos. Você pode solicitar '
          'exclusão novamente a qualquer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, cancelar exclusão'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(consentProvider.notifier).cancelDeletion();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exclusão cancelada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}