-- ═══════════════════════════════════════════════════════
-- DEBUG: Verificar estado do trigger e dados
-- Execute este script no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════

-- 1. Verificar se o trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trg_update_assignment_after_response';

-- 2. Verificar a função do trigger
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'update_assignment_after_response';

-- 3. Ver assignments de um paciente específico (substitua o ID)
-- Substitua 'SEU_PATIENT_ID_AQUI' pelo ID real do paciente
SELECT 
    id,
    patient_id,
    frequency,
    status,
    start_date,
    next_due_date,
    last_completed_at,
    created_at,
    updated_at
FROM scale_assignments
WHERE patient_id = 'SEU_PATIENT_ID_AQUI'
ORDER BY created_at DESC;

-- 4. Ver respostas de um assignment específico (substitua o ID)
-- Substitua 'SEU_ASSIGNMENT_ID_AQUI' pelo ID real do assignment
SELECT 
    id,
    assignment_id,
    patient_id,
    total_score,
    severity_level,
    completed_at,
    duration_seconds
FROM scale_responses
WHERE assignment_id = 'SEU_ASSIGNMENT_ID_AQUI'
ORDER BY completed_at DESC;

-- 5. Testar o trigger manualmente (opcional)
-- Isso simula uma inserção para ver se o trigger funciona
-- CUIDADO: isso criará uma resposta de teste!
/*
INSERT INTO scale_responses (
    assignment_id,
    patient_id,
    answers,
    total_score,
    severity_level,
    subscale_scores,
    critical_flags,
    completed_at
) VALUES (
    'SEU_ASSIGNMENT_ID_AQUI',
    'SEU_PATIENT_ID_AQUI',
    '{"test": 0}',
    0,
    'minimal',
    '{}',
    '[]',
    NOW()
);

-- Verificar se o assignment foi atualizado
SELECT 
    id,
    status,
    last_completed_at,
    next_due_date
FROM scale_assignments
WHERE id = 'SEU_ASSIGNMENT_ID_AQUI';
*/
