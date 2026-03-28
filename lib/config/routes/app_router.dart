// lib/config/routes/app_router.dart

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
import '../../features/patient/screens/patient_home_screen.dart';
import '../../features/patient/screens/checkin_screen.dart';
import '../../features/patient/screens/evolution_screen.dart';
import '../../features/patient/screens/tasks_screen.dart';
import '../../features/patient/screens/task_detail_screen.dart';
import '../../models/task_model.dart';
import '../../features/patient/screens/achievements_screen.dart';
import '../../features/legal/screens/consent_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/data_export_screen.dart';
import '../../features/legal/screens/delete_account_screen.dart';


class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,

    routes: [
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
      // PSICÓLOGO
      // ══════════════════════════════════════
      GoRoute(
        path: '/psi',
        builder: (context, state) => const PsiHomeScreen(),
      ),
      GoRoute(
        path: '/psi/patient',
        builder: (context, state) {
          final patient = state.extra as Map<String, dynamic>;
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
          final patient = state.extra as Map<String, dynamic>;
          return CreateTaskScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/psi/task',
        builder: (context, state) {
          final task = state.extra as TaskModel;
          return PsiTaskDetailScreen(task: task);
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
          final task = state.extra as TaskModel;
          return TaskDetailScreen(task: task);
        },
      ),
      GoRoute(
      path: '/app/achievements',
      builder: (context, state) => const AchievementsScreen(),
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
}