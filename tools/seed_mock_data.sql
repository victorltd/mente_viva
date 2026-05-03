-- ═══════════════════════════════════════════════════════
-- SEED: Dados Fictícios para Testes (MenteViva)
-- ═══════════════════════════════════════════════════════
-- Objetivo: Gerar histórico de check-ins, escalas e tarefas
-- para um paciente existente para fins de teste e validação de UI.
--
-- COMO USAR:
-- 1. No Supabase, vá em "SQL Editor".
-- 2. Substitua 'SEU_PATIENT_ID_AQUI' pelo ID de um paciente real.
-- 3. Substitua 'SEU_PSY_ID_AQUI' pelo ID de um psicólogo real.
-- 4. Execute o script.

-- ═══════════════════════════════════════════════════════
-- CONFIGURAÇÃO (EDITE AQUI)
-- ═══════════════════════════════════════════════════════
DO $$
DECLARE
    v_patient_id UUID := 'SEU_PATIENT_ID_AQUI'::UUID;
    v_psy_id UUID := 'SEU_PSY_ID_AQUI'::UUID;
    v_assignment_id UUID;
    v_day INT;
    v_mood INT;
    v_date DATE;
BEGIN
    -- 1. Verificar se os IDs foram atualizados
    IF v_patient_id = '00000000-0000-0000-0000-000000000000' THEN
        RAISE EXCEPTION 'Por favor, edite o script e coloque o ID real do paciente.';
    END IF;

    -- ═══════════════════════════════════════════════════════
    -- 1. GERAR CHECK-INS (Últimos 30 dias)
    ═══════════════════════════════════════════════════════
    RAISE NOTICE 'Gerando Check-ins...';
    
    FOR v_day IN 0..29 LOOP
        v_date := CURRENT_DATE - v_day;
        
        -- Humor variável (entre 2 e 5 para simular melhora)
        v_mood := CASE 
            WHEN v_day > 20 THEN 4 + (random()::int % 2) -- Melhora recente
            WHEN v_day > 10 THEN 3 + (random()::int % 2) -- Médio
            ELSE 2 + (random()::int % 3)                 -- Pior no início
        END;

        INSERT INTO checkins (patient_id, mood_score, primary_emotion, notes, created_at)
        VALUES (
            v_patient_id,
            v_mood,
            CASE v_mood 
                WHEN 1 THEN 'tristeza'
                WHEN 2 THEN 'ansiedade'
                WHEN 3 THEN 'neutro'
                WHEN 4 THEN 'alívio'
                ELSE 'alegria'
            END,
            CASE WHEN v_day = 5 THEN 'Dia difícil, muita insônia'
                 WHEN v_day = 25 THEN 'Me sentindo muito melhor hoje!'
                 ELSE NULL
            END,
            v_date + (time '09:00:00' + (random() * interval '4 hours'))
        );
    END LOOP;

    -- ═══════════════════════════════════════════════════════
    -- 2. CRIAR ASSIGNMENT DE ESCALA (PHQ-9)
    ═══════════════════════════════════════════════════════
    RAISE NOTICE 'Criando Assignment de Escala...';

    INSERT INTO scale_assignments (patient_id, psychologist_id, scale_template_id, frequency, status, start_date, created_at)
    VALUES (v_patient_id, v_psy_id, 'phq9', 'weekly', 'active', CURRENT_DATE - 30, CURRENT_DATE - 30)
    RETURNING id INTO v_assignment_id;

    -- ═══════════════════════════════════════════════════════
    -- 3. GERAR RESPOSTAS DE ESCALA (Semanal)
    ═══════════════════════════════════════════════════════
    RAISE NOTICE 'Gerando Respostas de Escala...';

    -- Semana 1 (Score alto ~ 18)
    INSERT INTO scale_responses (assignment_id, patient_id, answers, total_score, severity_level, subscale_scores, critical_flags, completed_at, created_at)
    VALUES (
        v_assignment_id, v_patient_id,
        '{"q1": 2, "q2": 3, "q3": 2, "q4": 2, "q5": 1, "q6": 2, "q7": 2, "q8": 2, "q9": 2}',
        18, 'moderately_severe', '{"mood": 2.5, "anhedonia": 2.0}', '[]',
        CURRENT_DATE - 25, CURRENT_DATE - 25
    );

    -- Semana 2 (Score médio ~ 14)
    INSERT INTO scale_responses (assignment_id, patient_id, answers, total_score, severity_level, subscale_scores, critical_flags, completed_at, created_at)
    VALUES (
        v_assignment_id, v_patient_id,
        '{"q1": 1, "q2": 2, "q3": 2, "q4": 2, "q5": 1, "q6": 1, "q7": 2, "q8": 1, "q9": 2}',
        14, 'moderate', '{"mood": 1.8, "anhedonia": 1.5}', '[]',
        CURRENT_DATE - 18, CURRENT_DATE - 18
    );

    -- Semana 3 (Score baixo ~ 9)
    INSERT INTO scale_responses (assignment_id, patient_id, answers, total_score, severity_level, subscale_scores, critical_flags, completed_at, created_at)
    VALUES (
        v_assignment_id, v_patient_id,
        '{"q1": 1, "q2": 1, "q3": 1, "q4": 1, "q5": 0, "q6": 1, "q7": 1, "q8": 1, "q9": 2}',
        9, 'mild', '{"mood": 1.0, "anhedonia": 1.0}', '[{"question_id": "q9", "value": 2, "threshold": 1, "message": "Item crítico"}]',
        CURRENT_DATE - 11, CURRENT_DATE - 11
    );

    -- Semana 4 (Score muito baixo ~ 5)
    INSERT INTO scale_responses (assignment_id, patient_id, answers, total_score, severity_level, subscale_scores, critical_flags, completed_at, created_at)
    VALUES (
        v_assignment_id, v_patient_id,
        '{"q1": 0, "q2": 1, "q3": 0, "q4": 1, "q5": 0, "q6": 0, "q7": 1, "q8": 0, "q9": 2}',
        5, 'minimal', '{"mood": 0.5, "anhedonia": 0.5}', '[{"question_id": "q9", "value": 2, "threshold": 1, "message": "Item crítico"}]',
        CURRENT_DATE - 4, CURRENT_DATE - 4
    );

    -- ═══════════════════════════════════════════════════════
    -- 4. GERAR TAREFAS
    ═══════════════════════════════════════════════════════
    RAISE NOTICE 'Gerando Tarefas...';

    -- Tarefa Concluída
    INSERT INTO tasks (patient_id, psychologist_id, title, description, frequency, status, due_date, completed_at, created_at)
    VALUES (
        v_patient_id, v_psy_id,
        'Diário de Gratidão', 'Escreva 3 coisas pelas quais você é grato hoje.',
        'daily', 'completed', CURRENT_DATE, CURRENT_DATE - (random() * interval '12 hours')::int,
        CURRENT_DATE - 1
    );

    -- Tarefa Pendente
    INSERT INTO tasks (patient_id, psychologist_id, title, description, frequency, status, due_date, created_at)
    VALUES (
        v_patient_id, v_psy_id,
        'Exercício de Respiração', 'Faça 5 minutos de respiração 4-7-8.',
        'daily', 'active', CURRENT_DATE,
        CURRENT_DATE - 1
    );

    RAISE NOTICE '✅ Dados fictícios gerados com sucesso!';
END $$;
