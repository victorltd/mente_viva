// lib/features/legal/screens/data_export_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/consent_provider.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  Map<String, dynamic>? _exportedData;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Dados'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // HEADER
            // ══════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download,
                      color: AppColors.info,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Seus Dados',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Conforme a LGPD, você tem direito de acessar todos os '
                    'dados pessoais que armazenamos sobre você.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.info.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // O QUE SERÁ EXPORTADO
            // ══════════════════════════════════════
            Text(
              'O que será exportado:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.sm),

            _buildExportItem(
              context,
              icon: Icons.person,
              title: 'Dados do Perfil',
              description: 'Nome, e-mail, data de cadastro',
            ),
            _buildExportItem(
              context,
              icon: Icons.mood,
              title: 'Check-ins Emocionais',
              description: 'Todos os seus registros de humor',
            ),
            _buildExportItem(
              context,
              icon: Icons.assignment,
              title: 'Tarefas e Respostas',
              description: 'Tarefas completadas e suas respostas',
            ),
            _buildExportItem(
              context,
              icon: Icons.emoji_events,
              title: 'Conquistas',
              description: 'Badges desbloqueados',
            ),
            _buildExportItem(
              context,
              icon: Icons.verified_user,
              title: 'Registros de Consentimento',
              description: 'Histórico de aceites de termos',
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // BOTÃO EXPORTAR
            // ══════════════════════════════════════
            if (_exportedData == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportData,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isExporting ? 'Exportando...' : 'Exportar Meus Dados'),
                ),
              ),

            // ══════════════════════════════════════
            // DADOS EXPORTADOS
            // ══════════════════════════════════════
            if (_exportedData != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Dados exportados com sucesso!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.success,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.md),

              // Resumo
              _buildDataSummary(context),

              const SizedBox(height: AppSizes.md),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar JSON'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _viewFullData,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Completo'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.md),

              // Exportar novamente
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() => _exportedData = null),
                  child: const Text('Exportar Novamente'),
                ),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // AVISO
            // ══════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Os dados são exportados em formato JSON. '
                      'Guarde-os em local seguro, pois contêm informações '
                      'sensíveis sobre sua saúde.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportItem(
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
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
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
            Icons.check,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummary(BuildContext context) {
    final data = _exportedData!;
    final checkins = (data['checkins'] as List?)?.length ?? 0;
    final tasks = (data['task_responses'] as List?)?.length ?? 0;
    final achievements = (data['achievements'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo dos dados:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              _buildSummaryChip(context, '$checkins', 'Check-ins'),
              const SizedBox(width: AppSizes.sm),
              _buildSummaryChip(context, '$tasks', 'Tarefas'),
              const SizedBox(width: AppSizes.sm),
              _buildSummaryChip(context, '$achievements', 'Conquistas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    final data = await ref.read(consentProvider.notifier).exportUserData();

    setState(() {
      _isExporting = false;
      _exportedData = data;
    });

    if (data == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao exportar dados. Tente novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (_exportedData == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(_exportedData);
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados copiados para a área de transferência'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _viewFullData() {
    if (_exportedData == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(_exportedData);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSizes.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Text(
                      'Dados Completos (JSON)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}