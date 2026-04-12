// ═══════════════════════════════════════════════════════
// TESTES UNITÁRIOS — ScaleResponseModel
// ═══════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:menteviva/models/scale_template_model.dart';
import 'package:menteviva/models/scale_response_model.dart';

void main() {
  // ══════════════════════════════════════
  // FIXTURES
  // ══════════════════════════════════════

  final _now = DateTime.now();
  final _criticalFlag = CriticalFlag(
    questionId: 'q9',
    questionText: 'Pensamentos de se machucar',
    value: 2,
    threshold: 1,
  );

  ScaleResponseModel _createResponse({
    String id = 'resp-1',
    Map<String, int> answers = const {'q1': 2, 'q2': 1},
    int totalScore = 3,
    String? severityLevel = 'mild',
    List<CriticalFlag> criticalFlags = const [],
    int? durationSeconds = 120,
    DateTime? completedAt,
  }) {
    final doneAt = completedAt ?? _now;
    return ScaleResponseModel(
      id: id,
      assignmentId: 'assign-1',
      patientId: 'patient-1',
      answers: answers,
      totalScore: totalScore,
      severityLevel: severityLevel,
      subscaleScores: {'mood': 1.5},
      criticalFlags: criticalFlags,
      hasCriticalItem: criticalFlags.isNotEmpty,
      completedAt: doneAt,
      durationSeconds: durationSeconds,
      createdAt: doneAt,
    );
  }

  Map<String, dynamic> _responseJson() {
    return {
      'id': 'resp-1',
      'assignment_id': 'assign-1',
      'patient_id': 'patient-1',
      'answers': {'q1': 2, 'q2': 1, 'q9': 0},
      'total_score': 3,
      'severity_level': 'mild',
      'subscale_scores': {'mood': 1.5, 'anhedonia': 2.0},
      'critical_flags': [],
      'has_critical_item': false,
      'completed_at': '2025-01-15T10:30:00Z',
      'duration_seconds': 180,
      'created_at': '2025-01-15T10:30:00Z',
    };
  }

  // ══════════════════════════════════════
  // TESTES: FACTORY CALCULATE
  // ══════════════════════════════════════

  group('ScaleResponseModel.calculate', () {
    test('deve criar resposta com score calculado', () {
      final response = ScaleResponseModel.calculate(
        assignmentId: 'assign-1',
        patientId: 'patient-1',
        answers: {'q1': 2, 'q2': 3, 'q9': 1},
        totalScore: 6,
        severityLevel: 'mild',
        subscaleScores: {'mood': 2.0},
        criticalFlags: [],
        durationSeconds: 150,
      );

      expect(response.assignmentId, 'assign-1');
      expect(response.patientId, 'patient-1');
      expect(response.answers['q1'], 2);
      expect(response.answers['q2'], 3);
      expect(response.totalScore, 6);
      expect(response.severityLevel, 'mild');
      expect(response.durationSeconds, 150);
    });

    test('deve marcar hasCriticalItem quando há flags', () {
      final response = ScaleResponseModel.calculate(
        assignmentId: 'assign-1',
        patientId: 'patient-1',
        answers: {'q9': 2},
        totalScore: 2,
        severityLevel: 'minimal',
        criticalFlags: [_criticalFlag],
      );

      expect(response.hasCriticalItem, true);
      expect(response.criticalFlags.length, 1);
      expect(response.isCritical, true);
    });

    test('deve NÃO marcar hasCriticalItem quando sem flags', () {
      final response = ScaleResponseModel.calculate(
        assignmentId: 'assign-1',
        patientId: 'patient-1',
        answers: {'q1': 0, 'q2': 0},
        totalScore: 0,
        severityLevel: 'minimal',
        criticalFlags: [],
      );

      expect(response.hasCriticalItem, false);
      expect(response.isCritical, false);
    });
  });

  // ══════════════════════════════════════
  // TESTES: FROM JSON
  // ══════════════════════════════════════

  group('ScaleResponseModel.fromJson', () {
    test('deve fazer parse correto do JSON', () {
      final json = _responseJson();
      final response = ScaleResponseModel.fromJson(json);

      expect(response.id, 'resp-1');
      expect(response.assignmentId, 'assign-1');
      expect(response.patientId, 'patient-1');
      expect(response.answers['q1'], 2);
      expect(response.answers['q2'], 1);
      expect(response.answers['q9'], 0);
      expect(response.totalScore, 3);
      expect(response.severityLevel, 'mild');
      expect(response.subscaleScores['mood'], 1.5);
      expect(response.subscaleScores['anhedonia'], 2.0);
      expect(response.hasCriticalItem, false);
      expect(response.durationSeconds, 180);
    });

    test('deve parsear critical flags do JSON', () {
      final json = _responseJson();
      json['critical_flags'] = [
        {
          'question_id': 'q9',
          'question_text': 'Pensamentos de se machucar',
          'value': 2,
          'threshold': 1,
        },
      ];
      json['has_critical_item'] = true;

      final response = ScaleResponseModel.fromJson(json);

      expect(response.criticalFlags.length, 1);
      expect(response.criticalFlags[0].questionId, 'q9');
      expect(response.criticalFlags[0].value, 2);
      expect(response.hasCriticalItem, true);
    });

    test('deve lidar com campos nulos/ausentes', () {
      final json = {
        'assignment_id': 'assign-1',
        'patient_id': 'patient-1',
        'answers': {'q1': 1},
        'total_score': 1,
        'severity_level': null,
        'subscale_scores': null,
        'critical_flags': null,
        'has_critical_item': false,
        'completed_at': '2025-01-15T10:30:00Z',
        'duration_seconds': null,
        'created_at': '2025-01-15T10:30:00Z',
      };

      final response = ScaleResponseModel.fromJson(json);

      expect(response.severityLevel, null);
      expect(response.subscaleScores, isEmpty);
      expect(response.criticalFlags, isEmpty);
      expect(response.durationSeconds, null);
    });
  });

  // ══════════════════════════════════════
  // TESTES: TO JSON
  // ══════════════════════════════════════

  group('ScaleResponseModel.toJson', () {
    test('deve serializar corretamente para JSON', () {
      final response = _createResponse();
      final json = response.toJson();

      expect(json['assignment_id'], 'assign-1');
      expect(json['patient_id'], 'patient-1');
      expect(json['total_score'], 3);
      expect(json['severity_level'], 'mild');
      expect(json['answers']['q1'], 2);
      expect(json['answers']['q2'], 1);
      expect(json['subscale_scores']['mood'], 1.5);
      expect(json['has_critical_item'], false);
    });

    test('deve serializar critical flags', () {
      final response = _createResponse(
        criticalFlags: [_criticalFlag],
      );
      final json = response.toJson();

      expect(json['has_critical_item'], true);
      expect(json['critical_flags'], isA<List>());
      expect(json['critical_flags'].length, 1);
      expect(json['critical_flags'][0]['question_id'], 'q9');
    });
  });

  // ══════════════════════════════════════
  // TESTES: HELPERS
  // ══════════════════════════════════════

  group('Helpers', () {
    test('isCritical deve retornar true quando há flags', () {
      final response = _createResponse(
        criticalFlags: [_criticalFlag],
      );
      expect(response.isCritical, true);
    });

    test('isCritical deve retornar false quando sem flags', () {
      final response = _createResponse();
      expect(response.isCritical, false);
    });

    test('severityLabel deve retornar label correto', () {
      final response = _createResponse(severityLevel: 'moderate');
      expect(response.severityLabel, 'Moderado');
    });

    test('severityLabel deve retornar N/A se null', () {
      final response = _createResponse(severityLevel: null);
      expect(response.severityLabel, 'N/A');
    });

    test('durationFormatted deve formatar minutos e segundos', () {
      final response = _createResponse(durationSeconds: 185);
      expect(response.durationFormatted, '3min 5s');
    });

    test('durationFormatted deve formatar só segundos (< 1 min)', () {
      final response = _createResponse(durationSeconds: 45);
      expect(response.durationFormatted, '45s');
    });

    test('durationFormatted deve retornar N/A se null', () {
      final response = _createResponse(durationSeconds: null);
      expect(response.durationFormatted, 'N/A');
    });

    test('answeredCount deve retornar nº de respostas', () {
      final response = _createResponse(
        answers: {'q1': 1, 'q2': 2, 'q3': 3},
      );
      expect(response.answeredCount, 3);
    });

    test('isToday deve retornar true se resposta é de hoje', () {
      final response = _createResponse(completedAt: DateTime.now());
      expect(response.isToday, true);
    });

    test('isToday deve retornar false se resposta é de outro dia', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final response = _createResponse(completedAt: yesterday);
      expect(response.isToday, false);
    });
  });

  // ══════════════════════════════════════
  // TESTES: COPYWITH
  // ══════════════════════════════════════

  group('copyWith', () {
    test('deve criar cópia com campo alterado', () {
      final response = _createResponse();
      final modified = response.copyWith(totalScore: 10);

      expect(modified.totalScore, 10);
      expect(modified.assignmentId, 'assign-1'); // resto igual
    });

    test('deve manter todos os campos se nada alterado', () {
      final response = _createResponse();
      final copy = response.copyWith();

      expect(copy.id, response.id);
      expect(copy.totalScore, response.totalScore);
      expect(copy.answers, response.answers);
      expect(copy.criticalFlags, response.criticalFlags);
    });
  });

  // ══════════════════════════════════════
  // TESTES: SCALE EVOLUTION POINT
  // ══════════════════════════════════════

  group('ScaleEvolutionPoint', () {
    test('deve criar a partir de ScaleResponseModel', () {
      final response = _createResponse(
        totalScore: 5,
        severityLevel: 'mild',
        id: 'resp-evolution',
      );

      final point = ScaleEvolutionPoint.fromResponse(response);

      expect(point.date, response.completedAt);
      expect(point.score, 5);
      expect(point.severityLevel, 'mild');
      expect(point.responseId, 'resp-evolution');
    });
  });

  // ══════════════════════════════════════
  // TESTES: SUBSCALE EVOLUTION
  // ══════════════════════════════════════

  group('SubscaleEvolution', () {
    test('deve calcular tendência negativa (melhorando)', () {
      final points = [
        ScaleEvolutionPoint(
          date: DateTime(2025, 1, 1),
          score: 10,
          severityLevel: 'moderate',
          severityLabel: 'Moderado',
          responseId: 'r1',
        ),
        ScaleEvolutionPoint(
          date: DateTime(2025, 1, 8),
          score: 5,
          severityLevel: 'mild',
          severityLabel: 'Leve',
          responseId: 'r2',
        ),
      ];

      final evolution = SubscaleEvolution(
        subscaleId: 'mood',
        subscaleName: 'Humor',
        points: points,
      );

      expect(evolution.trend, -5.0); // 5 - 10 = -5 (melhorando)
    });

    test('deve calcular tendência positiva (piorando)', () {
      final points = [
        ScaleEvolutionPoint(
          date: DateTime(2025, 1, 1),
          score: 3,
          severityLevel: 'minimal',
          severityLabel: 'Mínimo',
          responseId: 'r1',
        ),
        ScaleEvolutionPoint(
          date: DateTime(2025, 1, 8),
          score: 8,
          severityLevel: 'mild',
          severityLabel: 'Leve',
          responseId: 'r2',
        ),
      ];

      final evolution = SubscaleEvolution(
        subscaleId: 'mood',
        subscaleName: 'Humor',
        points: points,
      );

      expect(evolution.trend, 5.0); // 8 - 3 = +5 (piorando)
    });

    test('deve retornar 0 se menos de 2 pontos', () {
      final evolution = SubscaleEvolution(
        subscaleId: 'mood',
        subscaleName: 'Humor',
        points: [
          ScaleEvolutionPoint(
            date: DateTime(2025, 1, 1),
            score: 5,
            severityLevel: 'mild',
            severityLabel: 'Leve',
            responseId: 'r1',
          ),
        ],
      );

      expect(evolution.trend, 0);
    });
  });

  // ══════════════════════════════════════
  // TESTES: CRITICAL FLAG
  // ══════════════════════════════════════

  group('CriticalFlag', () {
    test('deve fazer parse e serializar corretamente', () {
      final flag = CriticalFlag(
        questionId: 'q9',
        questionText: 'Pensamentos de se machucar',
        value: 3,
        threshold: 1,
      );

      expect(flag.questionId, 'q9');
      expect(flag.value, 3);
      expect(flag.threshold, 1);

      final json = flag.toJson();
      expect(json['question_id'], 'q9');
      expect(json['value'], 3);
      expect(json['threshold'], 1);
      expect(json['message'], contains('Item crítico'));
    });

    test('deve fazer parse do JSON', () {
      final json = {
        'question_id': 'q9',
        'question_text': 'Pensamentos de se machucar',
        'value': 2,
        'threshold': 1,
      };

      final flag = CriticalFlag.fromJson(json);

      expect(flag.questionId, 'q9');
      expect(flag.value, 2);
      expect(flag.threshold, 1);
    });
  });
}
