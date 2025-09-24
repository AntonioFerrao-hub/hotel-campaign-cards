# 🐳 Docker - Hotel Campaign Cards

Este documento contém todas as instruções para executar o projeto usando Docker.

## 📋 Pré-requisitos

- Docker Desktop instalado
- Docker Compose (incluído no Docker Desktop)
- Git (para clonar o repositório)

## 🚀 Execução Rápida

### Produção (Recomendado)
```bash
# Build e execução
docker-compose up --build web

# Acesse: http://localhost
```

### Desenvolvimento
```bash
# Execução com hot reload
docker-compose --profile development up --build web-dev

# Acesse: http://localhost:8181
```

## 📁 Estrutura dos Arquivos Docker

```
hotel-campaign-cards/
├── Dockerfile              # Configuração principal do container
├── docker-compose.yml      # Orquestração dos serviços
├── .dockerignore           # Arquivos ignorados no build
├── nginx.conf              # Configuração do Nginx
└── README-Docker.md        # Este arquivo
```

## 🛠️ Comandos Disponíveis

### Básicos
```bash
# Build da imagem
docker-compose build

# Executar em produção
docker-compose up web

# Executar em desenvolvimento
docker-compose --profile development up web-dev

# Executar em background
docker-compose up -d web

# Parar todos os serviços
docker-compose down

# Ver logs
docker-compose logs -f web
```

### Avançados
```bash
# Com proxy Nginx
docker-compose --profile proxy up

# Com banco Supabase local
docker-compose --profile database up supabase

# Desenvolvimento completo (app + banco)
docker-compose --profile development --profile database up

# Limpar volumes
docker-compose down -v

# Rebuild forçado
docker-compose up --build --force-recreate
```

## 🌐 Portas e Acessos

| Serviço | Porta | URL | Descrição |
|---------|-------|-----|-----------|
| Produção | 80 | http://localhost | App em produção |
| Produção SSL | 443 | https://localhost | App com HTTPS |
| Desenvolvimento | 8181 | http://localhost:8181 | App com hot reload |
| Proxy Nginx | 8080 | http://localhost:8080 | Proxy reverso |
| Supabase DB | 5432 | localhost:5432 | PostgreSQL local |

## 🔧 Configurações

### Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
# Supabase
VITE_SUPABASE_URL=sua_url_do_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima

# Ambiente
NODE_ENV=production

# Opcional - Configurações customizadas
VITE_APP_TITLE=Hotel Campaign Cards
VITE_API_URL=https://api.exemplo.com
```

### Nginx Customizado

Para customizar o Nginx, edite o arquivo `nginx.conf`:

```nginx
# Exemplo: Adicionar proxy para API externa
location /external-api/ {
    proxy_pass https://api.externa.com/;
    proxy_set_header Host $host;
}
```

## 🏗️ Profiles do Docker Compose

### `development`
- Hot reload ativado
- Volume montado para desenvolvimento
- Porta 8181

### `proxy`
- Nginx como proxy reverso
- Porta 8080
- Load balancing (se múltiplas instâncias)

### `database`
- PostgreSQL local (Supabase)
- Porta 5432
- Volume persistente

## 📊 Monitoramento e Logs

### Health Check
```bash
# Verificar saúde do container
docker-compose ps

# Health check manual
curl http://localhost/health
```

### Logs Detalhados
```bash
# Logs em tempo real
docker-compose logs -f web

# Logs específicos
docker logs hotel-campaign-cards-web

# Logs do Nginx
docker-compose logs nginx
```

## 🔒 Segurança

### Headers de Segurança
O Nginx está configurado com:
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Content-Security-Policy

### HTTPS (Opcional)
Para ativar HTTPS, descomente a seção SSL no `nginx.conf` e configure os certificados.

## 🚀 Deploy em Produção

### Docker Hub
```bash
# Build e tag
docker build -t seu-usuario/hotel-campaign-cards .

# Push para Docker Hub
docker push seu-usuario/hotel-campaign-cards

# Pull e run em produção
docker pull seu-usuario/hotel-campaign-cards
docker run -p 80:80 seu-usuario/hotel-campaign-cards
```

### Docker Registry Privado
```bash
# Tag para registry privado
docker tag hotel-campaign-cards registry.empresa.com/hotel-campaign-cards

# Push
docker push registry.empresa.com/hotel-campaign-cards
```

## 🐛 Troubleshooting

### Problemas Comuns

**Porta já em uso:**
```bash
# Verificar processos na porta
netstat -tulpn | grep :80

# Usar porta diferente
docker-compose up -p 8080:80 web
```

**Build falha:**
```bash
# Limpar cache do Docker
docker system prune -a

# Build sem cache
docker-compose build --no-cache
```

**Container não inicia:**
```bash
# Verificar logs
docker-compose logs web

# Executar interativamente
docker run -it hotel-campaign-cards sh
```

### Performance

**Otimizar build:**
```bash
# Multi-stage build já implementado
# Use .dockerignore para excluir arquivos desnecessários
```

**Reduzir tamanho da imagem:**
```bash
# Verificar tamanho
docker images hotel-campaign-cards

# Analisar camadas
docker history hotel-campaign-cards
```

## 📝 Notas Importantes

1. **Desenvolvimento**: Use sempre o profile `development` para desenvolvimento local
2. **Produção**: O build de produção é otimizado e minificado
3. **Volumes**: Os dados do banco são persistidos em volumes Docker
4. **Network**: Todos os serviços estão na mesma rede `hotel-network`
5. **Health Checks**: Implementados para monitoramento automático

## 🆘 Suporte

Para problemas específicos:

1. Verifique os logs: `docker-compose logs -f`
2. Teste a conectividade: `curl http://localhost/health`
3. Verifique as variáveis de ambiente
4. Consulte a documentação do Docker

---

**Desenvolvido para Hotel Campaign Cards** 🏨✨