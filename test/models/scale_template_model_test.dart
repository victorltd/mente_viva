// ═══════════════════════════════════════════════════════
// TESTES UNITÁRIOS — ScaleTemplateModel
// ═══════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:menteviva/models/scale_template_model.dart';

void main() {
  // ══════════════════════════════════════
  // FIXTURES — JSON de exemplo (PHQ-9 simplificado)
  // ══════════════════════════════════════

  Map<String, dynamic> _phq9Json() {
    return {
      'id': 'phq9',
      'name': 'PHQ-9',
      'full_name': 'Patient Health Questionnaire-9',
      'description': 'Rastreio de depressão',
      'category': 'depression',
      'is_validated': true,
      'reference': 'Kroenke et al., 2001',
      'estimated_time_minutes': 3,
      'instructions':
          'Nas últimas 2 semanas, com que frequência você foi incomodado(a)?',
      'response_options': [
        {'value': 0, 'label': 'Nenhuma vez'},
        {'value': 1, 'label': 'Vários dias'},
        {'value': 2, 'label': 'Mais da metade dos dias'},
        {'value': 3, 'label': 'Quase todos os dias'},
      ],
      'questions': [
        {
          'id': 'q1',
          'order': 1,
          'text': 'Pouco interesse ou prazer em fazer as coisas',
          'required': true,
          'subscale': 'anhedonia',
          'is_critical': false,
          'alert_threshold': null,
        },
        {
          'id': 'q2',
          'order': 2,
          'text': 'Sentir-se triste, para baixo(a)',
          'required': true,
          'subscale': 'mood',
          'is_critical': false,
          'alert_threshold': null,
        },
        {
          'id': 'q9',
          'order': 9,
          'text': 'Pensamentos de se machucar',
          'required': true,
          'subscale': 'mood',
          'is_critical': true,
          'alert_threshold': 1,
        },
      ],
      'scoring': {
        'method': 'sum',
        'min_score': 0,
        'max_score': 27,
        'reverse_items': [],
        'severity_ranges': [
          {
            'min': 0,
            'max': 4,
            'level': 'minimal',
            'label': 'Mínimo',
            'color': '#10B981',
          },
          {
            'min': 5,
            'max': 9,
            'level': 'mild',
            'label': 'Leve',
            'color': '#F59E0B',
          },
          {
            'min': 10,
            'max': 14,
            'level': 'moderate',
            'label': 'Moderado',
            'color': '#F97316',
          },
          {
            'min': 15,
            'max': 19,
            'level': 'moderately_severe',
            'label': 'Moderadamente Grave',
            'color': '#EF4444',
          },
          {
            'min': 20,
            'max': 27,
            'level': 'severe',
            'label': 'Grave',
            'color': '#DC2626',
          },
        ],
        'clinical_cutoff': 10,
        'clinical_cutoff_description': 'Score ≥ 10 sugere depressão clínica.',
      },
      'subscales': [
        {'id': 'anhedonia', 'name': 'Anedonia', 'items': ['q1']},
        {'id': 'mood', 'name': 'Humor', 'items': ['q2', 'q9']},
      ],
      'alerts': [
        {
          'condition': 'q9 >= 1',
          'severity': 'critical',
          'message': 'Paciente relatou pensamentos de autoagressão',
          'action': 'Avaliar risco de suicídio imediatamente.',
        },
      ],
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
    };
  }

  // ══════════════════════════════════════
  // TESTES: FROM JSON
  // ══════════════════════════════════════

  group('ScaleTemplateModel.fromJson', () {
    test('deve fazer parse correto de um JSON válido (PHQ-9)', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      expect(template.id, 'phq9');
      expect(template.name, 'PHQ-9');
      expect(template.fullName, 'Patient Health Questionnaire-9');
      expect(template.category, ScaleCategory.depression);
      expect(template.isValidated, true);
      expect(template.estimatedTimeMinutes, 3);
      expect(template.questions.length, 3);
      expect(template.responseOptions.length, 4);
      expect(template.scoring.maxScore, 27);
      expect(template.scoring.severityRanges.length, 5);
      expect(template.subscales.length, 2);
      expect(template.alerts.length, 1);
    });

    test('deve identificar pergunta crítica', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final criticalQuestion = template.questions[2]; // q9
      expect(criticalQuestion.isCritical, true);
      expect(criticalQuestion.alertThreshold, 1);
    });

    test('deve identificar pergunta não crítica', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final normalQuestion = template.questions[0]; // q1
      expect(normalQuestion.isCritical, false);
      expect(normalQuestion.alertThreshold, null);
    });
  });

  // ══════════════════════════════════════
  // TESTES: TO JSON
  // ══════════════════════════════════════

  group('ScaleTemplateModel.toJson', () {
    test('deve serializar corretamente para JSON', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);
      final output = template.toJson();

      expect(output['id'], 'phq9');
      expect(output['name'], 'PHQ-9');
      expect(output['category'], 'depression');
      expect(output['questions'], isA<List>());
      expect(output['scoring'], isA<Map>());
    });
  });

  // ══════════════════════════════════════
  // TESTES: CALCULAR SCORE
  // ══════════════════════════════════════

  group('calculateTotalScore', () {
    test('deve somar corretamente as respostas', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {
        'q1': 2, // Mais da metade dos dias
        'q2': 1, // Vários dias
        'q9': 0, // Nenhuma vez
      };

      final score = template.calculateTotalScore(answers);
      expect(score, 3); // 2 + 1 + 0
    });

    test('deve retornar 0 para todas respostas zeradas', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {'q1': 0, 'q2': 0, 'q9': 0};
      final score = template.calculateTotalScore(answers);
      expect(score, 0);
    });

    test('deve retornar score máximo', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {'q1': 3, 'q2': 3, 'q9': 3};
      final score = template.calculateTotalScore(answers);
      expect(score, 9); // 3 + 3 + 3
    });
  });

  // ══════════════════════════════════════
  // TESTES: SEVERIDADE
  // ══════════════════════════════════════

  group('getSeverityLevel', () {
    test('deve retornar "mínimo" para score 0', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final severity = template.getSeverityLevel(0);
      expect(severity.level, 'minimal');
      expect(severity.label, 'Mínimo');
    });

    test('deve retornar "leve" para score 7', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final severity = template.getSeverityLevel(7);
      expect(severity.level, 'mild');
      expect(severity.label, 'Leve');
    });

    test('deve retornar "moderado" para score 12', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final severity = template.getSeverityLevel(12);
      expect(severity.level, 'moderate');
      expect(severity.label, 'Moderado');
    });

    test('deve retornar "moderadamente grave" para score 17', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final severity = template.getSeverityLevel(17);
      expect(severity.level, 'moderately_severe');
      expect(severity.label, 'Moderadamente Grave');
    });

    test('deve retornar "grave" para score 25', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final severity = template.getSeverityLevel(25);
      expect(severity.level, 'severe');
      expect(severity.label, 'Grave');
    });

    test('deve usar primeiro range se score fora do intervalo', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      // Score negativo (não deveria acontecer, mas o código deve lidar)
      final severity = template.getSeverityLevel(-1);
      expect(severity.level, 'minimal');
    });
  });

  // ══════════════════════════════════════
  // TESTES: ITENS CRÍTICOS
  // ══════════════════════════════════════

  group('checkCriticalItems', () {
    test('deve detectar item crítico quando resposta >= threshold', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {
        'q1': 1,
        'q2': 2,
        'q9': 2, // threshold = 1, resposta = 2 → CRÍTICO
      };

      final flags = template.checkCriticalItems(answers);
      expect(flags.length, 1);
      expect(flags[0].questionId, 'q9');
      expect(flags[0].value, 2);
      expect(flags[0].threshold, 1);
    });

    test('deve detectar item crítico quando resposta == threshold', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {
        'q1': 0,
        'q2': 0,
        'q9': 1, // threshold = 1, resposta = 1 → CRÍTICO (igual)
      };

      final flags = template.checkCriticalItems(answers);
      expect(flags.length, 1);
    });

    test('NÃO deve detectar item crítico quando resposta < threshold', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {
        'q1': 0,
        'q2': 0,
        'q9': 0, // threshold = 1, resposta = 0 → NÃO CRÍTICO
      };

      final flags = template.checkCriticalItems(answers);
      expect(flags.length, 0);
    });

    test('deve ignorar perguntas não críticas mesmo com score alto', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final answers = {
        'q1': 3, // Score máximo, mas NÃO é crítica
        'q2': 3, // Score máximo, mas NÃO é crítica
        'q9': 0, // threshold = 1, resposta = 0 → NÃO CRÍTICO
      };

      final flags = template.checkCriticalItems(answers);
      expect(flags.length, 0);
    });
  });

  // ══════════════════════════════════════
  // TESTES: ENUMS
  // ══════════════════════════════════════

  group('ScaleCategory enum', () {
    test('deve retornar label correto para cada categoria', () {
      expect(ScaleCategory.depression.label, 'Depressão');
      expect(ScaleCategory.anxiety.label, 'Ansiedade');
      expect(ScaleCategory.progress.label, 'Progresso');
      expect(ScaleCategory.general.label, 'Geral');
    });

    test('deve retornar emoji correto para cada categoria', () {
      expect(ScaleCategory.depression.emoji, '🌧️');
      expect(ScaleCategory.anxiety.emoji, '⚡');
      expect(ScaleCategory.progress.emoji, '📈');
      expect(ScaleCategory.general.emoji, '📋');
    });
  });

  group('SeverityLevel enum', () {
    test('deve retornar label correto', () {
      expect(SeverityLevel.minimal.label, 'Mínimo');
      expect(SeverityLevel.mild.label, 'Leve');
      expect(SeverityLevel.moderate.label, 'Moderado');
      expect(SeverityLevel.moderately_severe.label, 'Moderadamente Grave');
      expect(SeverityLevel.severe.label, 'Grave');
    });

    test('deve fazer parse de string corretamente', () {
      expect(
        SeverityLevel.fromString('minimal'),
        SeverityLevel.minimal,
      );
      expect(
        SeverityLevel.fromString('severe'),
        SeverityLevel.severe,
      );
      expect(
        SeverityLevel.fromString('invalido'),
        SeverityLevel.minimal, // fallback
      );
    });
  });

  // ══════════════════════════════════════
  // TESTES: HELPERS
  // ══════════════════════════════════════

  group('estimatedTime', () {
    test('deve formatar tempo em minutos', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);
      expect(template.estimatedTime, '~3 min');
    });

    test('deve formatar tempo em horas', () {
      final json = _phq9Json();
      json['estimated_time_minutes'] = 75;
      final template = ScaleTemplateModel.fromJson(json);
      expect(template.estimatedTime, '~1h 15min');
    });
  });

  // ══════════════════════════════════════
  // TESTES: COPYWITH
  // ══════════════════════════════════════

  group('copyWith', () {
    test('deve criar cópia com campo alterado', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final modified = template.copyWith(name: 'PHQ-9 Modificado');
      expect(modified.name, 'PHQ-9 Modificado');
      expect(modified.id, 'phq9'); // resto igual
    });

    test('deve retornar mesmo objeto se nenhum campo alterado', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final copy = template.copyWith();
      expect(copy.id, template.id);
      expect(copy.name, template.name);
      expect(copy.questions.length, template.questions.length);
    });
  });

  // ══════════════════════════════════════
  // TESTES: ALERT RULE
  // ══════════════════════════════════════

  group('AlertRule', () {
    test('deve identificar regra crítico', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final alert = template.alerts.first;
      expect(alert.isCritical, true);
      expect(alert.severity, 'critical');
    });
  });

  // ══════════════════════════════════════
  // TESTES: RESPONSE OPTION
  // ══════════════════════════════════════

  group('ResponseOption', () {
    test('deve fazer parse e serializar corretamente', () {
      final jsonMap = {'value': 2, 'label': 'Mais da metade dos dias'};
      final option = ResponseOption.fromJson(jsonMap);

      expect(option.value, 2);
      expect(option.label, 'Mais da metade dos dias');

      final output = option.toJson();
      expect(output['value'], 2);
      expect(output['label'], 'Mais da metade dos dias');
    });
  });

  // ══════════════════════════════════════
  // TESTES: SUBSCALE
  // ══════════════════════════════════════

  group('Subscale', () {
    test('deve fazer parse corretamente', () {
      final json = _phq9Json();
      final template = ScaleTemplateModel.fromJson(json);

      final anhedonia = template.subscales[0];
      expect(anhedonia.id, 'anhedonia');
      expect(anhedonia.name, 'Anedonia');
      expect(anhedonia.items, ['q1']);

      final mood = template.subscales[1];
      expect(mood.id, 'mood');
      expect(mood.name, 'Humor');
      expect(mood.items, ['q2', 'q9']);
    });
  });
}
