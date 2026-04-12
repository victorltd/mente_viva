# 📊 Escalas Adicionais - Guia de Instalação

## ✅ Escalas Criadas

### 1. **BDI-II** (Beck Depression Inventory-II)
- **21 itens** - Inventário de Depressão de Beck
- **Faixa de score**: 0-63
- **Categorias**: Mínimo (0-13), Leve (14-19), Moderado (20-28), Grave (29-63)
- **Subescalas**: Humor, Sintomas Cognitivos, Anedonia, Sintomas Somáticos
- **Item crítico**: Q9 (pensamentos suicidas)
- **Tempo estimado**: 10 minutos

### 2. **BAI** (Beck Anxiety Inventory)
- **21 itens** - Inventário de Ansiedade de Beck
- **Faixa de score**: 0-63
- **Categorias**: Mínimo (0-9), Leve (10-18), Moderado (19-29), Grave (30-63)
- **Subscalas**: Sintomas Somáticos, Sintomas Cognitivos, Tensão
- **Item crítico**: Q16 (medo de morrer)
- **Tempo estimado**: 10 minutos

### 3. **OQ-45** (Outcome Questionnaire-45)
- **45 itens** - Questionário de Resultados
- **Faixa de score**: 0-180
- **Categorias**: Funcional (0-63), Subclínico (64-90), Clínico (91-120), Grave (121-180)
- **Subscalas**: Sintomas (SD), Relações Interpessoais (RI), Funcionamento Social (FS)
- **Item crítico**: Q7 (pensamentos de suicídio)
- **Itens reversos**: 19 itens (marcados no JSON)
- **Tempo estimado**: 15 minutos

---

## 🚀 Como Instalar

### Opção 1: Executar no Supabase Dashboard (Recomendado)

1. Acesse **Supabase Dashboard** → seu projeto
2. Vá para **SQL Editor** (menu lateral esquerdo)
3. Abra o arquivo: `tools/seed_additional_scales.sql`
4. **Copie todo o conteúdo** e **cole** no SQL Editor
5. Clique em **RUN** ▶️ (ou Ctrl+Enter)
6. Aguarde a confirmação de sucesso
7. Verifique a tabela de resultados mostrando as 3 escalas inseridas

### Opção 2: Via CLI do Supabase (Avançado)

```bash
# Se você tem o Supabase CLI instalado
supabase db execute -f tools/seed_additional_scales.sql
```

---

## ✅ Verificação

Após executar o script, rode esta query para confirmar:

```sql
SELECT 
    id, 
    name, 
    full_name, 
    category, 
    jsonb_array_length(questions) as question_count,
    is_validated
FROM scale_templates
ORDER BY id;
```

**Resultado esperado:**

| id | name | full_name | category | question_count | is_validated |
|----|------|-----------|----------|----------------|--------------|
| phq9 | PHQ-9 | Patient Health Questionnaire-9 | depression | 9 | true |
| gad7 | GAD-7 | Generalized Anxiety Disorder-7 | anxiety | 7 | true |
| **bdiii** | **BDI-II** | **Beck Depression Inventory-II** | **depression** | **21** | **true** |
| **bai** | **BAI** | **Beck Anxiety Inventory** | **anxiety** | **21** | **true** |
| **oq45** | **OQ-45** | **Outcome Questionnaire-45** | **progress** | **45** | **true** |

---

## 🎯 Como Usar no App

### Para o Psicólogo:

1. **Login como psicólogo**
2. **Clique em um paciente**
3. **Clique em "+ Adicionar Escala"**
4. As novas escalas aparecerão na lista:
   - **BDI-II** (na seção de Depressão)
   - **BAI** (na seção de Ansiedade)
   - **OQ-45** (na seção de Progresso)
5. **Selecione** a escala desejada
6. **Configure** frequência e data
7. **Atribua** ao paciente

### Para o Paciente:

1. **Login como paciente**
2. **Ver escala pendente** na home
3. **Clique em "Responder"**
4. **Responda** todas as perguntas
5. **Envie** e veja a confirmação

---

## 📝 Detalhes Técnicos

### Estrutura do JSON de Cada Escala

Cada escala contém:
- ✅ **response_options**: Opções de resposta com valores 0-3 ou 0-4
- ✅ **questions**: Todas as perguntas traduzidas para PT-BR
- ✅ **scoring**: Configuração completa com severity_ranges
- ✅ **subscales**: Definição das subscalas com itens
- ✅ **alerts**: Regras de alerta para itens críticos

### Itens Reversos (OQ-45)

No OQ-45, **19 itens são reversos** (score invertido):
- q3, q4, q6, q8, q10, q12, q14, q18, q21, q23, q25, q27, q29, q31, q33, q35, q37, q41, q45

O código Dart já suporta itens reversos via `reverse_items` no scoring config.

### Alertas Críticos

| Escala | Item Crítico | Condição | Ação |
|--------|--------------|----------|------|
| BDI-II | Q9 (pensamentos suicidas) | ≥ 1 | Avaliar risco imediatamente |
| BAI | Q16 (medo de morrer) | ≥ 2 | Avaliar ataque de pânico |
| OQ-45 | Q7 (pensamentos de suicídio) | ≥ 2 | Protocolo de emergência |

---

## 🔍 Troubleshooting

### Se as escalas não aparecerem no app:

1. **Verifique se o INSERT foi bem-sucedido**:
   ```sql
   SELECT COUNT(*) FROM scale_templates;
   -- Deve retornar 5 (PHQ-9, GAD-7, BDI-II, BAI, OQ-45)
   ```

2. **Recarregue os templates no app**:
   - Saia e volte para a tela de selecionar escala
   - Ou faça pull-to-refresh na lista

3. **Verifique permissões RLS**:
   ```sql
   -- O usuário autenticado deve conseguir ler os templates
   SELECT id, name FROM scale_templates;
   -- Deve retornar todas as 5 escalas
   ```

### Se houver erro de duplicidade:

Se você já executou o script antes, pode haver conflito de chaves. Use:

```sql
-- Deletar escalas existentes (CUIDADO: isso remove dados!)
DELETE FROM scale_templates WHERE id IN ('bdiii', 'bai', 'oq45');

-- Depois execute o script novamente
```

---

## 📊 Resumo Final do Sistema de Escalas

### Total de Escalas Disponíveis: **5**

| # | Escala | Itens | Categoria | Status |
|---|--------|-------|-----------|--------|
| 1 | PHQ-9 | 9 | Depressão | ✅ Seed existente |
| 2 | GAD-7 | 7 | Ansiedade | ✅ Seed existente |
| 3 | **BDI-II** | **21** | **Depressão** | **✅ NOVO** |
| 4 | **BAI** | **21** | **Ansiedade** | **✅ NOVO** |
| 5 | **OQ-45** | **45** | **Progresso** | **✅ NOVO** |

### Sistema de Escalas: **100% COMPLETO** 🎉

- ✅ SQL/Database (todas as tabelas + 5 escalas seed)
- ✅ Models Dart (4 arquivos)
- ✅ Providers (4 arquivos)
- ✅ Telas do Paciente (3 telas)
- ✅ Telas do Psicólogo - Visualização (2 telas)
- ✅ Telas do Psicólogo - Criação (4 telas)
- ✅ JSONs das Escalas (5 escalas completas)

---

## 🚀 Próximos Passos (Opcional)

Agora que o sistema de escalas está 100% completo, você pode:

1. **Notificações push** para escalas pendentes
2. **Dashboard avançado** com estatísticas
3. **Exportar relatórios** em PDF
4. **Alertas automáticos** por tempo de resposta
5. **Gráficos comparativos** entre diferentes escalas

---

**Sistema de Escalas: ✅ 100% IMPLEMENTADO!** 🎉
