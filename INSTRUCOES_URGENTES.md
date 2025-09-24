# 🚨 INSTRUÇÕES URGENTES - CORRIGIR LOGIN AGORA

## ❌ PROBLEMA ATUAL
O login **NÃO ESTÁ FUNCIONANDO** porque os scripts de correção ainda **NÃO FORAM APLICADOS** no Supabase.

## ✅ SOLUÇÃO IMEDIATA

### PASSO 1: ABRIR SUPABASE DASHBOARD
1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **SQL Editor**

### PASSO 2: EXECUTAR SCRIPT DE CORREÇÃO
Copie e cole **TODO O CONTEÚDO** do arquivo:
```
APLICAR_CORRECAO_COMPLETA.sql
```

**OU** execute os scripts na ordem:
1. `VERIFICAR_STATUS_ATUAL.sql` (para ver o problema)
2. `APLICAR_CORRECAO_COMPLETA.sql` (para corrigir tudo)

### PASSO 3: TESTAR LOGIN
Após executar o script, teste na aplicação com:

**Usuários Criados:**
- **admin@hotel.com.br** / admin123
- **user@hotel.com.br** / user123  
- **suporte@wfinformatica.com.br** / suporte123

**Usuários Existentes:**
- Qualquer email da base / **123456**

## 🔍 VERIFICAÇÃO RÁPIDA

Se quiser verificar se funcionou, execute no SQL Editor:
```sql
-- Testar login do admin
SELECT * FROM public.authenticate_user('admin@hotel.com.br', 'admin123');

-- Ver todos os usuários
SELECT email, name, role, password_hash IS NOT NULL as tem_senha 
FROM public.profiles;
```

## ⚡ RESUMO DO QUE O SCRIPT FAZ

1. ✅ Cria funções de hash e autenticação
2. ✅ Cria usuários hardcoded na base de dados
3. ✅ Define senha padrão (123456) para usuários sem senha
4. ✅ Configura permissões corretas
5. ✅ Ajusta políticas de segurança

## 🎯 RESULTADO ESPERADO

Após executar o script:
- ✅ admin@hotel.com.br funcionará
- ✅ Usuários cadastrados poderão acessar
- ✅ Sistema de login estará 100% funcional

---

**⚠️ IMPORTANTE:** Execute o script **AGORA** no Supabase Dashboard para resolver o problema!