// lib/features/auth/screens/onboarding_psi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../providers/auth_provider.dart';

class OnboardingPsiScreen extends ConsumerStatefulWidget {
  const OnboardingPsiScreen({super.key});

  @override
  ConsumerState<OnboardingPsiScreen> createState() =>
      _OnboardingPsiScreenState();
}

class _OnboardingPsiScreenState extends ConsumerState<OnboardingPsiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _selectedApproaches = [];

  final List<Map<String, String>> _approaches = [
    {'key': 'TCC', 'label': 'Terapia Cognitivo-Comportamental'},
    {'key': 'Psicanálise', 'label': 'Psicanálise'},
    {'key': 'Humanista', 'label': 'Humanista'},
    {'key': 'Comportamental', 'label': 'Comportamental'},
    {'key': 'Sistêmica', 'label': 'Terapia Sistêmica'},
    {'key': 'ACT', 'label': 'Terapia de Aceitação e Compromisso'},
    {'key': 'Gestalt', 'label': 'Gestalt-terapia'},
    {'key': 'Junguiana', 'label': 'Psicologia Analítica (Jung)'},
    {'key': 'Esquema', 'label': 'Terapia do Esquema'},
    {'key': 'Mindfulness', 'label': 'Baseada em Mindfulness'},
    {'key': 'Outra', 'label': 'Outra'},
  ];

  @override
  void dispose() {
    _crpController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      // 1. Criar registro na tabela psychologists
      await SupabaseService.client.from('psychologists').insert({
        'id': userId,
        'crp': _crpController.text.trim(),
        'approach': _selectedApproaches,
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      });

      // 2. Marcar onboarding como completo
      await ref.read(authProvider.notifier).updateProfile(
            onboardingCompleted: true,
          );

      if (mounted) {
        context.go('/psi');
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_crpController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe seu CRP'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_selectedApproaches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione pelo menos uma abordagem'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Perfil'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _currentStep--);
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ══════════════════════════════════════
              // INDICADOR DE PROGRESSO
              // ══════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ══════════════════════════════════════
              // CONTEÚDO
              // ══════════════════════════════════════
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: _buildStep(),
                ),
              ),

              // ══════════════════════════════════════
              // BOTÃO
              // ══════════════════════════════════════
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep < 2 ? 'Próximo' : 'Concluir',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════
  // STEP 1: Dados profissionais
  // ══════════════════════════════════════
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: const Icon(
            Icons.badge_outlined,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Dados Profissionais',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Informe seu registro profissional para validarmos sua conta.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.xl),
        TextFormField(
          controller: _crpController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Número do CRP (ex: 06/123456)',
            prefixIcon: Icon(Icons.verified_outlined),
            labelText: 'CRP',
          ),
        ),
        const SizedBox(height: AppSizes.md),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: '(11) 99999-9999',
            prefixIcon: Icon(Icons.phone_outlined),
            labelText: 'Telefone (opcional)',
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 2: Abordagem
  // ══════════════════════════════════════
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            size: 32,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Abordagem Terapêutica',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Selecione as abordagens que você utiliza. '
          'Isso nos ajuda a personalizar as ferramentas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.xl),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: _approaches.map((approach) {
            final isSelected =
                _selectedApproaches.contains(approach['key']);
            return FilterChip(
              label: Text(approach['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedApproaches.add(approach['key']!);
                  } else {
                    _selectedApproaches.remove(approach['key']);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusFull),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 3: Bio + Resumo
  // ══════════════════════════════════════
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: const Icon(
            Icons.rocket_launch_outlined,
            size: 32,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Quase pronto!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Adicione uma breve descrição sobre você (opcional).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.xl),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 300,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText:
                'Ex: Psicóloga clínica com 5 anos de experiência...',
            labelText: 'Sobre você (opcional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Resumo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo do seu perfil',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.md),
              _buildSummaryRow(
                Icons.badge_outlined,
                'CRP',
                _crpController.text,
              ),
              const SizedBox(height: AppSizes.sm),
              _buildSummaryRow(
                Icons.psychology_outlined,
                'Abordagens',
                _selectedApproaches.join(', '),
              ),
              if (_phoneController.text.isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                _buildSummaryRow(
                  Icons.phone_outlined,
                  'Telefone',
                  _phoneController.text,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}