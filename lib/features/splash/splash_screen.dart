// lib/features/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../core/widgets/menteviva_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consent_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    
    Future.microtask(() => _initializeApp());
  }

  Future<void> _initializeApp() async {
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('🚀 Iniciando MenteViva...');
    debugPrint('══════════════════════════════════════════════════════════');

    try {
      // Aguardar um tempo mínimo para mostrar o splash
      await Future.delayed(const Duration(milliseconds: 2000));

      // Verificar autenticação
      await ref.read(authProvider.notifier).checkAuth();

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (!authState.isAuthenticated || authState.profile == null) {
        debugPrint('👤 Usuário não autenticado → /login');
        context.go('/login');
        return;
      }

      final profile = authState.profile!;
      debugPrint('👤 Usuário: ${profile.fullName} (${profile.role})');

      // Verificar consentimento
      await ref.read(consentProvider.notifier).checkConsent();
      final consentState = ref.read(consentProvider);

      if (consentState.needsReConsent) {
        debugPrint('📋 Precisa re-consentir → /legal/consent');
        final redirectTarget = profile.isPsychologist ? '/psi' : '/app';
        context.go('/legal/consent', extra: redirectTarget);
        return;
      }

      // Verificar onboarding
      if (!profile.onboardingCompleted) {
        debugPrint('📝 Onboarding pendente');
        if (profile.isPsychologist) {
          context.go('/onboarding/psychologist');
        } else {
          context.go('/onboarding/patient');
        }
        return;
      }

      // Navegar para home
      if (profile.isPsychologist) {
        debugPrint('🏠 Redirecionando → /psi');
        context.go('/psi');
      } else {
        debugPrint('🏠 Redirecionando → /app');
        context.go('/app');
      }

      debugPrint('══════════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar app: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ══════════════════════════════════════
              // LOGO
              // ══════════════════════════════════════
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: MenteVivaLogo(
                    size: 60,
                    showText: false,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // ══════════════════════════════════════
              // NOME DO APP
              // ══════════════════════════════════════
              Text(
                'MenteViva',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),

              const SizedBox(height: AppSizes.sm),

              Text(
                'Cuidando da sua saúde mental',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ══════════════════════════════════════
              // LOADING INDICATOR
              // ══════════════════════════════════════
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
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