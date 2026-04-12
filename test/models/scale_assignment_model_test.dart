// ═══════════════════════════════════════════════════════
// TESTES UNITÁRIOS — ScaleAssignmentModel
// ═══════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:menteviva/models/scale_assignment_model.dart';

void main() {
  // ══════════════════════════════════════
  // FIXTURES
  // ══════════════════════════════════════

  final _now = DateTime.now();
  final _yesterday = _now.subtract(const Duration(days: 1));
  final _tomorrow = _now.add(const Duration(days: 1));
  final _lastWeek = _now.subtract(const Duration(days: 7));

  ScaleAssignmentModel _createAssignment({
    String id = 'assign-1',
    String? scaleTemplateId = 'phq9',
    String? customScaleId,
    ScaleFrequency frequency = ScaleFrequency.once,
    AssignmentStatus status = AssignmentStatus.active,
    DateTime? nextDueDate,
    DateTime? lastCompletedAt,
  }) {
    return ScaleAssignmentModel(
      id: id,
      patientId: 'patient-1',
      psychologistId: 'psi-1',
      scaleTemplateId: scaleTemplateId,
      customScaleId: customScaleId,
      frequency: frequency,
      status: status,
      startDate: _lastWeek,
      nextDueDate: nextDueDate,
      lastCompletedAt: lastCompletedAt,
      createdAt: _lastWeek,
      updatedAt: _now,
    );
  }

  Map<String, dynamic> _assignmentJson() {
    return {
      'id': 'assign-1',
      'patient_id': 'patient-1',
      'psychologist_id': 'psi-1',
      'scale_template_id': 'phq9',
      'custom_scale_id': null,
      'frequency': 'weekly',
      'status': 'active',
      'start_date': '2025-01-01',
      'next_due_date': '2025-01-08',
      'last_completed_at': null,
      'notify_patient': true,
      'custom_instructions': null,
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
    };
  }

  // ══════════════════════════════════════
  // TESTES: FROM JSON
  // ══════════════════════════════════════

  group('ScaleAssignmentModel.fromJson', () {
    test('deve fazer parse correto de assignment com template', () {
      final json = _assignmentJson();
      final assignment = ScaleAssignmentModel.fromJson(json);

      expect(assignment.id, 'assign-1');
      expect(assignment.patientId, 'patient-1');
      expect(assignment.psychologistId, 'psi-1');
      expect(assignment.scaleTemplateId, 'phq9');
      expect(assignment.customScaleId, null);
      expect(assignment.frequency, ScaleFrequency.weekly);
      expect(assignment.status, AssignmentStatus.active);
      expect(assignment.notifyPatient, true);
    });

    test('deve fazer parse correto de assignment com escala customizada', () {
      final json = _assignmentJson();
      json['scale_template_id'] = null;
      json['custom_scale_id'] = 'custom-uuid-123';

      final assignment = ScaleAssignmentModel.fromJson(json);

      expect(assignment.scaleTemplateId, null);
      expect(assignment.customScaleId, 'custom-uuid-123');
      expect(assignment.isTemplate, false);
    });

    test('deve fazer parse de frequência mensal', () {
      final json = _assignmentJson();
      json['frequency'] = 'monthly';

      final assignment = ScaleAssignmentModel.fromJson(json);
      expect(assignment.frequency, ScaleFrequency.monthly);
    });

    test('deve fazer parse de next_due_date nulo', () {
      final json = _assignmentJson();
      json['next_due_date'] = null;

      final assignment = ScaleAssignmentModel.fromJson(json);
      expect(assignment.nextDueDate, null);
    });

    test('deve fazer parse de last_completed_at quando existe', () {
      final json = _assignmentJson();
      json['last_completed_at'] = '2025-01-07T14:30:00Z';

      final assignment = ScaleAssignmentModel.fromJson(json);
      expect(assignment.lastCompletedAt, isNotNull);
      expect(assignment.lastCompletedAt!.year, 2025);
    });
  });

  // ══════════════════════════════════════
  // TESTES: TO JSON
  // ══════════════════════════════════════

  group('ScaleAssignmentModel.toJson', () {
    test('deve serializar corretamente para JSON', () {
      final assignment = _createAssignment();
      final json = assignment.toJson();

      expect(json['patient_id'], 'patient-1');
      expect(json['scale_template_id'], 'phq9');
      expect(json['custom_scale_id'], null);
      expect(json['frequency'], 'once');
      expect(json['status'], 'active');
      expect(json['notify_patient'], true);
    });
  });

  // ══════════════════════════════════════
  // TESTES: HELPERS — IS PENDING / OVERDUE
  // ══════════════════════════════════════

  group('isPending', () {
    test('deve retornar true se status active e sem nextDueDate (nunca respondida)', () {
      // Escala única nunca respondida: pendente
      final assignment = _createAssignment(nextDueDate: null);
      expect(assignment.isPending, true);
    });

    test('deve retornar false se status active, sem nextDueDate, mas já respondida', () {
      // Escala única já completada: NÃO pendente
      final assignment = _createAssignment(
        nextDueDate: null,
        lastCompletedAt: _yesterday,
        frequency: ScaleFrequency.once,
      );
      expect(assignment.isPending, false);
    });

    test('deve retornar true se nextDueDate é ontem (atrasada)', () {
      final assignment = _createAssignment(nextDueDate: _yesterday);
      expect(assignment.isPending, true);
    });

    test('deve retornar true se nextDueDate é agora', () {
      final assignment = _createAssignment(nextDueDate: _now);
      expect(assignment.isPending, true);
    });

    test('deve retornar true se nextDueDate é amanhã mas nunca foi respondida', () {
      // Escala nunca respondida: SEMPRE pendente, independente do nextDueDate
      final assignment = _createAssignment(nextDueDate: _tomorrow);
      expect(assignment.isPending, true);
    });

    test('deve retornar false se nextDueDate é amanhã e já foi respondida', () {
      // Escala já respondida com próxima data no futuro: NÃO pendente
      final assignment = _createAssignment(
        nextDueDate: _tomorrow,
        lastCompletedAt: _yesterday,
      );
      expect(assignment.isPending, false);
    });

    test('deve retornar false se status é paused', () {
      final assignment = _createAssignment(
        status: AssignmentStatus.paused,
        nextDueDate: _yesterday,
      );
      expect(assignment.isPending, false);
    });

    test('deve retornar false se status é completed', () {
      final assignment = _createAssignment(
        status: AssignmentStatus.completed,
        nextDueDate: _yesterday,
      );
      expect(assignment.isPending, false);
    });
  });

  group('isOverdue', () {
    test('deve retornar true se nextDueDate é ontem e active', () {
      final assignment = _createAssignment(nextDueDate: _yesterday);
      expect(assignment.isOverdue, true);
    });

    test('deve retornar false se nextDueDate é amanhã', () {
      final assignment = _createAssignment(nextDueDate: _tomorrow);
      expect(assignment.isOverdue, false);
    });

    test('deve retornar false se nextDueDate é null', () {
      final assignment = _createAssignment(nextDueDate: null);
      expect(assignment.isOverdue, false);
    });

    test('deve retornar false se status é paused', () {
      final assignment = _createAssignment(
        status: AssignmentStatus.paused,
        nextDueDate: _yesterday,
      );
      expect(assignment.isOverdue, false);
    });
  });

  // ══════════════════════════════════════
  // TESTES: HELPERS — IS TEMPLATE / SCALE ID
  // ══════════════════════════════════════

  group('isTemplate / scaleId', () {
    test('isTemplate deve retornar true se scaleTemplateId existe', () {
      final assignment = _createAssignment(scaleTemplateId: 'phq9');
      expect(assignment.isTemplate, true);
    });

    test('isTemplate deve retornar false se customScaleId existe', () {
      final assignment = _createAssignment(
        scaleTemplateId: null,
        customScaleId: 'custom-123',
      );
      expect(assignment.isTemplate, false);
    });

    test('scaleId deve retornar template id quando é template', () {
      final assignment = _createAssignment(scaleTemplateId: 'gad7');
      expect(assignment.scaleId, 'gad7');
    });

    test('scaleId deve retornar custom id quando é custom', () {
      final assignment = _createAssignment(
        scaleTemplateId: null,
        customScaleId: 'custom-uuid',
      );
      expect(assignment.scaleId, 'custom-uuid');
    });
  });

  group('scaleLabel', () {
    test('deve retornar nome do template', () {
      final assignment = _createAssignment(scaleTemplateId: 'phq9');
      expect(assignment.scaleLabel, 'phq9');
    });

    test('deve retornar "Escala personalizada" se custom', () {
      final assignment = _createAssignment(
        scaleTemplateId: null,
        customScaleId: 'custom-123',
      );
      expect(assignment.scaleLabel, 'Escala personalizada');
    });
  });

  // ══════════════════════════════════════
  // TESTES: ENUMS — FREQUENCY
  // ══════════════════════════════════════

  group('ScaleFrequency enum', () {
    test('deve retornar labels corretos', () {
      expect(ScaleFrequency.once.label, 'Única vez');
      expect(ScaleFrequency.weekly.label, 'Semanal');
      expect(ScaleFrequency.biweekly.label, 'Quinzenal');
      expect(ScaleFrequency.monthly.label, 'Mensal');
      expect(ScaleFrequency.custom.label, 'Personalizada');
    });

    test('deve retornar descriptions corretas', () {
      expect(
        ScaleFrequency.weekly.description,
        'Repete toda semana',
      );
      expect(
        ScaleFrequency.biweekly.description,
        'Repete a cada 2 semanas',
      );
    });
  });

  // ══════════════════════════════════════
  // TESTES: ENUMS — STATUS
  // ══════════════════════════════════════

  group('AssignmentStatus enum', () {
    test('deve retornar labels corretos', () {
      expect(AssignmentStatus.active.label, 'Ativa');
      expect(AssignmentStatus.paused.label, 'Pausada');
      expect(AssignmentStatus.completed.label, 'Concluída');
    });
  });

  // ══════════════════════════════════════
  // TESTES: COPYWITH
  // ══════════════════════════════════════

  group('copyWith', () {
    test('deve criar cópia com status alterado', () {
      final assignment = _createAssignment();
      final modified = assignment.copyWith(
        status: AssignmentStatus.paused,
      );

      expect(modified.status, AssignmentStatus.paused);
      expect(modified.id, 'assign-1'); // resto igual
    });

    test('deve criar cópia com frequência alterada', () {
      final assignment = _createAssignment();
      final modified = assignment.copyWith(
        frequency: ScaleFrequency.monthly,
      );

      expect(modified.frequency, ScaleFrequency.monthly);
      expect(assignment.frequency, ScaleFrequency.once); // original intacto
    });

    test('deve manter tudo se nenhum campo alterado', () {
      final assignment = _createAssignment();
      final copy = assignment.copyWith();

      expect(copy.id, assignment.id);
      expect(copy.frequency, assignment.frequency);
      expect(copy.status, assignment.status);
    });
  });
}
