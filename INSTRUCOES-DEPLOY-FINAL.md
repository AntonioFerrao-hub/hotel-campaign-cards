# 🚀 INSTRUÇÕES FINAIS DE DEPLOY - Hotel Campaign Cards

## ✅ **CHECKLIST RÁPIDO**

### **1. Portainer (Stack)**
1. **Cole o arquivo**: `portainer-stack-final.yml`
2. **Preencha as Environment Variables**:
   ```
   SUPABASE_URL=https://mpdblvvznqpajascuxxb.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZGJsdnZ6bnFwYWphc2N1eHhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MjYyOTEsImV4cCI6MjA1NzMwMjI5MX0.8bFGtwYMWwkaHNtZD2-zNYoN-Tvp_cVdiaCjpmkPzJ0
   ```
3. **Deploy** ✅
   - ⚠️ **Importante**: Qualquer mudança nessas chaves → precisa rebuildar o serviço

### **2. Supabase (Dashboard)**

#### **Auth → URL Settings**
- **Site URL**: `https://gl.oceaniaparkhotel.com.br`
- **Redirect URLs**: Adicione o mesmo domínio (se usar login mágico/OAuth)

#### **Storage → CORS** 
- Adicione: `https://gl.oceaniaparkhotel.com.br` (se usar Storage do frontend)

#### **Policies (RLS)**
- Garanta que as tabelas acessadas pelo `anon key` tenham regras que permitam:
  - `SELECT`/`INSERT`/`UPDATE` necessários
  - Sem expor dados sensíveis

### **3. Segurança** 🔒
- ✅ **NUNCA** colocar `service_role` (chave secreta) no frontend
- ✅ Use `anon key` no browser
- ✅ Chaves privadas só em backend (não é o caso aqui)

## 🔧 **PROBLEMAS COMUNS**

### **CORS/401/403**
- Verifique **Allowed Origins** (Storage)
- Verifique **RLS** nas tabelas

### **Build Falha**
- Confirme que há `"build": "vite build"` no `package.json`
- Confirme que o repo compila localmente

### **Traefik**
- O container do Traefik deve estar na rede `ideiasia`
- Certresolver deve estar correto

## 📋 **ARQUIVOS ATUALIZADOS**

### **Dockerfile** ✅
- ✅ Build args para variáveis do Supabase
- ✅ Nginx inline otimizado
- ✅ Health check simplificado
- ✅ SPA routing configurado

### **Stack Final** ✅
- ✅ Build args passados corretamente
- ✅ Labels Traefik configurados
- ✅ Health check robusto
- ✅ Rede `ideiasia` externa

## 🎯 **RESULTADO ESPERADO**

Após o deploy:
- **URL**: `https://gl.oceaniaparkhotel.com.br`
- **SSL**: Certificado automático via Let's Encrypt
- **Redirecionamento**: HTTP → HTTPS automático
- **Health Check**: Monitoramento ativo

## 🚀 **PRÓXIMOS PASSOS**

1. **Criar repositório no GitHub** (se ainda não existe)
2. **Push do código atualizado**
3. **Deploy no Portainer** com o stack final
4. **Configurar Supabase** conforme checklist
5. **Testar aplicação** em produção

---

**✨ Configuração otimizada para Traefik + Portainer + Supabase!**