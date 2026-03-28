// lib/features/legal/screens/consent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/legal_constants.dart';
import '../../../providers/consent_provider.dart';
import '../../../providers/auth_provider.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  final String redirectTo;

  const ConsentScreen({
    super.key,
    required this.redirectTo,
  });

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedDataSharing = false;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      _acceptedTerms && _acceptedPrivacy && _acceptedDataSharing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════
            // HEADER
            // ══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Termos e Privacidade',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Para continuar, leia e aceite nossos termos',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ══════════════════════════════════════
            // CONTENT
            // ══════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
                              LegalConstants.appDisclaimer,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // Resumo dos termos
                    Text(
                      'Resumo dos pontos principais:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.sm),

                    ...LegalConstants.termsHighlights.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                item,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppSizes.lg),

                    // CFP Notice (se for psicólogo)
                    if (ref.watch(authProvider).profile?.role == 'psychologist')
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        margin: const EdgeInsets.only(bottom: AppSizes.lg),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.psychology,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text(
                                  'Resolução CFP nº 11/2018',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: AppColors.info),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              LegalConstants.cfpPsychologistNotice,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.info,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),

                    const Divider(),
                    const SizedBox(height: AppSizes.md),

                    // ══════════════════════════════════════
                    // CHECKBOXES
                    // ══════════════════════════════════════
                    _buildCheckbox(
                      title: 'Termos de Uso',
                      subtitle: 'Li e aceito os Termos de Uso do MenteViva',
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v!),
                      onTapLink: () => context.push('/legal/terms'),
                    ),

                    _buildCheckbox(
                      title: 'Política de Privacidade',
                      subtitle:
                          'Li e aceito a Política de Privacidade (LGPD)',
                      value: _acceptedPrivacy,
                      onChanged: (v) => setState(() => _acceptedPrivacy = v!),
                      onTapLink: () => context.push('/legal/privacy'),
                    ),

                    _buildCheckbox(
                      title: 'Compartilhamento de Dados',
                      subtitle:
                          'Autorizo o compartilhamento das minhas informações '
                          'de saúde com meu psicólogo para fins de tratamento',
                      value: _acceptedDataSharing,
                      onChanged: (v) =>
                          setState(() => _acceptedDataSharing = v!),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // Versão
                    Center(
                      child: Text(
                        'Versão ${LegalConstants.termsVersion} • '
                        'Atualizado em ${LegalConstants.lastUpdated}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════
            // FOOTER
            // ══════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isSubmitting
                        ? _submitConsent
                        : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Aceitar e Continuar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onTapLink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: value ? AppColors.successLight.withOpacity(0.3) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: value ? AppColors.success.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.success,
        title: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (onTapLink != null) ...[
              const SizedBox(width: AppSizes.xs),
              GestureDetector(
                onTap: onTapLink,
                child: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
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

  Future<void> _submitConsent() async {
    setState(() => _isSubmitting = true);

    final success = await ref.read(consentProvider.notifier).giveConsent();

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      context.go(widget.redirectTo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao registrar consentimento. Tente novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}