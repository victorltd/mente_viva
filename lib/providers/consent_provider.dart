// lib/providers/consent_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../config/constants/legal_constants.dart';
import '../models/consent_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class ConsentState {
  final bool isLoading;
  final bool hasValidConsent;
  final ConsentRecord? latestConsent;
  final DeletionRequest? pendingDeletion;
  final String? error;

  const ConsentState({
    this.isLoading = false,
    this.hasValidConsent = false,
    this.latestConsent,
    this.pendingDeletion,
    this.error,
  });

  ConsentState copyWith({
    bool? isLoading,
    bool? hasValidConsent,
    ConsentRecord? latestConsent,
    DeletionRequest? pendingDeletion,
    String? error,
    bool clearError = false,
    bool clearDeletion = false,
  }) {
    return ConsentState(
      isLoading: isLoading ?? this.isLoading,
      hasValidConsent: hasValidConsent ?? this.hasValidConsent,
      latestConsent: latestConsent ?? this.latestConsent,
      pendingDeletion: clearDeletion ? null : (pendingDeletion ?? this.pendingDeletion),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get needsReConsent {
    if (latestConsent == null) return true;
    return latestConsent!.termsVersion != LegalConstants.termsVersion ||
        latestConsent!.privacyVersion != LegalConstants.privacyVersion;
  }

  bool get hasPendingDeletion => 
      pendingDeletion != null && 
      pendingDeletion!.status == DeletionStatus.pending;
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class ConsentNotifier extends Notifier<ConsentState> {
  @override
  ConsentState build() {
    return const ConsentState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // VERIFICAR CONSENTIMENTO
  // ══════════════════════════════════════
  Future<void> checkConsent() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = state.copyWith(isLoading: false, hasValidConsent: false);
        return;
      }

      // Buscar último consentimento
      final consentResponse = await _client
          .from('consent_records')
          .select()
          .eq('user_id', userId)
          .order('accepted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      ConsentRecord? consent;
      if (consentResponse != null) {
        consent = ConsentRecord.fromJson(consentResponse);
      }

      // Verificar se precisa de re-consentimento
      final hasValid = consent != null &&
          consent.termsVersion == LegalConstants.termsVersion &&
          consent.privacyVersion == LegalConstants.privacyVersion;

      // Buscar solicitação de exclusão pendente
      final deletionResponse = await _client
          .from('deletion_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      DeletionRequest? deletion;
      if (deletionResponse != null) {
        deletion = DeletionRequest.fromJson(deletionResponse);
      }

      state = state.copyWith(
        isLoading: false,
        hasValidConsent: hasValid,
        latestConsent: consent,
        pendingDeletion: deletion,
      );

      debugPrint('=== CONSENTIMENTO: ${hasValid ? "VÁLIDO" : "NECESSÁRIO"} ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao verificar consentimento: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // REGISTRAR CONSENTIMENTO
  // ══════════════════════════════════════
  Future<bool> giveConsent({
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Inserir registro de consentimento
      final response = await _client
          .from('consent_records')
          .insert({
            'user_id': userId,
            'terms_version': LegalConstants.termsVersion,
            'privacy_version': LegalConstants.privacyVersion,
            'ip_address': ipAddress,
            'user_agent': userAgent,
          })
          .select()
          .single();

      final consent = ConsentRecord.fromJson(response);

      // Atualizar profile
      await _client.from('profiles').update({
        'consent_given_at': DateTime.now().toIso8601String(),
        'terms_version': LegalConstants.termsVersion,
        'privacy_version': LegalConstants.privacyVersion,
      }).eq('id', userId);

      state = state.copyWith(
        isLoading: false,
        hasValidConsent: true,
        latestConsent: consent,
      );

      debugPrint('=== CONSENTIMENTO REGISTRADO ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao registrar consentimento: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // SOLICITAR EXCLUSÃO DE CONTA
  // ══════════════════════════════════════
  Future<bool> requestDeletion({String? reason}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final response = await _client
          .from('deletion_requests')
          .insert({
            'user_id': userId,
            'reason': reason,
          })
          .select()
          .single();

      final deletion = DeletionRequest.fromJson(response);

      state = state.copyWith(
        isLoading: false,
        pendingDeletion: deletion,
      );

      debugPrint('=== EXCLUSÃO SOLICITADA ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao solicitar exclusão: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // CANCELAR EXCLUSÃO
  // ══════════════════════════════════════
  Future<bool> cancelDeletion() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final deletion = state.pendingDeletion;
      if (deletion == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      await _client
          .from('deletion_requests')
          .update({'status': 'cancelled'})
          .eq('id', deletion.id);

      state = state.copyWith(
        isLoading: false,
        clearDeletion: true,
      );

      debugPrint('=== EXCLUSÃO CANCELADA ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao cancelar exclusão: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // EXPORTAR DADOS
  // ══════════════════════════════════════
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      // Buscar profile
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Buscar patient data (se for paciente)
      final patient = await _client
          .from('patients')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Buscar check-ins
      List<dynamic> checkins = [];
      if (patient != null) {
        checkins = await _client
            .from('checkins')
            .select()
            .eq('patient_id', patient['id'])
            .order('created_at', ascending: false);
      }

      // Buscar task responses
      List<dynamic> taskResponses = [];
      if (patient != null) {
        taskResponses = await _client
            .from('task_responses')
            .select('*, tasks(*)')
            .eq('patient_id', patient['id'])
            .order('completed_at', ascending: false);
      }

      // Buscar conquistas
      List<dynamic> achievements = [];
      if (patient != null) {
        achievements = await _client
            .from('user_achievements')
            .select()
            .eq('patient_id', patient['id'])
            .order('unlocked_at', ascending: false);
      }

      // Buscar consentimentos
      final consents = await _client
          .from('consent_records')
          .select()
          .eq('user_id', userId)
          .order('accepted_at', ascending: false);

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile': profile,
        'patient_data': patient,
        'checkins': checkins,
        'task_responses': taskResponses,
        'achievements': achievements,
        'consent_records': consents,
      };

      state = state.copyWith(isLoading: false);

      debugPrint('=== DADOS EXPORTADOS ===');
      return exportData;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao exportar dados: $e',
      );
      return null;
    }
  }

  void clear() {
    state = const ConsentState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final consentProvider =
    NotifierProvider<ConsentNotifier, ConsentState>(ConsentNotifier.new);