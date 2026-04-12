# 📋 Guia de Correção - Escalas Não Atualizam

## 🔍 Problema Identificado

O **paciente não consegue atualizar** o `scale_assignments` porque as **políticas RLS do Supabase** só permitem que o **psicólogo** faça UPDATE nesta tabela.

### Evidência:
```sql
-- RLS Policy atual (só permite psicólogo)
CREATE POLICY "Psicólogo edita assignments"
    ON scale_assignments FOR UPDATE
    TO authenticated
    USING (
        psychologist_id = (SELECT id FROM profiles WHERE auth.uid() = id)
    );
```

### Comportamento observado:
- ✅ Psicólogo cria escala → vai para `scale_assignments`
- ✅ Paciente responde → vai para `scale_responses`
- ❌ `scale_assignments` **NÃO É ATUALIZADO** (RLS bloqueia)

---

## ✅ Solução Implementada

Criamos uma **função SQL com SECURITY DEFINER** que:
1. **Ignora as políticas RLS** (executa com permissões do dono da tabela)
2. **Verifica** se o assignment pertence ao paciente logado
3. **Atualiza** apenas os campos necessários: `last_completed_at`, `next_due_date`, `status`

### Código Dart atualizado:
- Agora chama a função `patient_complete_assignment` via RPC
- Try-catch para não falhar se o RPC falhar
- Logs detalhados para debug

---

## 🚀 Passos para Aplicar a Correção

### PASSO 1: Executar Migration SQL no Supabase

1. Acesse o **Supabase Dashboard** → seu projeto
2. Vá para **SQL Editor** (menu lateral esquerdo)
3. Copie e cole o conteúdo do arquivo:
   ```
   tools/migration_patient_update_assignment.sql
   ```
4. Clique em **RUN** (ou Ctrl+Enter)
5. Você deve ver uma mensagem de sucesso e a função criada

#### O que este script faz:
- ✅ Cria a função `patient_complete_assignment()`
- ✅ Define como `SECURITY DEFINER` (ignora RLS)
- ✅ Concede permissão para `authenticated`
- ✅ Verifica se o assignment pertence ao paciente antes de atualizar

---

### PASSO 2: Testar no App

1. **Abra o app** e faça login como **paciente**
2. **Vá para a Home** e clique em uma escala pendente
3. **Responda** todas as perguntas e clique em **Finalizar**
4. **Observe os logs** no console:

#### Logs Esperados (SUCESSO):
```
=== ENVIANDO RESPOSTA PARA O BANCO ===
Assignment ID: xxx-xxx-xxx
Patient ID: yyy-yyy-yyy
Total Score: 5
Severity: minimal
Completed At: 2026-04-12T10:30:00.000Z

=== RESPOSTA INSERIDA COM SUCESSO ===
Response ID: zzz-zzz-zzz
Completed At: 2026-04-12T10:30:00.000Z

=== ATUALIZANDO ASSIGNMENT VIA FUNÇÃO SQL ===
  Frequency: once
  Next Due Date: null
  New Status: completed
  Chamando RPC: patient_complete_assignment
  Params: {p_assignment_id: xxx, p_completed_at: ..., p_next_due_date: null, p_status: completed}
✅ Assignment atualizado com sucesso via função SQL!

=== RESPOSTA ENVIADA: score=5, severidade=minimal ===

=== ESTADO DO ASSIGNMENT APÓS ATUALIZAÇÃO ===
Status: completed
lastCompletedAt: 2026-04-12T10:30:00.000Z
nextDueDate: null
frequency: once
```

#### Logs de ERRO (se algo falhar):
```
❌ ERRO ao atualizar assignment: <mensagem de erro>
```
Se aparecer isso, **copie o erro** e me envie para investigar.

---

### PASSO 3: Verificar no Supabase

1. Vá para **Table Editor** → `scale_assignments`
2. Encontre o assignment que o paciente respondeu
3. Verifique se os campos foram atualizados:
   - ✅ `status` = `completed` (se foi escala `once`)
   - ✅ `last_completed_at` = data/hora da resposta
   - ✅ `next_due_date` = `null` (para `once`) ou data futura (para recorrentes)

---

## 🎯 Resultado Esperado

### Para o Paciente:
- ✅ Após responder a escala, ela **SOME** da lista de pendentes na Home
- ✅ Tela de confirmação aparece normalmente
- ✅ Ao voltar para Home, escala não aparece mais

### Para o Psicólogo:
- ✅ Consegue acessar os resultados da escala sem erros
- ✅ Vê o status correto: "Respondida" ou "Concluída"
- ✅ Não aparece tela vermelha de erro

---

## 🐛 Debug de Problemas

### Se ainda não funcionar:

#### 1. Verificar se a função foi criada:
```sql
SELECT 
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_name = 'patient_complete_assignment';
```
Deve retornar uma linha com `security_type = DEFINER`

#### 2. Testar a função manualmente:
```sql
-- Substitua os valores reais do seu assignment
SELECT patient_complete_assignment(
    'SEU_ASSIGNMENT_ID_AQUI'::UUID,
    NOW(),
    NULL,
    'completed'
);
```
Se der erro, copie a mensagem e me envie.

#### 3. Verificar permissões do paciente:
```sql
-- Verificar se o paciente existe e está vinculado
SELECT 
    p.id AS patient_id,
    p.user_id,
    sa.id AS assignment_id,
    sa.status,
    sa.last_completed_at
FROM patients p
LEFT JOIN scale_assignments sa ON p.id = sa.patient_id
WHERE p.user_id = auth.uid();
```

---

## 📝 Resumo

| Ação | Status | Quem faz |
|------|--------|----------|
| Executar migration SQL | ⏳ PENDENTE | VOCÊ (no Supabase) |
| Testar no app | ⏳ PENDENTE | VOCÊ (como paciente) |
| Verificar logs | ⏳ PENDENTE | VOCÊ (console do app) |
| Verificar tabela no Supabase | ⏳ PENDENTE | VOCÊ (Table Editor) |

---

## ⚠️ IMPORTANTE

- ✅ A migration SQL é **SEGURA** - só cria uma função, não deleta nada
- ✅ A função **VERIFICA** se o assignment pertence ao paciente antes de atualizar
- ✅ O código Dart tem **TRY-CATCH** - se o RPC falhar, a resposta já foi salva
- ✅ **BACKWARDS COMPATIBLE** - se o trigger do Supabase estiver ativo, não tem problema

---

## 📞 Próximos Passos

1. Execute a migration SQL no Supabase
2. Teste respondendo uma escala como paciente
3. Copie e cole os logs do console aqui
4. Verifique no Table Editor se o assignment foi atualizado

Se ainda não funcionar, me envie:
- Os logs completos do console
- Uma screenshot do Table Editor mostrando o assignment antes e depois
- Qualquer mensagem de erro que aparecer
