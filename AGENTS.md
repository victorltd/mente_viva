# AGENTS.md — MenteViva

Flutter web app for mental-health therapy (psychologists + patients).

## Stack & entry

- Flutter (Dart), Riverpod 3.x (`Notifier`/`NotifierProvider`), go_router 17.x, Supabase
- `main.dart` → `SupabaseService.initialize()` → `ProviderScope(MenteVivaApp)` → `MaterialApp.router` with `AppRouter.router`
- `Enables web` via `flutter config --enable-web`; deploy target: Vercel (SPA rewrites to `index.html`)

## Commands

```bash
# Dev (web, Windows):
run_dev.bat

# Lint (always before committing):
flutter analyze

# Tests (minimal — no Supabase dependency):
flutter test

# Production build (Windows):
set SUPABASE_URL=... && set SUPABASE_ANON_KEY=... && build_production.bat

# Production build (Unix / Vercel CI):
SUPABASE_URL=... SUPABASE_ANON_KEY=... ./build_production.sh

# Deploy:
vercel --prod
```

**Env vars** are injected via `--dart-define` at build time (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `PRODUCTION`). Dev defaults live in `lib/config/env.dart`. Never commit `.env.development`.

## Architecture

```
lib/
  config/routes/app_router.dart  # ALL routes + auth redirect guard
  config/env.dart                # String.fromEnvironment (dev defaults in-code)
  config/theme/                  # app_colors, app_sizes, app_theme
  core/supabase/supabase_service.dart  # Supabase singleton
  providers/                     # One NotifierProvider per domain
  features/{auth,patient,psychologist,legal,splash}/
  models/                        # Pure Dart models (fromJson/toJson/copyWith)
  services/                      # pdf_generator_service.dart
```

## Hard rules (will break the app if violated)

1. **Use `Notifier` + `NotifierProvider`** for all state. Never `ChangeNotifier` or old `package:provider`.
2. **Use `context.go()`** for navigation. Never `Navigator.push`.
3. **`patient_id` in all tables = `patients.id`** (auto-generated UUID). It is NEVER `auth.uid()`. A patient's `auth.uid()` is `patients.user_id` — used only to find the patient record (`patients.user_id = auth.uid()`).
4. **Always access Supabase via `SupabaseService.client`**, never directly via `Supabase.instance.client`.
5. **Screens**: always `ConsumerStatefulWidget`. Always `Future.microtask(() => _loadData())` in `initState`.
6. **State classes**: always `@immutable` with `copyWith`.
7. **Logs**: `debugPrint` only, never `print`.
8. **Section comments** use `// ═══` divider blocks (see any existing file).
9. **Use `AppSizes.*`** constants for spacing — never hardcoded `SizedBox` values.

## Auth & route guard (critical)

The `_authGuard()` redirect in `app_router.dart` protects every non-public route:

- **Not authenticated + not on `/`, `/login`, `/register`** → redirect to `/login`
- **Authenticated + on `/login` or `/register`** → redirect to `/` (splash handles routing)
- **Role mismatch** (patient on `/psi/*`, psychologist on `/app/*`) → redirect to `/`

`_AuthChangeNotifier` listens to Supabase `onAuthStateChange` and is wired as `refreshListenable` — this makes the redirect reactive when the user signs in/out. Without this wire, the guard only fires once.

Role is checked via `session.user.userMetadata['role']` (set during sign-up), no DB query needed.

**When adding a NEW route:** add it to the appropriate prefix group (`/psi/...` or `/app/...`) so the guard covers it automatically. Routes outside those prefixes (like `/legal/*`, `/onboarding/*`) are gated only by auth, not role.

## Route table (abridged)

```
/                           → SplashScreen
/login                      → LoginScreen
/register                   → RegisterScreen
/onboarding/psychologist    → OnboardingPsiScreen
/onboarding/patient         → OnboardingPatientScreen

/psi                        → PsiHomeScreen
/psi/patient                → PatientDetailScreen (extra: Map)
/psi/alerts                 → AlertsScreen
/psi/settings               → SettingsScreen
/psi/create-task            → CreateTaskScreen (extra: Map)
/psi/task                   → PsiTaskDetailScreen (extra: TaskModel)
/psi/* (scale routes)       → SelectScale, ConfigureScale, EditScale, etc.

/app                        → PatientHomeScreen
/app/checkin                → CheckinScreen
/app/evolution              → EvolutionScreen
/app/tasks                  → TasksScreen
/app/task                   → TaskDetailScreen (extra: TaskModel)
/app/achievements           → AchievementsScreen
/app/* (scale routes)       → AnswerScaleScreen, ScaleCompletedScreen

/legal/consent              → ConsentScreen (extra: String redirectTo)
/legal/terms                → TermsScreen
/legal/privacy              → PrivacyPolicyScreen
/legal/export               → DataExportScreen
/legal/delete-account       → DeleteAccountScreen
```

Routes that carry data use `state.extra` (not path params). For full list, read `app_router.dart`.

## Database key relationships

```
patients.id          ← FK used in checkins, tasks, task_responses, achievements
patients.user_id     = auth.uid() (nullable — null until patient links account)
patients.psychologist_id = psychologists.id (= auth.uid() of the psychologist)
psychologists.id     = auth.uid() of the psychologist
profiles.id          = auth.uid()
```

RLS policies use JOINs through `patients` table — patient data is accessible to the patient's `auth.uid()` via `patients.user_id`, and to the psychologist via `patients.psychologist_id`.

`link_patient_to_user` is an RPC function (Supabase SQL) that bypasses RLS to set `patients.user_id`.

## Feature flags

Stored in `psychologists.features` (JSONB): `{"tasks": true, "chat": false}`. Managed via `featureProvider`.

## Deploy notes

- `vercel.json`: SPA rewrites send all paths to `/index.html` (required for client-side routing)
- `scripts/build.sh` is the Vercel CI build entry; clones Flutter SDK from GitHub
- Web renderer: default (auto) — the old `--web-renderer canvaskit` flag is no longer needed with Flutter 3.24+
