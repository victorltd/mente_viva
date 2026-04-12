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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

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
      GoRoute(
        path: '/psi/scale-results',
        builder: (context, state) {
          final assignmentId = state.extra as String;
          return ScaleResultsScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/psi/select-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return SelectScaleScreen(
            patientId: data['patientId'] as String,
            patientName: data['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/psi/configure-scale',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
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
          final data = state.extra as Map<String, dynamic>;
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
          final data = state.extra as Map<String, dynamic>;
          return CreateCustomScaleScreen(
            patientId: data['patientId'] as String,
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
          final task = state.extra as TaskModel;
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
          final assignmentId = state.extra as String;
          return AnswerScaleScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/app/scale-completed',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return ScaleCompletedScreen(
            hasCritical: data['hasCritical'] as bool,
            scaleName: data['scaleName'] as String,
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
}