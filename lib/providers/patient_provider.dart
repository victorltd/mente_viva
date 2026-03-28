// lib/providers/patient_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/patient_model.dart';

@immutable
class PatientState {
  final bool isLoading;
  final PatientModel? patient;
  final String? error;

  const PatientState({
    this.isLoading = false,
    this.patient,
    this.error,
  });

  PatientState copyWith({
    bool? isLoading,
    PatientModel? patient,
    String? error,
  }) {
    return PatientState(
      isLoading: isLoading ?? this.isLoading,
      patient: patient ?? this.patient,
      error: error ?? this.error,
    );
  }
}

class PatientNotifier extends Notifier<PatientState> {
  @override
  PatientState build() {
    return const PatientState();
  }

  final _client = SupabaseService.client;

  Future<void> loadMyPatientData() async {
    try {
      state = state.copyWith(isLoading: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final response = await _client
          .from('patients')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          patient: PatientModel.fromJson(response),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro: $e',
      );
    }
  }
}

final patientProvider =
    NotifierProvider<PatientNotifier, PatientState>(PatientNotifier.new);