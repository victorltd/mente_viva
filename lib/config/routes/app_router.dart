// lib/config/routes/app_router.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_psi_screen.dart';
import '../../features/auth/screens/onboarding_patient_screen.dart';
import '../../features/psychologist/screens/psi_home_screen.dart';
import '../../features/psychologist/screens/patient_detail_screen.dart';
import '../../features/psychologist/screens/alerts_screen.dart';
import '../../features/psychologist/screens/settings_screen.dart';
import '../../features/psychologist/screens/create_task_screen.dart';
import '../../features/psychologist/screens/psi_task_detail_screen.dart';
import '../../features/psychologist/screens/scale_results_screen.dart';
import '../../features/psychologist/screens/select_scale_screen.dart';
import '../../features/psychologist/screens/configure_scale_screen.dart';
import '../../features/psychologist/screens/edit_scale_screen.dart';
import '../../features/psychologist/screens/create_custom_scale_screen.dart';
import '../../features/patient/screens/patient_home_screen.dart';
import '../../features/patient/screens/checkin_screen.dart';
import '../../features/patient/screens/evolution_screen.dart';
import '../../features/patient/screens/tasks_screen.dart';
import '../../features/patient/screens/task_detail_screen.dart';
import '../../models/task_model.dart';
import '../../features/patient/screens/achievements_screen.dart';
import '../../features/patient/screens/answer_scale_screen.dart';
import '../../features/patient/screens/scale_completed_screen.dart';
import '../../features/legal/screens/consent_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/data_export_screen.dart';
import '../../features/legal/screens/delete_account_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/demo/demo_screen.dart';
import '../../core/supabase/supabase_service.dart';
import '../../config/constants/app_constants.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  StreamSubscription? _subscription;

  _AuthChangeNotifier() {
    _subscription = SupabaseService.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _authNotifier = _AuthChangeNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _authNotifier,

    redirect: _authGuard,

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Rota não encontrada: ${state.uri.path}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar para Home'),
              ),
            ],
          ),
        ),
      ),
    ),

    routes: [
      // ══════════════════════════════════════
      // SPLASH (verifica sessão)
      // ══════════════════════════════════════
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ══════════════════════════════════════
      // AUTH
      // ══════════════════════════════════════
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ══════════════════════════════════════
      // ONBOARDING
      // ══════════════════════════════════════
      GoRoute(
        path: '/onboarding/psychologist',
        builder: (context, state) => const OnboardingPsiScreen(),
      ),
      GoRoute(
        path: '/onboarding/patient',
        builder: (context, state) => const OnboardingPatientScreen(),
      ),

      // ══════════════════════════════════════
      // DEMO
      // ══════════════════════════════════════
      GoRoute(
        path: '/demo',
        name: 'demo',
        builder: (context, state) => const DemoScreen(),
      ),

      // ══════════════════════════════════════
      // PSICÓLOGO
      // ══════════════════════════════════════
      GoRoute(
        path: '/psi',
        builder: (context, state) => const PsiHomeScreen(),
      ),
      GoRoute(
        path: '/psi/patient',
        builder: (context, state) {
          final patient = state.extra as Map<String, dynamic>?;
          if (patient == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados do paciente não fornecidas')),
            );
          }
          return PatientDetailScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/psi/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/psi/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/psi/create-task',
        builder: (context, state) {
          final patient = state.extra as Map<String, dynamic>?;
          if (patient == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados do paciente não fornecidos')),
            );
          }
          return CreateTaskScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/psi/task',
        builder: (context, state) {
          final task = state.extra as TaskModel?;
          if (task == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados da tarefa não fornecidos')),
            );
          }
          return PsiTaskDetailScreen(task: task);
        },
      ),
      GoRoute(
        path: '/psi/scale-results',
        builder: (context, state) {
          final assignmentId = state.extra as String?;
          if (assignmentId == null || assignmentId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Erro: ID da escala não fornecido')),
            );
          }
          return ScaleResultsScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/psi/select-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados não fornecidos')),
            );
          }
          return SelectScaleScreen(
            patientId: data['patientId'] as String,
            patientName: data['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/psi/configure-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados não fornecidos')),
            );
          }
          return ConfigureScaleScreen(
            template: data['template'],
            customScale: data['customScale'],
            patientId: data['patientId'] as String,
            patientName: data['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/psi/edit-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados não fornecidos')),
            );
          }
          return EditScaleScreen(
            template: data['template'],
            patientId: data['patientId'] as String,
            patientName: data['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/psi/create-custom-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final patientId = data?['patientId'] as String?;
          if (patientId == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: ID do paciente não fornecido')),
            );
          }
          return CreateCustomScaleScreen(
            patientId: patientId,
          );
        },
      ),

      // ══════════════════════════════════════
      // PACIENTE
      // ══════════════════════════════════════
      GoRoute(
        path: '/app',
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: '/app/checkin',
        builder: (context, state) => const CheckinScreen(),
      ),
      GoRoute(
        path: '/app/evolution',
        builder: (context, state) => const EvolutionScreen(),
      ),
      GoRoute(
        path: '/app/tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: '/app/task',
        builder: (context, state) {
          final task = state.extra as TaskModel?;
          if (task == null) {
            return const Scaffold(
              body: Center(child: Text('Erro: Dados da tarefa não fornecidos')),
            );
          }
          return TaskDetailScreen(task: task);
        },
      ),
      GoRoute(
      path: '/app/achievements',
      builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/app/scale-answer',
        builder: (context, state) {
          final assignmentId = state.extra as String?;
          if (assignmentId == null || assignmentId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Erro: ID da escala não fornecido')),
            );
          }
          return AnswerScaleScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/app/scale-completed',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return const ScaleCompletedScreen(
              hasCritical: false,
              scaleName: 'Escala',
            );
          }
          return ScaleCompletedScreen(
            hasCritical: data['hasCritical'] as bool? ?? false,
            scaleName: data['scaleName'] as String? ?? 'Escala',
          );
        },
      ),
      GoRoute(
  path: '/legal/consent',
  builder: (context, state) {
    final redirectTo = state.extra as String? ?? '/app';
    return ConsentScreen(redirectTo: redirectTo);
  },
),
GoRoute(
  path: '/legal/terms',
  builder: (context, state) => const TermsScreen(),
),
GoRoute(
  path: '/legal/privacy',
  builder: (context, state) => const PrivacyPolicyScreen(),
),
GoRoute(
  path: '/legal/export',
  builder: (context, state) => const DataExportScreen(),
),
GoRoute(
  path: '/legal/delete-account',
  builder: (context, state) => const DeleteAccountScreen(),
),
    ],
  );

  static String? _authGuard(BuildContext context, GoRouterState state) {
    final session = SupabaseService.client.auth.currentSession;
    final isAuthenticated = session != null;
    final currentPath = state.matchedLocation;

    final publicRoutes = ['/', '/login', '/register', '/demo'];
    final isPublic = publicRoutes.contains(currentPath);

    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    if (isAuthenticated && (currentPath == '/login' || currentPath == '/register')) {
      return '/';
    }

    final role = session?.user.userMetadata?['role'] as String?;
    if (role == null) return null;

    final isPsiRoute = currentPath.startsWith('/psi');
    final isPatientRoute = currentPath.startsWith('/app');
    final isOnboardingPsi = currentPath == '/onboarding/psychologist';
    final isOnboardingPatient = currentPath == '/onboarding/patient';

    if (role == AppConstants.rolePsychologist && (isPatientRoute || isOnboardingPatient)) {
      return '/';
    }
    if (role == AppConstants.rolePatient && (isPsiRoute || isOnboardingPsi)) {
      return '/';
    }

    return null;
  }
}