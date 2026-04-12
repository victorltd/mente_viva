// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../core/widgets/menteviva_logo.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/consent_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (success && mounted) {
        // Verificar consentimento após login
        await ref.read(consentProvider.notifier).checkConsent();
        final consentState = ref.read(consentProvider);

        final profile = ref.read(authProvider).profile;
        if (profile == null) return;

        if (consentState.needsReConsent) {
          final redirectTarget = profile.isPsychologist ? '/psi' : '/app';
          context.go('/legal/consent', extra: redirectTarget);
          return;
        }

        if (profile.onboardingCompleted) {
          if (profile.isPsychologist) {
            context.go('/psi');
          } else {
            context.go('/app');
          }
        } else {
          if (profile.isPsychologist) {
            context.go('/onboarding/psychologist');
          } else {
            context.go('/onboarding/patient');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro de conexão. Verifique sua internet e tente novamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xxl),

                // ══════════════════════════════════════
                // LOGO
                // ══════════════════════════════════════
                const MenteVivaLogo(),

                const SizedBox(height: AppSizes.xxl),

                // ══════════════════════════════════════
                // TÍTULO
                // ══════════════════════════════════════
                Text(
                  'Bem-vindo de volta',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Entre na sua conta para continuar',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.xl),

                // ══════════════════════════════════════
                // EMAIL
                // ══════════════════════════════════════
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Seu email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.md),

                // ══════════════════════════════════════
                // SENHA
                // ══════════════════════════════════════
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: 'Sua senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe sua senha';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.sm),

                // Esqueceu a senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperação de senha
                    },
                    child: const Text('Esqueceu a senha?'),
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                // ══════════════════════════════════════
                // ERRO
                // ══════════════════════════════════════
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ══════════════════════════════════════
                // BOTÃO LOGIN
                // ══════════════════════════════════════
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Entrar'),
                ),

                const SizedBox(height: AppSizes.lg),

                // ══════════════════════════════════════
                // LINK PARA REGISTRO
                // ══════════════════════════════════════
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem conta?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}