// lib/features/psychologist/screens/psi_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/feature_provider.dart';
import '../../demo/demo_banner.dart';
import '../../../config/constants/demo_constants.dart';

class PsiHomeScreen extends ConsumerStatefulWidget {
  const PsiHomeScreen({super.key});

  @override
  ConsumerState<PsiHomeScreen> createState() => _PsiHomeScreenState();
}

class _PsiHomeScreenState extends ConsumerState<PsiHomeScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    await _loadPatients();
    // Carregar features do psicólogo
    ref.read(featureProvider.notifier).loadFeatures();
    // Calcular alertas após carregar pacientes
    ref.read(alertProvider.notifier).loadAlerts(_patients);
  }

  Future<void> _loadPatients() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final response = await SupabaseService.client
          .from('patients')
          .select()
          .eq('psychologist_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPatient() async {
    final authState = ref.read(authProvider);

    if (authState.isDemoMode) {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.lock_outline_rounded,
              size: 48, color: AppColors.textLight),
          title: const Text(DemoConstants.blockedTitle),
          content: const Text(DemoConstants.blockedDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(DemoConstants.blockedCta),
            ),
          ],
        ),
      );
      if (result == true && mounted) {
        context.go('/register');
      }
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nome do paciente',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final userId = SupabaseService.currentUserId;
        if (userId == null) return;

        await SupabaseService.client.from('patients').insert({
          'psychologist_id': userId,
          'full_name': nameController.text.trim(),
          'email': emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          'status': 'pending',
        });

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente adicionado! ✅'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final alertState = ref.watch(alertProvider);
    final firstName = authState.profile?.fullName?.split(' ').first ?? '';

    return Scaffold(
      // ══════════════════════════════════════
      // APP BAR
      // ══════════════════════════════════════
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const Text('MenteViva'),
          ],
        ),
        actions: [
          // ══════════════════════════════════════
          // 🔔 BADGE DE ALERTAS
          // ══════════════════════════════════════
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/psi/alerts'),
              ),
              if (alertState.actionableCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: alertState.criticalCount > 0
                          ? AppColors.error
                          : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${alertState.actionableCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                  
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sair', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'settings') {
                context.push('/psi/settings');
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).signOut();
                if (mounted) context.go('/');
              }
            },
          ),
        ],
      ),

      // ══════════════════════════════════════
      // BODY
      // ══════════════════════════════════════
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════
              // BANNER DEMO
              // ══════════════════════════════════════
              if (authState.isDemoMode) const DemoBanner(),

              // ══════════════════════════════════════
              // SAUDAÇÃO
              // ══════════════════════════════════════
              Text(
                'Olá, $firstName! 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Veja como seus pacientes estão.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // ALERTAS RESUMO (se houver)
              // ══════════════════════════════════════
              if (alertState.actionableCount > 0) ...[
                _buildAlertsBanner(context, alertState),
                const SizedBox(height: AppSizes.lg),
              ],

              // ══════════════════════════════════════
              // CARDS DE ESTATÍSTICAS
              // ══════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_outline,
                      label: 'Pacientes',
                      value: '${_patients.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      label: 'Pendentes',
                      value:
                          '${_patients.where((p) => p['status'] == 'pending').length}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Ativos',
                      value:
                          '${_patients.where((p) => p['status'] == 'active').length}',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // LISTA DE PACIENTES
              // ══════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seus Pacientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: _addPatient,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.xxl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_patients.isEmpty)
                _EmptyPatientsState(onAdd: _addPatient)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    return _PatientCard(
                      patient: patient,
                      alertSeverity: alertState
                          .worstSeverityForPatient(patient['id'] as String),
                      onTap: () {
                        context.push('/psi/patient', extra: patient);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),

      // ══════════════════════════════════════
      // FAB
      // ══════════════════════════════════════
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatient,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Paciente'),
      ),
    );
  }

  // ══════════════════════════════════════
  // BANNER DE ALERTAS
  // ══════════════════════════════════════
  Widget _buildAlertsBanner(BuildContext context, AlertState alertState) {
    final hasCritical = alertState.criticalCount > 0;

    return GestureDetector(
      onTap: () => context.push('/psi/alerts'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: hasCritical
              ? AppColors.error.withOpacity(0.05)
              : AppColors.warning.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: hasCritical
                ? AppColors.error.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: hasCritical
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                hasCritical
                    ? Icons.warning_rounded
                    : Icons.info_outlined,
                color: hasCritical ? AppColors.error : AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCritical
                        ? '${alertState.criticalCount} alerta(s) crítico(s)'
                        : '${alertState.actionableCount} alerta(s) pendente(s)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: hasCritical
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toque para ver detalhes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final AlertSeverity? alertSeverity;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    this.alertSeverity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = patient['status'] == 'active';
    final isPending = patient['status'] == 'pending';
    final inviteCode = patient['invite_code'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // Avatar com indicador de alerta
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    child: Text(
                      (patient['full_name'] as String? ?? '?')[0]
                          .toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Badge de alerta no avatar
                  if (alertSeverity != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: alertSeverity!.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSizes.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['full_name'] ?? 'Sem nome',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    if (isPending)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              'Pendente',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Código: $inviteCode',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ativo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.success),
                          ),
                          // Alerta inline
                          if (alertSeverity != null &&
                              alertSeverity != AlertSeverity.positive) ...[
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              alertSeverity!.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              alertSeverity!.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: alertSeverity!.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPatientsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPatientsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Nenhum paciente ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Adicione seu primeiro paciente para começar a usar o MenteViva',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar Paciente'),
          ),
        ],
      ),
    );
  }
}