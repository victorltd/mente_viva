// lib/models/consent_model.dart

import 'package:flutter/material.dart';

// ══════════════════════════════════════
// CONSENT RECORD MODEL
// ══════════════════════════════════════
@immutable
class ConsentRecord {
  final String id;
  final String userId;
  final String termsVersion;
  final String privacyVersion;
  final DateTime acceptedAt;
  final String? ipAddress;
  final String? userAgent;

  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.termsVersion,
    required this.privacyVersion,
    required this.acceptedAt,
    this.ipAddress,
    this.userAgent,
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      termsVersion: json['terms_version'] as String,
      privacyVersion: json['privacy_version'] as String,
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'terms_version': termsVersion,
      'privacy_version': privacyVersion,
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }
}

// ══════════════════════════════════════
// DELETION REQUEST MODEL
// ══════════════════════════════════════
enum DeletionStatus {
  pending,
  cancelled,
  processing,
  completed;

  String get label {
    switch (this) {
      case DeletionStatus.pending:
        return 'Pendente';
      case DeletionStatus.cancelled:
        return 'Cancelada';
      case DeletionStatus.processing:
        return 'Em processamento';
      case DeletionStatus.completed:
        return 'Concluída';
    }
  }

  static DeletionStatus fromString(String value) {
    switch (value) {
      case 'cancelled':
        return DeletionStatus.cancelled;
      case 'processing':
        return DeletionStatus.processing;
      case 'completed':
        return DeletionStatus.completed;
      default:
        return DeletionStatus.pending;
    }
  }
}

@immutable
class DeletionRequest {
  final String id;
  final String userId;
  final String? reason;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final DateTime? processedAt;
  final DeletionStatus status;

  const DeletionRequest({
    required this.id,
    required this.userId,
    this.reason,
    required this.requestedAt,
    required this.scheduledFor,
    this.processedAt,
    required this.status,
  });

  int get daysUntilDeletion {
    if (status != DeletionStatus.pending) return 0;
    return scheduledFor.difference(DateTime.now()).inDays;
  }

  bool get canCancel => status == DeletionStatus.pending;

  factory DeletionRequest.fromJson(Map<String, dynamic> json) {
    return DeletionRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reason: json['reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      status: DeletionStatus.fromString(json['status'] as String? ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'reason': reason,
    };
  }
}