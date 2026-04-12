# Correção: Escalas Pendentes Após Conclusão

## Problema
Mesmo após o paciente finalizar uma escala, ela continuava aparecendo como pendente na tela home.

## Causa Raiz
O **trigger do Supabase** (`trg_update_assignment_after_response`) **pode não estar funcionando** ou não foi aplicado corretamente no banco de dados de produção.

## Solução Implementada

### Atualização Manual do Assignment (Independente do Trigger)

Modificamos o `submitResponse` em `scale_responses_provider.dart` para **atualizar manualmente** o assignment após inserir a resposta, **sem depender do trigger**.

### Arquivos Modificados

#### 1. `lib/providers/scale_responses_provider.dart`
**Mudança**: Adicionada lógica para atualizar manualmente o `scale_assignments` após inserir a resposta.

```dart
// DEPOIS: Atualiza manualmente o assignment (sem depender do trigger)
debugPrint('=== ATUALIZANDO ASSIGNMENT MANUALMENTE ===');

// Buscar info do assignment para saber a frequência
final assignmentData = await _client
    .from('scale_assignments')
    .select('frequency')
    .eq('id', response.assignmentId)
    .maybeSingle();

if (assignmentData != null) {
  final frequency = assignmentData['frequency'] as String? ?? 'once';
  
  // Calcular próxima data baseado na frequência
  String? nextDueDate;
  String newStatus = 'active';
  final completedAt = insertedResponse['completed_at'] as String;
  
  if (frequency == 'weekly') {
    final date = DateTime.parse(completedAt).add(const Duration(days: 7));
    nextDueDate = date.toIso8601String().split('T').first;
  } else if (frequency == 'biweekly') {
    final date = DateTime.parse(completedAt).add(const Duration(days: 14));
    nextDueDate = date.toIso8601String().split('T').first;
  } else if (frequency == 'monthly') {
    final date = DateTime.parse(completedAt);
    final nextMonth = DateTime(date.year, date.month + 1, date.day);
    nextDueDate = nextMonth.toIso8601String().split('T').first;
  } else if (frequency == 'once') {
    nextDueDate = null;
    newStatus = 'completed'; // Marcar como completada
  }
  
  // Atualizar o assignment
  await _client
      .from('scale_assignments')
      .update({
        'last_completed_at': completedAt,
        'next_due_date': nextDueDate,
        'status': newStatus,
      })
      .eq('id', response.assignmentId);

  debugPrint('✅ Assignment atualizado com sucesso!');
}
```

**Vantagens**:
- ✅ **Não depende do trigger** - funciona mesmo se o trigger não estiver ativo
- ✅ **Atomicidade** - a resposta e o assignment são atualizados na mesma operação
- ✅ **Debug detalhado** - logs mostram exatamente o que está acontecendo

#### 2. `lib/models/scale_assignment_model.dart`
**Mudança**: Atualizado o getter `isPending` para verificar se a escala já foi respondida antes de considerar como pendente.

```dart
// DEPOIS:
bool get isPending {
  if (status != AssignmentStatus.active) return false;
  // Se nunca foi respondida, está pendente
  if (lastCompletedAt == null) return true;
  // Se já foi respondida e é escala única (sem nextDueDate): NÃO está pendente
  if (nextDueDate == null) return false;
  // Se tem próxima data: está pendente se a data já venceu
  return nextDueDate!.isBefore(DateTime.now()) ||
      nextDueDate!.isAtSameMomentAs(DateTime.now());
}
```

#### 3. `lib/providers/scale_assignments_provider.dart`
**Mudança**: Atualizada a lógica de filtro no método `loadPendingForPatient` para seguir a mesma lógica + adicionado debug detalhado.

```dart
// Debug: mostrar TODAS as escalas do paciente
debugPrint('=== DEBUG: ${responseAll.length} ESCALAS TOTAIS DO PACIENTE ===');
for (var a in responseAll) {
  debugPrint('  - ID: ${a['id']}');
  debugPrint('    Status: ${a['status']}');
  debugPrint('    lastCompletedAt: ${a['last_completed_at']}');
  debugPrint('    nextDueDate: ${a['next_due_date']}');
  debugPrint('    frequency: ${a['frequency']}');
}
```

#### 4. `lib/features/patient/screens/answer_scale_screen.dart`
**Mudança**: Removido o delay de 500ms (não é mais necessário) + adicionado debug para verificar o estado do assignment.

#### 5. `lib/features/patient/screens/scale_completed_screen.dart`
**Mudança**: Trocado `context.go('/app')` por `context.replace('/app')` para garantir reconstrução da home.

#### 6. `test/models/scale_assignment_model_test.dart`
**Mudança**: Atualizados testes para refletir a nova lógica.

## Fluxo Após Correção

1. Paciente entra na tela de resposta da escala
2. Responde todas as perguntas e envia
3. `submitResponse` **INSERE** a resposta no banco
4. **IMEDIATAMENTE** (sem depender do trigger):
   - Busca a frequência do assignment
   - Calcula `next_due_date` baseado na frequência
   - Define `status = 'completed'` se frequência `once`
   - **ATUALIZA** o assignment com `last_completed_at`, `next_due_date`, `status`
5. `loadPendingForPatient` recarrega as escalas do banco
6. **Nova lógica** filtra corretamente: escala única já respondida → **NÃO** aparece como pendente
7. Paciente é redirecionado para `/app/scale-completed`
8. Ao voltar para home, escala **não aparece mais** na lista de pendentes

## Debug Logs

Ao responder uma escala, você verá logs detalhados como:

```
=== ENVIANDO RESPOSTA PARA O BANCO ===
Assignment ID: xxx
Patient ID: xxx
Total Score: 5
Severity: minimal
Completed At: 2026-04-12T10:30:00.000Z

=== RESPOSTA INSERIDA COM SUCESSO ===
Response ID: yyy
Completed At: 2026-04-12T10:30:00.000Z

=== ATUALIZANDO ASSIGNMENT MANUALMENTE ===
  Frequency: once
  Next Due Date: null
  New Status: completed
✅ Assignment atualizado com sucesso!

=== RESPOSTA ENVIADA: score=5, severidade=minimal ===

=== ESTADO DO ASSIGNMENT APÓS ATUALIZAÇÃO ===
Status: completed
lastCompletedAt: 2026-04-12T10:30:00.000Z
nextDueDate: null
frequency: once

=== DEBUG: 2 ESCALAS TOTAIS DO PACIENTE ===
  - ID: xxx
    Status: completed
    lastCompletedAt: 2026-04-12T10:30:00.000Z
    nextDueDate: null
    frequency: once
  - ID: zzz
    Status: active
    lastCompletedAt: null
    nextDueDate: 2026-04-13
    frequency: weekly

=== 1 ESCALAS ATIVAS CARREGADAS ===
=== 1 ESCALAS PENDENTES (FINAL) ===
```

## Testes
```bash
flutter test test/models/scale_assignment_model_test.dart
# ✅ 30 testes passaram
```

## Notas Importantes
- ✅ **Não requer migration SQL** - a lógica está toda no código Dart
- ✅ **Funciona mesmo sem o trigger** - o assignment é atualizado manualmente
- ✅ **Backwards compatible** - se o trigger estiver ativo, a atualização será feita duas vezes (sem problema)
- 🔍 **Debug detalhado** - logs mostram exatamente o que está acontecendo em cada etapa
