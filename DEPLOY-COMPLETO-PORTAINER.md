# 🚀 **DEPLOY COMPLETO - PORTAINER**

## ✅ **PROJETO PRONTO PARA DEPLOY**

### **📋 Dados do Projeto:**
- **Repositório GitHub**: `https://github.com/AntonioFerrao-hub/hotel-campaign-cards.git`
- **Branch**: `main`
- **Projeto Supabase**: `mpdblvvznqpajascuxxb`

---

## 🎯 **PASSO A PASSO - PORTAINER**

### **1. Criar Stack no Portainer**
1. **Acesse Portainer** → **Stacks** → **Add Stack**
2. **Nome**: `hotel-campaign-cards`
3. **Build method**: `Repository`
4. **Repository URL**: `https://github.com/AntonioFerrao-hub/hotel-campaign-cards`
5. **Reference**: `refs/heads/main`
6. **Compose path**: `portainer-stack-final.yml`

### **2. Environment Variables (OBRIGATÓRIO)**
Na seção **Environment variables**, cole exatamente:

```
SUPABASE_URL=https://mpdblvvznqpajascuxxb.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZGJsdnZ6bnFwYWphc2N1eHhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MjYyOTEsImV4cCI6MjA1NzMwMjI5MX0.8bFGtwYMWwkaHNtZD2-zNYoN-Tvp_cVdiaCjpmkPzJ0
```

### **3. Deploy** ✅
- Clique em **Deploy the stack**
- Aguarde o build (pode levar 2-3 minutos)

---

## 🔧 **CONFIGURAÇÃO SUPABASE**

### **1. Auth Settings**
No Supabase Dashboard → **Authentication** → **URL Configuration**:

```
Site URL: https://hotel-campaign-cards.SEU_DOMINIO.com
Redirect URLs: https://hotel-campaign-cards.SEU_DOMINIO.com/auth/callback
```

### **2. Storage CORS**
No Supabase Dashboard → **Storage** → **Settings** → **CORS**:

```json
[
  {
    "allowedOrigins": ["https://hotel-campaign-cards.SEU_DOMINIO.com"],
    "allowedMethods": ["GET", "POST", "PUT", "DELETE"],
    "allowedHeaders": ["*"]
  }
]
```

### **3. RLS Policies** ✅
Já configuradas automaticamente pelas migrations.

---

## 🌐 **RESULTADO ESPERADO**

### **URL Final**: 
`https://hotel-campaign-cards.SEU_DOMINIO.com`

### **Funcionalidades**:
- ✅ SSL automático (Traefik)
- ✅ Redirecionamento HTTP → HTTPS
- ✅ Health check ativo
- ✅ Sistema de usuários completo
- ✅ Upload de imagens
- ✅ Dashboard administrativo

---

## 🔍 **TROUBLESHOOTING**

### **Erro 401/403**:
- Verificar variáveis SUPABASE no Portainer
- Confirmar Auth URLs no Supabase

### **Build falha**:
- Verificar se o repositório está público
- Confirmar branch `main`

### **Traefik não funciona**:
- Verificar se a rede `traefik` existe
- Confirmar labels no stack

---

## 📞 **SUPORTE**

### **Logs do Container**:
```bash
docker logs hotel-campaign-cards_gl-app_1
```

### **Rebuild Stack**:
1. Portainer → Stacks → `hotel-campaign-cards`
2. **Editor** → **Update the stack**
3. Marcar **Re-pull image and redeploy**

---

## 🎉 **DEPLOY FINALIZADO!**

**Seu projeto está 100% pronto para produção!** 🚀

- **Código**: ✅ No GitHub
- **Docker**: ✅ Otimizado
- **Portainer**: ✅ Configurado
- **Supabase**: ✅ Integrado
- **SSL**: ✅ Automático
- **Monitoramento**: ✅ Health checks

**Próximo passo**: Fazer o deploy no Portainer! 🎯