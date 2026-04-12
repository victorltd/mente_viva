-- ═══════════════════════════════════════════════════════
-- MIGRATION: Permitir paciente atualizar assignment após resposta
-- Problema: RLS policy só permite psicólogo fazer UPDATE
-- Solução: Função SECURITY DEFINER que ignora RLS
--
-- Execute este script no Supabase SQL Editor UMA VEZ
-- ═══════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════
-- 1. Criar função que atualiza assignment (ignora RLS)
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION patient_complete_assignment(
    p_assignment_id UUID,
    p_completed_at TIMESTAMP WITH TIME ZONE,
    p_next_due_date DATE,
    p_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER -- Executa com permissões do dono da tabela (ignora RLS)
SET search_path = public
AS $$
BEGIN
    -- Verificar se o assignment pertence ao paciente logado
    IF NOT EXISTS (
        SELECT 1 FROM scale_assignments sa
        INNER JOIN patients p ON sa.patient_id = p.id
        WHERE sa.id = p_assignment_id
        AND p.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Assignment não encontrado ou não pertence ao paciente';
    END IF;

    -- Atualizar o assignment
    UPDATE scale_assignments
    SET
        last_completed_at = p_completed_at,
        next_due_date = p_next_due_date,
        status = p_status::assignment_status,
        updated_at = NOW()
    WHERE id = p_assignment_id;
END;
$$;

-- ═══════════════════════════════════════════════════════
-- 2. Conceder permissão de execução para authenticated
-- ═══════════════════════════════════════════════════════

GRANT EXECUTE ON FUNCTION patient_complete_assignment TO authenticated;

-- ═══════════════════════════════════════════════════════
-- 3. Verificação (opcional)
-- ═══════════════════════════════════════════════════════

-- Confirmar que a função foi criada
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_name = 'patient_complete_assignment';

-- ═══════════════════════════════════════════════════════
-- FIM DA MIGRATION
-- ✅ Execute este script UMA VEZ no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════
