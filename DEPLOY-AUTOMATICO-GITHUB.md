# 🚀 Deploy Automático com GitHub Actions

## 📋 **Configuração Completa**

### 1️⃣ **Configurar Secrets no GitHub**

Vá em: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Adicione os seguintes secrets:

```
DOCKER_USERNAME = seu_usuario_docker_hub
DOCKER_PASSWORD = sua_senha_docker_hub
VITE_SUPABASE_URL = sua_url_supabase
VITE_SUPABASE_ANON_KEY = sua_chave_publica_supabase  
VITE_SUPABASE_PROJECT_ID = seu_project_id_supabase
```

### 2️⃣ **Como Funciona**

✅ **Push para `main`** → Build automático da imagem Docker
✅ **Nova tag `v*`** → Build com versão específica  
✅ **Pull Request** → Build de teste (sem push)
✅ **Imagem enviada** → Docker Hub automaticamente

### 3️⃣ **Portainer Stack Atualizado**

O arquivo `portainer-stack-final.yml` agora usa:

```yaml
image: antonioferrao/hotel-campaign-cards:latest
```

### 4️⃣ **Fluxo Completo**

1. **Desenvolver** → Fazer alterações no código
2. **Commit & Push** → `git push origin main`
3. **GitHub Actions** → Build automático da imagem
4. **Docker Hub** → Imagem disponível como `latest`
5. **Portainer** → Usar a stack para deploy
6. **Resultado** → App rodando em `gl.oceaniaparkhotel.com.br`

### 5️⃣ **Variáveis de Ambiente no Portainer**

Configure no Portainer:

```
VITE_SUPABASE_URL = sua_url_supabase
VITE_SUPABASE_PUBLISHABLE_KEY = sua_chave_publica_supabase
VITE_SUPABASE_PROJECT_ID = seu_project_id_supabase
```

### 6️⃣ **Vantagens**

🎯 **Build automático** a cada push
🎯 **Imagem sempre atualizada** no Docker Hub
🎯 **Deploy simples** no Portainer
🎯 **Versionamento** com tags Git
🎯 **Cache otimizado** para builds rápidos
🎯 **Multi-arquitetura** (AMD64 + ARM64)

---

## 🔄 **Processo de Deploy**

### **Desenvolvimento:**
```bash
git add .
git commit -m "Nova funcionalidade"
git push origin main
```

### **GitHub Actions:**
- ✅ Detecta push
- ✅ Faz build da imagem
- ✅ Envia para Docker Hub
- ✅ Tag como `latest`

### **Portainer:**
- ✅ Usa `antonioferrao/hotel-campaign-cards:latest`
- ✅ Puxa imagem atualizada
- ✅ Deploy automático

**🎉 Resultado: App atualizado em produção!**