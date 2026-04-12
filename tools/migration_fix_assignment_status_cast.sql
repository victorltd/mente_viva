-- ═══════════════════════════════════════════════════════
-- MIGRATION: Fix assignment_status enum cast error
-- Problema: PostgrestException(message: column "status" is of type 
-- assignment_status but expression is of type text, code: 42804)
-- 
-- Execute este script no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════
-- 1. Recriar a função com o cast correto do enum
-- ═══════════════════════════════════════════════════════

-- Dropa a função antiga (se existir)
DROP FUNCTION IF EXISTS update_assignment_after_response() CASCADE;

-- Recria com o cast correto
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
                THEN 'completed'::assignment_status  -- CAST EXPLÍCITO para o enum
            ELSE 'active'::assignment_status         -- CAST EXPLÍCITO para o enum
        END
    WHERE id = NEW.assignment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════
-- 2. Recriar o trigger (dropa e recria)
-- ═══════════════════════════════════════════════════════

-- Dropa o trigger antigo (se existir)
DROP TRIGGER IF EXISTS trg_update_assignment_after_response ON scale_responses;

-- Recria o trigger apontando para a função corrigida
CREATE TRIGGER trg_update_assignment_after_response
    AFTER INSERT ON scale_responses
    FOR EACH ROW EXECUTE FUNCTION update_assignment_after_response();

-- ═══════════════════════════════════════════════════════
-- 3. Verificação (opcional)
-- ═══════════════════════════════════════════════════════

-- Confirma que o trigger foi criado
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trg_update_assignment_after_response';

-- ═══════════════════════════════════════════════════════
-- FIM DA MIGRATION
-- ✅ Execute este script uma vez no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════
