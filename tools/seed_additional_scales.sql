-- ═══════════════════════════════════════════════════════
-- SEED: Escalas padrão adicionais (BDI-II, BAI, OQ-45)
-- ═══════════════════════════════════════════════════════
-- Execute este script após o schema_scales.sql
-- ═══════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════
-- BDI-II (Beck Depression Inventory-II)
-- ═══════════════════════════════════════════════════════

INSERT INTO scale_templates (
    id, name, full_name, description, category, is_validated,
    reference, estimated_time_minutes, instructions,
    response_options, questions, scoring, subscales, alerts
) VALUES (
    'bdiii',
    'BDI-II',
    'Beck Depression Inventory-II',
    'Inventário de Depressão de Beck - Segunda Edição',
    'depression',
    true,
    'Beck, Steer & Brown, 1996',
    10,
    'Este questionário consiste em 21 grupos de afirmações. Cada grupo descreve um sintoma de depressão. Selecione a afirmação em cada grupo que melhor descreve como você se sentiu NAS ÚLTIMAS 2 SEMANAS, incluindo hoje.',

    -- Response Options (cada item tem 4 opções de 0 a 3)
    '[
        {"value": 0, "label": "Opção 0"},
        {"value": 1, "label": "Opção 1"},
        {"value": 2, "label": "Opção 2"},
        {"value": 3, "label": "Opção 3"}
    ]'::jsonb,

    -- Questions
    '[
        {"id": "q1", "order": 1, "text": "Tristeza", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não me sinto triste", "Sinto-me triste boa parte do tempo", "Estou sempre triste", "Sinto-me tão triste que não consigo suportar"]},
        {"id": "q2", "order": 2, "text": "Pessimismo", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null, "response_labels": ["Não me sinto desencorajado quanto ao meu futuro", "Sinto-me mais desencorajado quanto ao meu futuro do que costumava me sentir", "Não creio que as coisas vão melhorar para mim", "Sinto que não há esperança para o meu futuro e que só vai piorar"]},
        {"id": "q3", "order": 3, "text": "Sentimentos de Fracasso", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não me sinto um fracassado", "Sinto que fracassei mais do que a maioria das pessoas", "Quando olho para trás, na minha vida, tudo o que posso ver é uma porção de fracassos", "Sinto que sou um fracasso completo como pessoa"]},
        {"id": "q4", "order": 4, "text": "Perda de Prazer", "required": true, "subscale": "anedonia", "is_critical": false, "alert_threshold": null, "response_labels": ["Obtenho prazer nas coisas como sempre obtive", "Não obtenho tanto prazer nas coisas como costumava obter", "Obtenho muito menos prazer nas coisas do que costumava obter", "Não consigo obter prazer em nada do que faço"]},
        {"id": "q5", "order": 5, "text": "Sentimentos de Culpa", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não me sinto culpado(a) na maior parte do tempo", "Sinto-me culpado(a) boa parte do tempo", "Sinto-me culpado(a) a maior parte do tempo", "Sinto-me culpado(a) o tempo todo"]},
        {"id": "q6", "order": 6, "text": "Sentimentos de Punição", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não sinto que esteja sendo punido(a)", "Sinto que talvez esteja sendo punido(a)", "Espero ser punido(a)", "Sinto que estou sendo punido(a)"]},
        {"id": "q7", "order": 7, "text": "Descontentamento Consigo Mesmo", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Sinto-me da mesma forma em relação a mim mesmo(a) como sempre", "Perdi a confiança em mim mesmo(a)", "Estou desapontado(a) comigo mesmo(a)", "Não gosto de mim mesmo(a)"]},
        {"id": "q8", "order": 8, "text": "Autocrítica", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null, "response_labels": ["Não me sinto pior do que qualquer outra pessoa", "Sou crítico(a) comigo mesmo(a) por causa dos meus erros ou fraquezas", "Culpo-me constantemente por minhas faltas", "Culpo-me por tudo de ruim que acontece"]},
        {"id": "q9", "order": 9, "text": "Pensamentos ou Desejos Suicidas", "required": true, "subscale": "humor", "is_critical": true, "alert_threshold": 1, "response_labels": ["Não tenho nenhum pensamento de me matar", "Tenho pensamentos de me matar, mas não os executaria", "Eu me mataria", "Eu me mataria se tivesse oportunidade"]},
        {"id": "q10", "order": 10, "text": "Choro", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não choro mais do que o costume", "Choro mais agora do que costumava chorar", "Choro agora por qualquer coisinha", "Sinto vontade de chorar, mas não consigo"]},
        {"id": "q11", "order": 11, "text": "Agitação", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Não estou mais agitado(a) ou tenso(a) do que o habitual", "Sinto-me mais agitado(a) ou tenso(a) do que o habitual", "Estou tão agitado(a) que não consigo ficar parado(a)", "Estou tão agitado(a) que preciso estar sempre em movimento ou fazendo algo"]},
        {"id": "q12", "order": 12, "text": "Perda de Interesse", "required": true, "subscale": "anedonia", "is_critical": false, "alert_threshold": null, "response_labels": ["Não perdi o interesse em outras pessoas ou atividades", "Tenho menos interesse em outras pessoas ou coisas do que antes", "Perdi quase todo o meu interesse em outras pessoas ou coisas", "É difícil se interessar por qualquer coisa"]},
        {"id": "q13", "order": 13, "text": "Indecisão", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null, "response_labels": ["Tomo decisões normalmente", "Adio a tomada de decisões mais do que costumava", "Tenho mais dificuldade em tomar decisões do que antes", "Não consigo mais tomar decisões"]},
        {"id": "q14", "order": 14, "text": "Desvalorização", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null, "response_labels": ["Não sinto que não valha mais a pena", "Sinto que talvez não valha mais a pena", "Sinto que não valho mais a pena ao pensar em como sou comparado(a) com outras pessoas", "Sinto que não valho nada"]},
        {"id": "q15", "order": 15, "text": "Perda de Energia", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Tenho tanta energia quanto costumava ter", "Tenho menos energia do que costumava ter", "Não tenho energia suficiente para fazer muita coisa", "Não tenho energia suficiente para fazer nada"]},
        {"id": "q16", "order": 16, "text": "Alterações nos Padrões de Sono", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Meu padrão de sono não mudou", "Durmo um pouco mais do que o habitual", "Durmo muito mais do que o habitual", "Durmo a maior parte do dia"]},
        {"id": "q17", "order": 17, "text": "Irritabilidade", "required": true, "subscale": "humor", "is_critical": false, "alert_threshold": null, "response_labels": ["Não estou mais irritado(a) do que o habitual", "Estou mais irritado(a) do que o habitual", "Estou irritado(a) quase o tempo todo", "Não me irrito mais com as coisas que costumavam me irritar"]},
        {"id": "q18", "order": 18, "text": "Alterações no Apetite", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Meu apetite não mudou", "Meu apetite está um pouco maior ou menor do que o habitual", "Meu apetite está muito maior ou menor do que o habitual", "Não tenho apetite algum"]},
        {"id": "q19", "order": 19, "text": "Dificuldade de Concentração", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null, "response_labels": ["Posso me concentrar tão bem quanto sempre", "Não consigo me concentrar tão bem quanto o habitual", "É difícil manter minha atenção em qualquer coisa por muito tempo", "Não consigo me concentrar em nada"]},
        {"id": "q20", "order": 20, "text": "Cansaço ou Fadiga", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Não estou mais cansado(a) ou com mais fadiga do que o habitual", "Fico cansado(a) ou com fadiga mais facilmente do que o habitual", "Estou cansado(a) ou com fadiga demais para fazer muitas coisas que costumava fazer", "Estou cansado(a) ou com fadiga demais para fazer a maioria das coisas"]},
        {"id": "q21", "order": 21, "text": "Perda de Interesse em Sexo", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null, "response_labels": ["Não notei qualquer mudança recente no meu interesse por sexo", "Tenho menos interesse em sexo do que costumava ter", "Tenho muito menos interesse em sexo agora", "Perdi completamente o interesse em sexo"]}
    ]'::jsonb,

    -- Scoring
    '{
        "method": "sum",
        "min_score": 0,
        "max_score": 63,
        "reverse_items": [],
        "severity_ranges": [
            {"min": 0, "max": 13, "level": "minimal", "label": "Mínimo", "color": "#10B981"},
            {"min": 14, "max": 19, "level": "mild", "label": "Leve", "color": "#F59E0B"},
            {"min": 20, "max": 28, "level": "moderate", "label": "Moderado", "color": "#F97316"},
            {"min": 29, "max": 63, "level": "severe", "label": "Grave", "color": "#DC2626"}
        ],
        "clinical_cutoff": 20,
        "clinical_cutoff_description": "Score ≥ 20 sugere depressão moderada a grave. Encaminhamento para avaliação psiquiátrica recomendado."
    }'::jsonb,

    -- Subscales
    '[
        {"id": "humor", "name": "Humor", "items": ["q1", "q3", "q5", "q6", "q7", "q9", "q10", "q17"]},
        {"id": "cognitivo", "name": "Sintomas Cognitivos", "items": ["q2", "q8", "q13", "q14", "q19"]},
        {"id": "anedonia", "name": "Anedonia", "items": ["q4", "q12"]},
        {"id": "somático", "name": "Sintomas Somáticos", "items": ["q11", "q15", "q16", "q18", "q20", "q21"]}
    ]'::jsonb,

    -- Alerts
    '[
        {
            "condition": "q9 >= 1",
            "severity": "critical",
            "message": "Paciente relatou pensamentos suicidas (item 9 ≥ 1)",
            "action": "Avaliar risco de suicídio imediatamente. Considerar contato de emergência e protocolo de segurança."
        },
        {
            "condition": "total_score >= 29",
            "severity": "high",
            "message": "Score indica depressão grave",
            "action": "Encaminhamento psiquiátrico urgente. Avaliar necessidade de internação."
        },
        {
            "condition": "total_score >= 20",
            "severity": "medium",
            "message": "Score ≥ 20: depressão moderada a grave",
            "action": "Agendar avaliação detalhada. Considerar ajuste de tratamento."
        }
    ]'::jsonb
);


-- ═══════════════════════════════════════════════════════
-- BAI (Beck Anxiety Inventory)
-- ═══════════════════════════════════════════════════════

INSERT INTO scale_templates (
    id, name, full_name, description, category, is_validated,
    reference, estimated_time_minutes, instructions,
    response_options, questions, scoring, subscales, alerts
) VALUES (
    'bai',
    'BAI',
    'Beck Anxiety Inventory',
    'Inventário de Ansiedade de Beck',
    'anxiety',
    true,
    'Beck, Epstein, Brown & Steer, 1988',
    10,
    'Abaixo está uma lista de sintomas comuns de ansiedade. Leia cuidadosamente cada um dos sintomas e indique o quanto você foi incomodado(a) por ele NAS ÚLTIMAS SEMANAS, incluindo hoje.',

    -- Response Options
    '[
        {"value": 0, "label": "Nada"},
        {"value": 1, "label": "Levemente, não me incomodou muito"},
        {"value": 2, "label": "Moderadamente, não foi tão agradável"},
        {"value": 3, "label": "Severamente, incomodou-me muito"}
    ]'::jsonb,

    -- Questions
    '[
        {"id": "q1", "order": 1, "text": "Dormência ou formigamento", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q2", "order": 2, "text": "Sentir-se acalorado(a)", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q3", "order": 3, "text": "Tremor nas pernas", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q4", "order": 4, "text": "Incapaz de relaxar", "required": true, "subscale": "tensão", "is_critical": false, "alert_threshold": null},
        {"id": "q5", "order": 5, "text": "Medo de que algo pior vá acontecer", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null},
        {"id": "q6", "order": 6, "text": "Tontura ou vertigem", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q7", "order": 7, "text": "Aceleração do coração / palpitações", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q8", "order": 8, "text": "Sensação de desequilíbrio", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q9", "order": 9, "text": "Amedrontado(a) / com medo", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null},
        {"id": "q10", "order": 10, "text": "Nervosismo", "required": true, "subscale": "tensão", "is_critical": false, "alert_threshold": null},
        {"id": "q11", "order": 11, "text": "Sensação de sufocamento", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q12", "order": 12, "text": "Mãos tremendo", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q13", "order": 13, "text": "Trêmulo(a) / cambaleante", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q14", "order": 14, "text": "Medo de perder o controle", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null},
        {"id": "q15", "order": 15, "text": "Dificuldade em respirar", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q16", "order": 16, "text": "Medo de morrer", "required": true, "subscale": "cognitivo", "is_critical": true, "alert_threshold": 2},
        {"id": "q17", "order": 17, "text": "Assustado(a)", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null},
        {"id": "q18", "order": 18, "text": "Indigestão / desconforto abdominal", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q19", "order": 19, "text": "Desmaio / sensação de desmaio", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q20", "order": 20, "text": "Rosto ruborizado / corado", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q21", "order": 21, "text": "Suor (não devido ao calor ou exercício físico)", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null}
    ]'::jsonb,

    -- Scoring
    '{
        "method": "sum",
        "min_score": 0,
        "max_score": 63,
        "reverse_items": [],
        "severity_ranges": [
            {"min": 0, "max": 9, "level": "minimal", "label": "Mínimo", "color": "#10B981"},
            {"min": 10, "max": 18, "level": "mild", "label": "Leve", "color": "#F59E0B"},
            {"min": 19, "max": 29, "level": "moderate", "label": "Moderado", "color": "#F97316"},
            {"min": 30, "max": 63, "level": "severe", "label": "Grave", "color": "#DC2626"}
        ],
        "clinical_cutoff": 19,
        "clinical_cutoff_description": "Score ≥ 19 sugere ansiedade clinicamente significativa. Avaliação adicional recomendada."
    }'::jsonb,

    -- Subscales
    '[
        {"id": "somático", "name": "Sintomas Somáticos", "items": ["q1", "q2", "q3", "q6", "q7", "q8", "q11", "q12", "q13", "q15", "q18", "q19", "q20", "q21"]},
        {"id": "cognitivo", "name": "Sintomas Cognitivos", "items": ["q5", "q9", "q14", "q16", "q17"]},
        {"id": "tensão", "name": "Tensão", "items": ["q4", "q10"]}
    ]'::jsonb,

    -- Alerts
    '[
        {
            "condition": "q16 >= 2",
            "severity": "critical",
            "message": "Paciente relatou medo de morrer severamente (item 16 ≥ 2)",
            "action": "Avaliar risco de ataque de pânico. Considerar intervenção imediata."
        },
        {
            "condition": "total_score >= 30",
            "severity": "high",
            "message": "Score indica ansiedade severa",
            "action": "Encaminhamento para avaliação psiquiátrica. Considerar intervenção farmacológica."
        },
        {
            "condition": "total_score >= 19",
            "severity": "medium",
            "message": "Score ≥ 19: ansiedade moderada a severa",
            "action": "Agendar avaliação detalhada. Considerar técnicas de manejo de ansiedade."
        }
    ]'::jsonb
);


-- ═══════════════════════════════════════════════════════
-- OQ-45 (Outcome Questionnaire-45)
-- ═══════════════════════════════════════════════════════

INSERT INTO scale_templates (
    id, name, full_name, description, category, is_validated,
    reference, estimated_time_minutes, instructions,
    response_options, questions, scoring, subscales, alerts
) VALUES (
    'oq45',
    'OQ-45',
    'Outcome Questionnaire-45',
    'Questionário de Resultados - 45 itens',
    'progress',
    true,
    'Lambert et al., 1996',
    15,
    'Abaixo estão uma série de afirmações sobre suas emoções e comportamento. Para cada afirmação, assinale a alternativa que melhor descreve como você se sentiu NAS ÚLTIMAS SEMANAS.',

    -- Response Options
    '[
        {"value": 0, "label": "Nunca"},
        {"value": 1, "label": "Raramente"},
        {"value": 2, "label": "Às vezes"},
        {"value": 3, "label": "Frequentemente"},
        {"value": 4, "label": "Quase sempre"}
    ]'::jsonb,

    -- Questions (com itens reversos marcados)
    '[
        {"id": "q1", "order": 1, "text": "Sinto-me triste", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q2", "order": 2, "text": "Sinto-me desapontado(a) comigo mesmo(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q3", "order": 3, "text": "Sinto-me valorizado(a) pelos outros", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q4", "order": 4, "text": "Sinto que as coisas estão indo bem para mim", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q5", "order": 5, "text": "Sinto-me ansioso(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q6", "order": 6, "text": "Sinto-me satisfeito(a) com meu relacionamento com amigos íntimos", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q7", "order": 7, "text": "Tenho pensamentos de acabar com minha vida", "required": true, "subscale": "sintomas", "is_critical": true, "alert_threshold": 2},
        {"id": "q8", "order": 8, "text": "Sinto-me útil no meu dia a dia", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q9", "order": 9, "text": "Sinto-me sem esperança quanto ao futuro", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q10", "order": 10, "text": "Sinto que tenho pessoas com quem posso contar", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q11", "order": 11, "text": "Sinto-me sobrecarregado(a) com responsabilidades", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q12", "order": 12, "text": "Sinto-me satisfeito(a) com meu trabalho/estudo", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q13", "order": 13, "text": "Sinto-me irritado(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q14", "order": 14, "text": "Sinto-me próximo(a) de minha família", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q15", "order": 15, "text": "Sinto-me sem energia", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q16", "order": 16, "text": "Sinto-me insatisfeito(a) com meu relacionamento amoroso", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null},
        {"id": "q17", "order": 17, "text": "Sinto-me culpado(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q18", "order": 18, "text": "Consigo me concentrar bem", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q19", "order": 19, "text": "Sinto-me isolado(a)", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null},
        {"id": "q20", "order": 20, "text": "Sinto-me cansado(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q21", "order": 21, "text": "Sinto-me satisfeito(a) com minha vida social", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q22", "order": 22, "text": "Sinto-me tenso(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q23", "order": 23, "text": "Sinto-me satisfeito(a) com minha situação financeira", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q24", "order": 24, "text": "Sinto-me sem valor", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q25", "order": 25, "text": "Consigo lidar com os problemas do dia a dia", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q26", "order": 26, "text": "Sinto-me deprimido(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q27", "order": 27, "text": "Sinto-me satisfeito(a) com minha saúde", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q28", "order": 28, "text": "Sinto-me com medo", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q29", "order": 29, "text": "Tenho bons amigos", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q30", "order": 30, "text": "Sinto-me sem esperança", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q31", "order": 31, "text": "Sinto-me satisfeito(a) com meu lazer", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q32", "order": 32, "text": "Sinto-me infeliz", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q33", "order": 33, "text": "Sinto-me bem comigo mesmo(a)", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q34", "order": 34, "text": "Sinto-me preocupado(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q35", "order": 35, "text": "Sinto-me capaz de pedir ajuda", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q36", "order": 36, "text": "Sinto-me com dificuldade para dormir", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q37", "order": 37, "text": "Sinto-me satisfeito(a) com meu desempenho no trabalho/estudo", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q38", "order": 38, "text": "Sinto-me sem paciência", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q39", "order": 39, "text": "Sinto-me incompreendido(a) pelos outros", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null},
        {"id": "q40", "order": 40, "text": "Sinto-me estressado(a)", "required": true, "subscale": "sintomas", "is_critical": false, "alert_threshold": null},
        {"id": "q41", "order": 41, "text": "Sinto que a vida vale a pena", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true},
        {"id": "q42", "order": 42, "text": "Sinto-me sozinho(a)", "required": true, "subscale": "relacoes", "is_critical": false, "alert_threshold": null},
        {"id": "q43", "order": 43, "text": "Sinto que não tenho controle sobre minha vida", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null},
        {"id": "q44", "order": 44, "text": "Sinto-me com dificuldade para tomar decisões", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null},
        {"id": "q45", "order": 45, "text": "Sinto que tenho um propósito de vida", "required": true, "subscale": "funcionamento", "is_critical": false, "alert_threshold": null, "reverse": true}
    ]'::jsonb,

    -- Scoring
    '{
        "method": "sum",
        "min_score": 0,
        "max_score": 180,
        "reverse_items": ["q3", "q4", "q6", "q8", "q10", "q12", "q14", "q18", "q21", "q23", "q25", "q27", "q29", "q31", "q33", "q35", "q37", "q41", "q45"],
        "severity_ranges": [
            {"min": 0, "max": 63, "level": "functional", "label": "Funcional", "color": "#10B981"},
            {"min": 64, "max": 90, "level": "subclinical", "label": "Subclínico", "color": "#F59E0B"},
            {"min": 91, "max": 120, "level": "clinical", "label": "Clínico", "color": "#F97316"},
            {"min": 121, "max": 180, "level": "severe", "label": "Grave", "color": "#DC2626"}
        ],
        "clinical_cutoff": 64,
        "clinical_cutoff_description": "Score ≥ 64 sugere desconforto clínico significativo. Paciente na faixa clínica da população."
    }'::jsonb,

    -- Subscales
    '[
        {"id": "sintomas", "name": "Sintomas (SD)", "items": ["q1", "q2", "q5", "q7", "q9", "q11", "q13", "q15", "q17", "q20", "q22", "q24", "q26", "q28", "q30", "q32", "q34", "q36", "q38", "q40", "q42"]},
        {"id": "relacoes", "name": "Relações Interpessoais (RI)", "items": ["q3", "q6", "q10", "q14", "q16", "q19", "q21", "q29", "q35", "q39", "q42"]},
        {"id": "funcionamento", "name": "Funcionamento Social (FS)", "items": ["q4", "q8", "q12", "q18", "q23", "q25", "q27", "q31", "q33", "q37", "q41", "q43", "q44", "q45"]}
    ]'::jsonb,

    -- Alerts
    '[
        {
            "condition": "q7 >= 2",
            "severity": "critical",
            "message": "Paciente relatou pensamentos de suicídio frequentes (item 7 ≥ 2)",
            "action": "Avaliar risco de suicídio imediatamente. Considerar contato de emergência e protocolo de segurança."
        },
        {
            "condition": "total_score >= 121",
            "severity": "high",
            "message": "Score indica sofrimento severo",
            "action": "Avaliação urgente necessária. Considerar intervenção intensiva."
        },
        {
            "condition": "total_score >= 64",
            "severity": "medium",
            "message": "Score ≥ 64: paciente na faixa clínica",
            "action": "Monitorar evolução. Avaliar necessidade de ajuste no tratamento."
        }
    ]'::jsonb
);


-- ═══════════════════════════════════════════════════════
-- VERIFICAÇÃO
-- ═══════════════════════════════════════════════════════

-- Confirmar que todas as escalas foram inseridas
SELECT 
    id, 
    name, 
    full_name, 
    category, 
    jsonb_array_length(questions) as question_count,
    is_validated
FROM scale_templates
ORDER BY id;

-- ═══════════════════════════════════════════════════════
-- FIM DO SEED
-- ✅ BDI-II: 21 itens - Inventário de Depressão de Beck
-- ✅ BAI: 21 itens - Inventário de Ansiedade de Beck
-- ✅ OQ-45: 45 itens - Questionário de Resultados
-- ═══════════════════════════════════════════════════════
