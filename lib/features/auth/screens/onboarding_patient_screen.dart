// lib/features/auth/screens/onboarding_patient_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../providers/auth_provider.dart';

class OnboardingPatientScreen extends ConsumerStatefulWidget {
  const OnboardingPatientScreen({super.key});

  @override
  ConsumerState<OnboardingPatientScreen> createState() =>
      _OnboardingPatientScreenState();
}

class _OnboardingPatientScreenState
    extends ConsumerState<OnboardingPatientScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _foundPatient;
  bool _linked = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  // BUSCAR CÓDIGO
  // ══════════════════════════════════════
  Future<void> _searchInviteCode() async {
    final code = _inviteCodeController.text.trim().toLowerCase();

    if (code.isEmpty) {
      setState(() => _error = 'Digite o código de convite');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _foundPatient = null;
    });

    try {
      final response = await SupabaseService.client
          .from('patients')
          .select('*, psychologists(id, crp, profiles(full_name))')
          .eq('invite_code', code)
          .isFilter('user_id', null)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _foundPatient = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Código não encontrado ou já utilizado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar código: $e';
        _isLoading = false;
      });
    }
  }

  // ══════════════════════════════════════
  // VINCULAR (usando a função do Supabase)
  // ══════════════════════════════════════
  Future<void> _linkPatient() async {
    if (_foundPatient == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final code = _inviteCodeController.text.trim().toLowerCase();

      // Chamar função do Supabase (bypassa RLS)
      final result = await SupabaseService.client.rpc(
        'link_patient_to_user',
        params: {
          'p_invite_code': code,
          'p_user_id': userId,
        },
      );

      print('=== LINK RESULT: $result ===');

      if (result != null && result['success'] == true) {
        // Marcar onboarding como completo
        await ref.read(authProvider.notifier).updateProfile(
              onboardingCompleted: true,
            );

        setState(() {
          _linked = true;
          _isLoading = false;
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          context.go('/app');
        }
      } else {
        setState(() {
          _error = result?['error'] ?? 'Erro ao vincular';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao vincular: $e';
        _isLoading = false;
      });
    }
  }

  String _getPsychologistName() {
    try {
      final psi = _foundPatient!['psychologists'];
      final profile = psi['profiles'];
      return profile['full_name'] ?? 'Psicólogo';
    } catch (_) {
      return 'Psicólogo';
    }
  }

  String _getPsychologistCrp() {
    try {
      return _foundPatient!['psychologists']['crp'] ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar ao Psicólogo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.lg),

              // ÍCONE
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              Text(
                'Código de Convite',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Seu psicólogo deve ter enviado um código de convite. '
                'Digite abaixo para vincular sua conta.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.xl),

              // SUCESSO
              if (_linked) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'Conectado com sucesso! 🎉',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppColors.success),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Redirecionando...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ]

              // FORMULÁRIO
              else ...[
                TextFormField(
                  controller: _inviteCodeController,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.none,
                  onFieldSubmitted: (_) => _searchInviteCode(),
                  decoration: InputDecoration(
                    hintText: 'Ex: a1b2c3d4',
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    labelText: 'Código de convite',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchInviteCode,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.md),

                // Erro
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Loading
                if (_isLoading && _foundPatient == null)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                // Encontrado
                if (_foundPatient != null) ...[
                  const SizedBox(height: AppSizes.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 40,
                          color: AppColors.info,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Psicólogo encontrado!',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.info),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          _getPsychologistName(),
                          style:
                              Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'CRP: ${_getPsychologistCrp()}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _linkPatient,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Vincular minha conta'),
                  ),
                ],

                // Buscar
                if (_foundPatient == null && !_isLoading) ...[
                  const SizedBox(height: AppSizes.md),
                  ElevatedButton(
                    onPressed: _searchInviteCode,
                    child: const Text('Buscar'),
                  ),
                ],

                const SizedBox(height: AppSizes.xxl),

                // Info
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'Não tem um código? Peça ao seu psicólogo '
                          'para te cadastrar no MenteViva e enviar '
                          'o código de convite.',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}