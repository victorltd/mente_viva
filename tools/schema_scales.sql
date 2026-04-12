-- ═══════════════════════════════════════════════════════
-- MenteViva - Sistema de Escalas Psicológicas
-- Schema completo para Supabase (PostgreSQL)
-- Abordagem 2: Tabelas separadas (templates vs custom)
-- ═══════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════
-- ENUMS
-- ═══════════════════════════════════════════════════════

CREATE TYPE scale_category AS ENUM (
    'depression',
    'anxiety',
    'progress',
    'general'
);

CREATE TYPE scale_frequency AS ENUM (
    'once',
    'weekly',
    'biweekly',
    'monthly',
    'custom'
);

CREATE TYPE assignment_status AS ENUM (
    'active',
    'paused',
    'completed'
);


-- ═══════════════════════════════════════════════════════
-- 1. scale_templates (escalas padrão, read-only)
-- ═══════════════════════════════════════════════════════

CREATE TABLE scale_templates (
    id              TEXT PRIMARY KEY,           -- 'phq9', 'gad7', 'bdiii', 'bai', 'oq45'
    name            TEXT NOT NULL,              -- Nome curto
    full_name       TEXT NOT NULL,              -- Nome completo
    description     TEXT,
    category        scale_category NOT NULL,
    is_validated    BOOLEAN NOT NULL DEFAULT true,
    reference       TEXT,                       -- Autor et al., Ano
    estimated_time_minutes INTEGER DEFAULT 5,

    instructions    TEXT NOT NULL,
    response_options JSONB NOT NULL,            -- [{"value": 0, "label": "..."}]
    questions       JSONB NOT NULL,             -- Array de perguntas
    scoring         JSONB NOT NULL,             -- Config de pontuação
    subscales       JSONB DEFAULT '[]'::jsonb,  -- Subescalas (pode ser vazio)
    alerts          JSONB DEFAULT '[]'::jsonb,  -- Regras de alerta

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice por categoria (filtro na tela de seleção)
CREATE INDEX idx_scale_templates_category ON scale_templates(category);


-- ═══════════════════════════════════════════════════════
-- 2. custom_scales (criadas/editadas pelo psicólogo)
-- ═══════════════════════════════════════════════════════

CREATE TABLE custom_scales (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    psychologist_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    base_template_id    TEXT REFERENCES scale_templates(id) ON DELETE SET NULL,

    name                TEXT NOT NULL,
    description         TEXT,
    instructions        TEXT NOT NULL,
    response_options    JSONB NOT NULL,
    questions           JSONB NOT NULL,
    scoring             JSONB NOT NULL,
    subscales           JSONB DEFAULT '[]'::jsonb,
    alerts              JSONB DEFAULT '[]'::jsonb,

    is_validated        BOOLEAN NOT NULL DEFAULT false,
    is_draft            BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice por psicólogo
CREATE INDEX idx_custom_scales_psychologist ON custom_scales(psychologist_id);

-- Índice para saber qual template foi customizado
CREATE INDEX idx_custom_scales_base_template ON custom_scales(base_template_id);


-- ═══════════════════════════════════════════════════════
-- 3. scale_assignments (escala atribuída a paciente)
-- ═══════════════════════════════════════════════════════

CREATE TABLE scale_assignments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    psychologist_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Referencia uma OU outra (exclusivo)
    scale_template_id   TEXT REFERENCES scale_templates(id) ON DELETE CASCADE,
    custom_scale_id     UUID REFERENCES custom_scales(id) ON DELETE CASCADE,

    frequency           scale_frequency NOT NULL DEFAULT 'once',
    status              assignment_status NOT NULL DEFAULT 'active',

    start_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    next_due_date       DATE,
    last_completed_at   TIMESTAMPTZ,

    notify_patient      BOOLEAN NOT NULL DEFAULT true,
    custom_instructions TEXT,  -- Instruções extras do psicólogo

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garante que só uma das duas FKs é preenchida
    CONSTRAINT chk_scale_reference CHECK (
        (scale_template_id IS NOT NULL AND custom_scale_id IS NULL) OR
        (scale_template_id IS NULL AND custom_scale_id IS NOT NULL)
    )
);

-- Índices de consulta frequente
CREATE INDEX idx_scale_assignments_patient ON scale_assignments(patient_id);
CREATE INDEX idx_scale_assignments_psychologist ON scale_assignments(psychologist_id);
CREATE INDEX idx_scale_assignments_status ON scale_assignments(status);

-- Índice composto: escalas ativas por paciente (filtro por due_date feito na query)
CREATE INDEX idx_scale_assignments_patient_due
    ON scale_assignments(patient_id, next_due_date)
    WHERE status = 'active';


-- ═══════════════════════════════════════════════════════
-- 4. scale_responses (respostas do paciente)
-- ═══════════════════════════════════════════════════════

CREATE TABLE scale_responses (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id       UUID NOT NULL REFERENCES scale_assignments(id) ON DELETE CASCADE,
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    answers             JSONB NOT NULL,           -- {"q1": 2, "q2": 1, ...}
    total_score         INTEGER NOT NULL,
    severity_level      TEXT,                     -- 'minimal', 'mild', 'moderate', etc.
    subscale_scores     JSONB DEFAULT '{}'::jsonb, -- {"anhedonia": 8, "mood": 4}

    critical_flags      JSONB DEFAULT '[]'::jsonb, -- [{"question_id": "q9", "value": 3, "message": "..."}]
    has_critical_item   BOOLEAN NOT NULL DEFAULT false,

    completed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_seconds    INTEGER,                  -- Tempo gasto em segundos

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices de consulta frequente
CREATE INDEX idx_scale_responses_assignment ON scale_responses(assignment_id);
CREATE INDEX idx_scale_responses_patient ON scale_responses(patient_id);
CREATE INDEX idx_scale_responses_completed ON scale_responses(patient_id, completed_at DESC);

-- Índice para detectar respostas recentes com item crítico
CREATE INDEX idx_scale_responses_critical
    ON scale_responses(patient_id, completed_at DESC)
    WHERE has_critical_item = true;


-- ═══════════════════════════════════════════════════════
-- TRIGGER: Atualizar updated_at automaticamente
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_scale_templates_updated
    BEFORE UPDATE ON scale_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_custom_scales_updated
    BEFORE UPDATE ON custom_scales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_scale_assignments_updated
    BEFORE UPDATE ON scale_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ═══════════════════════════════════════════════════════
-- TRIGGER: Após resposta, atualizar last_completed_at e next_due_date
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_assignment_after_response()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE scale_assignments
    SET
        last_completed_at = NEW.completed_at,
        next_due_date = CASE
            WHEN (SELECT frequency FROM scale_assignments WHERE id = NEW.assignment_id) = 'weekly'
                THEN NEW.completed_at::date + INTERVAL '7 days'
            WHEN (SELECT frequency FROM scale_assignments WHERE id = NEW.assignment_id) = 'biweekly'
                THEN NEW.completed_at::date + INTERVAL '14 days'
            WHEN (SELECT frequency FROM scale_assignments WHERE id = NEW.assignment_id) = 'monthly'
                THEN NEW.completed_at::date + INTERVAL '1 month'
            WHEN (SELECT frequency FROM scale_assignments WHERE id = NEW.assignment_id) = 'once'
                THEN NULL  -- Não precisa de próxima
            ELSE NULL
        END,
        status = CASE
            WHEN (SELECT frequency FROM scale_assignments WHERE id = NEW.assignment_id) = 'once'
                THEN 'completed'::assignment_status
            ELSE 'active'::assignment_status
        END
    WHERE id = NEW.assignment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_assignment_after_response
    AFTER INSERT ON scale_responses
    FOR EACH ROW EXECUTE FUNCTION update_assignment_after_response();


-- ═══════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════

ALTER TABLE scale_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scales ENABLE ROW LEVEL SECURITY;
ALTER TABLE scale_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE scale_responses ENABLE ROW LEVEL SECURITY;


-- ── scale_templates: leitura pública para authenticated ──

CREATE POLICY "Templates são legíveis por todos autenticados"
    ON scale_templates FOR SELECT
    TO authenticated
    USING (true);

-- Templates são read-only (sem INSERT/UPDATE/DELETE pelo app)


-- ── custom_scales: psicólogo vê/edita as suas ──

CREATE POLICY "Psicólogo vê suas próprias escalas customizadas"
    ON custom_scales FOR SELECT
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
        OR
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.psychologist_id = custom_scales.psychologist_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Psicólogo cria suas escalas customizadas"
    ON custom_scales FOR INSERT
    TO authenticated
    WITH CHECK (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );

CREATE POLICY "Psicólogo edita suas escalas customizadas"
    ON custom_scales FOR UPDATE
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );

CREATE POLICY "Psicólogo exclui suas escalas customizadas"
    ON custom_scales FOR DELETE
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );


-- ── scale_assignments: psicólogo vê seus, paciente vê as suas ──

CREATE POLICY "Visualizar assignments (psicólogo e paciente)"
    ON scale_assignments FOR SELECT
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
        OR
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Psicólogo cria assignments"
    ON scale_assignments FOR INSERT
    TO authenticated
    WITH CHECK (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );

CREATE POLICY "Psicólogo edita assignments"
    ON scale_assignments FOR UPDATE
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );

CREATE POLICY "Psicólogo exclui assignments"
    ON scale_assignments FOR DELETE
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );


-- ── scale_responses: psicólogo vê dos seus pacientes, paciente vê as suas ──

CREATE POLICY "Visualizar respostas (psicólogo e paciente)"
    ON scale_responses FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM scale_assignments sa
            JOIN patients p ON sa.patient_id = p.id
            WHERE sa.id = scale_responses.assignment_id
            AND p.psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
        )
    );

CREATE POLICY "Paciente cria suas respostas"
    ON scale_responses FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Paciente edita suas respostas"
    ON scale_responses FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Paciente NÃO pode deletar respostas (histórico clínico)
-- Psicólogo também NÃO pode deletar


-- ═══════════════════════════════════════════════════════
-- SEED: Escalas padrão (PHQ-9 e GAD-7)
-- ═══════════════════════════════════════════════════════

-- ── PHQ-9 (Patient Health Questionnaire-9) ──

INSERT INTO scale_templates (
    id, name, full_name, description, category, is_validated,
    reference, estimated_time_minutes, instructions,
    response_options, questions, scoring, subscales, alerts
) VALUES (
    'phq9',
    'PHQ-9',
    'Patient Health Questionnaire-9',
    'Questionário de saúde do paciente - Rastreio de depressão',
    'depression',
    true,
    'Kroenke et al., 2001',
    3,
    'Nas últimas 2 semanas, com que frequência você foi incomodado(a) pelos problemas abaixo?',

    -- Response Options
    '[
        {"value": 0, "label": "Nenhuma vez"},
        {"value": 1, "label": "Vários dias"},
        {"value": 2, "label": "Mais da metade dos dias"},
        {"value": 3, "label": "Quase todos os dias"}
    ]'::jsonb,

    -- Questions
    '[
        {"id": "q1", "order": 1, "text": "Pouco interesse ou prazer em fazer as coisas", "required": true, "subscale": "anhedonia", "is_critical": false, "alert_threshold": null},
        {"id": "q2", "order": 2, "text": "Sentir-se triste, para baixo(a), sem esperança", "required": true, "subscale": "mood", "is_critical": false, "alert_threshold": null},
        {"id": "q3", "order": 3, "text": "Dificuldade para adormecer, permanecer dormindo ou dormir demais", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q4", "order": 4, "text": "Sentir-se cansado(a) ou com pouca energia", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q5", "order": 5, "text": "Pouco apetite ou comer demais", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q6", "order": 6, "text": "Sentir-se mal consigo mesmo(a) — ou achar que é um(a) fracassado(a) ou que decepcionou a si mesmo(a) ou sua família", "required": true, "subscale": "mood", "is_critical": false, "alert_threshold": null},
        {"id": "q7", "order": 7, "text": "Dificuldade de concentração em atividades como ler ou assistir TV", "required": true, "subscale": "cognitivo", "is_critical": false, "alert_threshold": null},
        {"id": "q8", "order": 8, "text": "Movendo ou falando tão devagar que outras pessoas poderiam notar? Ou, pelo contrário, movendo-se muito mais que o habitual, a ponto de ficar agitado(a) e inquieto(a)", "required": true, "subscale": "somático", "is_critical": false, "alert_threshold": null},
        {"id": "q9", "order": 9, "text": "Pensamentos de que seria melhor estar(a) morto(a) ou de se machucar de alguma forma", "required": true, "subscale": "mood", "is_critical": true, "alert_threshold": 1}
    ]'::jsonb,

    -- Scoring
    '{
        "method": "sum",
        "min_score": 0,
        "max_score": 27,
        "reverse_items": [],
        "severity_ranges": [
            {"min": 0, "max": 4, "level": "minimal", "label": "Mínimo", "color": "#10B981"},
            {"min": 5, "max": 9, "level": "mild", "label": "Leve", "color": "#F59E0B"},
            {"min": 10, "max": 14, "level": "moderate", "label": "Moderado", "color": "#F97316"},
            {"min": 15, "max": 19, "level": "moderately_severe", "label": "Moderadamente Grave", "color": "#EF4444"},
            {"min": 20, "max": 27, "level": "severe", "label": "Grave", "color": "#DC2626"}
        ],
        "clinical_cutoff": 10,
        "clinical_cutoff_description": "Score ≥ 10 sugere depressão clinicamente significativa. Encaminhamento para avaliação detalhada recomendado."
    }'::jsonb,

    -- Subscales
    '[
        {"id": "anhedonia", "name": "Anedonia", "items": ["q1"]},
        {"id": "mood", "name": "Humor", "items": ["q2", "q6", "q9"]},
        {"id": "somático", "name": "Sintomas Somáticos", "items": ["q3", "q4", "q5", "q8"]},
        {"id": "cognitivo", "name": "Sintomas Cognitivos", "items": ["q7"]}
    ]'::jsonb,

    -- Alerts
    '[
        {
            "condition": "q9 >= 1",
            "severity": "critical",
            "message": "Paciente relatou pensamentos de autoagressão (item 9 ≥ 1)",
            "action": "Avaliar risco de suicídio imediatamente. Considerar contato de emergência e protocolo de segurança."
        },
        {
            "condition": "total_score >= 15",
            "severity": "high",
            "message": "Score indica depressão moderadamente grave a grave",
            "action": "Agendar avaliação urgente. Considerar encaminhamento para psiquiatria."
        },
        {
            "condition": "total_score >= 10",
            "severity": "medium",
            "message": "Score ≥ 10: possível depressão clinicamente significativa",
            "action": "Avaliar com entrevista clínica detalhada. Monitorar evolução nas próximas aplicações."
        }
    ]'::jsonb
);


-- ── GAD-7 (Generalized Anxiety Disorder-7) ──

INSERT INTO scale_templates (
    id, name, full_name, description, category, is_validated,
    reference, estimated_time_minutes, instructions,
    response_options, questions, scoring, subscales, alerts
) VALUES (
    'gad7',
    'GAD-7',
    'Generalized Anxiety Disorder-7',
    'Questionário de Transtorno de Ansiedade Generalizada',
    'anxiety',
    true,
    'Spitzer et al., 2006',
    3,
    'Nas últimas 2 semanas, com que frequência você foi incomodado(a) pelos problemas abaixo?',

    -- Response Options
    '[
        {"value": 0, "label": "Nenhuma vez"},
        {"value": 1, "label": "Vários dias"},
        {"value": 2, "label": "Mais da metade dos dias"},
        {"value": 3, "label": "Quase todos os dias"}
    ]'::jsonb,

    -- Questions
    '[
        {"id": "q1", "order": 1, "text": "Sentir-se nervoso(a), ansioso(a) ou muito tenso(a)", "required": true, "subscale": "ansiedade", "is_critical": false, "alert_threshold": null},
        {"id": "q2", "order": 2, "text": "Não conseguir impedir ou controlar as preocupações", "required": true, "subscale": "preocupação", "is_critical": false, "alert_threshold": null},
        {"id": "q3", "order": 3, "text": "Preocupar-se muito com diversas coisas", "required": true, "subscale": "preocupação", "is_critical": false, "alert_threshold": null},
        {"id": "q4", "order": 4, "text": "Dificuldade para relaxar", "required": true, "subscale": "ansiedade", "is_critical": false, "alert_threshold": null},
        {"id": "q5", "order": 5, "text": "Ficar tão agitado(a) que é difícil permanecer sentado(a)", "required": true, "subscale": "agitação", "is_critical": false, "alert_threshold": null},
        {"id": "q6", "order": 6, "text": "Ficar facilmente aborrecido(a) ou irritado(a)", "required": true, "subscale": "irritabilidade", "is_critical": false, "alert_threshold": null},
        {"id": "q7", "order": 7, "text": "Sentir medo, como se algo horrível fosse acontecer", "required": true, "subscale": "medo", "is_critical": false, "alert_threshold": null}
    ]'::jsonb,

    -- Scoring
    '{
        "method": "sum",
        "min_score": 0,
        "max_score": 21,
        "reverse_items": [],
        "severity_ranges": [
            {"min": 0, "max": 4, "level": "minimal", "label": "Mínimo", "color": "#10B981"},
            {"min": 5, "max": 9, "level": "mild", "label": "Leve", "color": "#F59E0B"},
            {"min": 10, "max": 14, "level": "moderate", "label": "Moderado", "color": "#F97316"},
            {"min": 15, "max": 21, "level": "severe", "label": "Grave", "color": "#EF4444"}
        ],
        "clinical_cutoff": 10,
        "clinical_cutoff_description": "Score ≥ 10 sugere transtorno de ansiedade generalizada clinicamente significativo."
    }'::jsonb,

    -- Subscales
    '[
        {"id": "ansiedade", "name": "Ansiedade", "items": ["q1", "q4"]},
        {"id": "preocupação", "name": "Preocupação", "items": ["q2", "q3"]},
        {"id": "agitação", "name": "Agitação Motora", "items": ["q5"]},
        {"id": "irritabilidade", "name": "Irritabilidade", "items": ["q6"]},
        {"id": "medo", "name": "Medo Antecipatório", "items": ["q7"]}
    ]'::jsonb,

    -- Alerts
    '[
        {
            "condition": "total_score >= 15",
            "severity": "high",
            "message": "Score indica ansiedade grave",
            "action": "Avaliar impacto funcional. Considerar encaminhamento para avaliação psiquiátrica."
        },
        {
            "condition": "total_score >= 10",
            "severity": "medium",
            "message": "Score ≥ 10: possível TAG clinicamente significativo",
            "action": "Avaliar com entrevista clínica. Monitorar evolução nas próximas aplicações."
        }
    ]'::jsonb
);


-- ═══════════════════════════════════════════════════════
-- FUNÇÃO UTILITÁRIA: Calcular score de uma resposta
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION calculate_scale_score(
    p_answers JSONB,
    p_scoring JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_total INTEGER := 0;
    v_key TEXT;
    v_value INTEGER;
BEGIN
    -- Soma todos os valores das respostas
    FOR v_key, v_value IN SELECT key, (value)::INTEGER FROM jsonb_each(p_answers)
    LOOP
        v_total := v_total + v_value;
    END LOOP;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- ═══════════════════════════════════════════════════════
-- FUNÇÃO UTILITÁRIA: Verificar critical flags
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION check_critical_items(
    p_answers JSONB,
    p_questions JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_flags JSONB := '[]'::jsonb;
    v_question JSONB;
    v_question_id TEXT;
    v_answer_value INTEGER;
    v_threshold INTEGER;
    v_is_critical BOOLEAN;
BEGIN
    FOR v_question IN SELECT jsonb_array_elements(p_questions)
    LOOP
        v_question_id := v_question->>'id';
        v_is_critical := COALESCE((v_question->>'is_critical')::BOOLEAN, false);
        v_threshold := (v_question->>'alert_threshold')::INTEGER;

        IF v_is_critical AND v_threshold IS NOT NULL THEN
            IF p_answers ? v_question_id THEN
                v_answer_value := (p_answers->>v_question_id)::INTEGER;
                IF v_answer_value >= v_threshold THEN
                    v_flags := v_flags || jsonb_build_object(
                        'question_id', v_question_id,
                        'value', v_answer_value,
                        'threshold', v_threshold,
                        'message', 'Item crítico: resposta ' || v_answer_value || ' (threshold: ' || v_threshold || ')'
                    );
                END IF;
            END IF;
        END IF;
    END LOOP;

    RETURN v_flags;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- ═══════════════════════════════════════════════════════
-- FIM DO SCHEMA
-- ═══════════════════════════════════════════════════════
