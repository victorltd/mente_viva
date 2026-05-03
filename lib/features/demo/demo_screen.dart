// lib/features/demo/demo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../config/constants/demo_constants.dart';
import '../../core/widgets/menteviva_logo.dart';
import '../../providers/auth_provider.dart';

class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  bool _loadingPsi = false;
  bool _loadingPatient = false;
  String? _error;

  Future<void> _handleDemoLogin(DemoRole role) async {
    setState(() {
      if (role == DemoRole.psychologist) {
        _loadingPsi = true;
      } else {
        _loadingPatient = true;
      }
      _error = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.signInAsDemo(role);

    if (!mounted) return;

    setState(() {
      _loadingPsi = false;
      _loadingPatient = false;
    });

    if (success) {
      if (role == DemoRole.psychologist) {
        context.go('/psi');
      } else {
        context.go('/app');
      }
    } else {
      setState(() {
        _error = 'Não foi possível acessar o demo. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // LOGO
              // ══════════════════════════════════════
              const MenteVivaLogo(),

              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // TÍTULO
              // ══════════════════════════════════════
              Text(
                DemoConstants.pageTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                DemoConstants.pageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // CARDS
              // ══════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _DemoRoleCard(
                      icon: Icons.psychology_rounded,
                      iconColor: AppColors.primary,
                      title: DemoConstants.psiCardTitle,
                      description: DemoConstants.psiCardDescription,
                      isLoading: _loadingPsi,
                      onTap: () => _handleDemoLogin(DemoRole.psychologist),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _DemoRoleCard(
                      icon: Icons.person_rounded,
                      iconColor: AppColors.secondary,
                      title: DemoConstants.patientCardTitle,
                      description: DemoConstants.patientCardDescription,
                      isLoading: _loadingPatient,
                      onTap: () => _handleDemoLogin(DemoRole.patient),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // ERRO
              // ══════════════════════════════════════
              if (_error != null)
                Container(
                  width: double.infinity,
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

              const SizedBox(height: AppSizes.md),

              // ══════════════════════════════════════
              // AVISO
              // ══════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: AppColors.warning),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        DemoConstants.warningText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // DIVIDER + CTA
              // ══════════════════════════════════════
              const Divider(),
              const SizedBox(height: AppSizes.md),
              Text(
                DemoConstants.ctaText,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Criar conta grátis →'),
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// WIDGET: DemoRoleCard
// ══════════════════════════════════════
class _DemoRoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onTap;

  const _DemoRoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color:
              isLoading ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isLoading ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: AppSizes.sm),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onTap,
                      child: const Text('Explorar →'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
