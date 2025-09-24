# 🚀 Deploy no Portainer - Hotel Campaign Cards

Guia completo para fazer deploy da aplicação usando Portainer.

## 📋 Pré-requisitos

- Portainer instalado e configurado
- Docker Engine funcionando
- Acesso ao Supabase (URL e chave anônima)
- Arquivos do projeto disponíveis

## 🎯 Método 1: Upload de Arquivos (Recomendado)

### Passo 1: Preparar Arquivos
Faça upload destes arquivos para o servidor:
```
hotel-campaign-cards/
├── Dockerfile
├── portainer-stack.yml
├── nginx.conf
├── .dockerignore
└── [todos os arquivos do projeto]
```

### Passo 2: Criar Stack no Portainer
1. Acesse o Portainer
2. Vá em **Stacks** → **Add Stack**
3. Nome da stack: `hotel-campaign-cards`
4. Método: **Web editor**
5. Cole o conteúdo do arquivo `portainer-stack.yml`

### Passo 3: Configurar Variáveis de Ambiente
Na seção **Environment variables**, adicione:

| Nome | Valor | Descrição |
|------|-------|-----------|
| `SUPABASE_URL` | `https://seu-projeto.supabase.co` | URL do seu projeto Supabase |
| `SUPABASE_ANON_KEY` | `sua_chave_anonima_aqui` | Chave anônima do Supabase |

### Passo 4: Deploy
1. Clique em **Deploy the stack**
2. Aguarde o build da imagem (pode demorar alguns minutos)
3. Verifique se todos os containers estão rodando

## 🎯 Método 2: Repositório Git

### Passo 1: Configurar Repositório
1. Faça push de todos os arquivos para um repositório Git
2. Certifique-se que `portainer-stack.yml` está na raiz

### Passo 2: Criar Stack no Portainer
1. Acesse **Stacks** → **Add Stack**
2. Nome: `hotel-campaign-cards`
3. Método: **Git Repository**
4. Configure:
   - **Repository URL**: URL do seu repositório
   - **Reference**: `main` ou `master`
   - **Compose path**: `portainer-stack.yml`

### Passo 3: Variáveis e Deploy
- Configure as variáveis de ambiente (mesmo do Método 1)
- Clique em **Deploy the stack**

## 🌐 Acessos Após Deploy

| Serviço | URL | Descrição |
|---------|-----|-----------|
| Aplicação Principal | `http://seu-servidor:80` | Interface principal |
| Nginx Proxy | `http://seu-servidor:8080` | Proxy reverso |
| Health Check | `http://seu-servidor/health` | Status da aplicação |

## 📊 Monitoramento no Portainer

### Containers
- **hotel-campaign-cards**: Aplicação principal
- **hotel-nginx-proxy**: Proxy Nginx (opcional)

### Verificações Importantes
1. **Status**: Todos containers devem estar "running"
2. **Health Check**: Deve mostrar "healthy"
3. **Logs**: Sem erros críticos
4. **Resources**: CPU e memória dentro dos limites

## 🔧 Configurações Avançadas

### Limites de Recursos
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'      # Máximo 1 CPU
      memory: 512M     # Máximo 512MB RAM
    reservations:
      cpus: '0.5'      # Mínimo 0.5 CPU
      memory: 256M     # Mínimo 256MB RAM
```

### Labels para Traefik (se usar)
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.hotel-campaign.rule=Host(`hotel-campaign.local`)"
```

## 🔄 Atualizações

### Atualizar Aplicação
1. No Portainer, vá em **Stacks**
2. Selecione `hotel-campaign-cards`
3. Clique em **Editor**
4. Modifique se necessário
5. Clique em **Update the stack**

### Forçar Rebuild
1. Vá em **Stacks** → `hotel-campaign-cards`
2. Clique em **Stop this stack**
3. Aguarde parar completamente
4. Clique em **Start this stack**
5. Ou use **Recreate** para rebuild completo

## 💾 Backup e Restore

### Fazer Backup
```bash
# Backup dos volumes
docker run --rm \
  -v hotel-campaign-cards_app-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/hotel-campaign-backup.tar.gz /data

# Backup da configuração
docker stack config hotel-campaign-cards > stack-config-backup.yml
```

### Restaurar Backup
```bash
# Restore dos volumes
docker run --rm \
  -v hotel-campaign-cards_app-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/hotel-campaign-backup.tar.gz -C /
```

## 🐛 Troubleshooting

### Container não inicia
**Sintomas**: Container fica em estado "Exited"

**Soluções**:
1. Verifique logs no Portainer
2. Confirme variáveis de ambiente
3. Verifique se portas 80/443 estão livres
4. Teste build local: `docker build -t test .`

### Build falha
**Sintomas**: Erro durante criação da imagem

**Soluções**:
1. Verifique se `Dockerfile` está acessível
2. Confirme recursos disponíveis (CPU/RAM)
3. Limpe imagens antigas: **Images** → **Remove unused**
4. Verifique logs de build no Portainer

### Aplicação não responde
**Sintomas**: Timeout ao acessar a aplicação

**Soluções**:
1. Teste health check: `curl http://localhost/health`
2. Verifique logs do container
3. Confirme configuração do Supabase
4. Teste conectividade de rede

### Erro de permissões
**Sintomas**: Erro 403 ou problemas de acesso

**Soluções**:
1. Verifique configurações RLS no Supabase
2. Confirme chaves de API
3. Teste autenticação manualmente

## 📈 Otimizações

### Performance
- Use **restart_policy** para alta disponibilidade
- Configure **health_check** para monitoramento
- Limite recursos para evitar sobrecarga

### Segurança
- Use variáveis de ambiente para secrets
- Configure rede isolada
- Implemente HTTPS com certificados

### Monitoramento
- Configure alertas no Portainer
- Use labels para organização
- Monitore logs regularmente

## 🆘 Comandos Úteis

```bash
# Ver logs em tempo real
docker logs -f hotel-campaign-cards

# Executar comando no container
docker exec -it hotel-campaign-cards sh

# Verificar recursos
docker stats hotel-campaign-cards

# Inspecionar container
docker inspect hotel-campaign-cards

# Verificar rede
docker network ls
docker network inspect hotel-campaign-cards_hotel-network
```

## 📞 Suporte

Para problemas específicos:

1. **Logs**: Sempre verifique primeiro os logs no Portainer
2. **Health Check**: Teste `http://seu-servidor/health`
3. **Variáveis**: Confirme todas as variáveis de ambiente
4. **Rede**: Verifique conectividade entre containers
5. **Recursos**: Monitore uso de CPU e memória

---

**Deploy realizado com sucesso!** 🎉

Sua aplicação Hotel Campaign Cards está rodando no Portainer! 🏨✨