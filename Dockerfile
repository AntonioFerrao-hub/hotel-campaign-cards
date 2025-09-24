# ========================================
# DOCKERFILE - Hotel Campaign Cards
# Sistema de Gerenciamento de Campanhas
# Otimizado para Portainer
# ========================================

# Imagem base para build
FROM node:18-alpine AS base

# Labels para identificação no Portainer
LABEL maintainer="Hotel Campaign Cards Team"
LABEL description="Sistema de Gerenciamento de Campanhas para Hotéis"
LABEL version="1.0.0"
LABEL org.opencontainers.image.title="Hotel Campaign Cards"
LABEL org.opencontainers.image.description="React/Vite application for hotel campaign management"
LABEL org.opencontainers.image.vendor="Hotel Campaign Cards"

# Estágio 1: Build da aplicação
FROM node:18-alpine AS builder

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY bun.lockb ./

# Instalar dependências
RUN npm ci --only=production

# Copiar código fonte
COPY . .

# Build da aplicação para produção
RUN npm run build

# ========================================
# Estágio 2: Servidor de produção
FROM nginx:alpine AS production

# Instalar curl para health checks
RUN apk add --no-cache curl

# Copiar arquivos buildados do estágio anterior
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Criar arquivo de configuração do nginx se não existir
RUN if [ ! -f /etc/nginx/nginx.conf ]; then \
    echo 'events { worker_connections 1024; }' > /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '  include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '  default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '  server {' >> /etc/nginx/nginx.conf && \
    echo '    listen 80;' >> /etc/nginx/nginx.conf && \
    echo '    server_name localhost;' >> /etc/nginx/nginx.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf && \
    echo '    index index.html index.htm;' >> /etc/nginx/nginx.conf && \
    echo '    location / {' >> /etc/nginx/nginx.conf && \
    echo '      try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf && \
    echo '    }' >> /etc/nginx/nginx.conf && \
    echo '    location /api/ {' >> /etc/nginx/nginx.conf && \
    echo '      proxy_pass http://supabase:8000/;' >> /etc/nginx/nginx.conf && \
    echo '      proxy_set_header Host $host;' >> /etc/nginx/nginx.conf && \
    echo '      proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/nginx.conf && \
    echo '    }' >> /etc/nginx/nginx.conf && \
    echo '  }' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf; \
    fi

# Expor porta 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Comando para iniciar o nginx
CMD ["nginx", "-g", "daemon off;"]

# ========================================
# ESTÁGIO ALTERNATIVO: Desenvolvimento
FROM node:18-alpine AS development

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY bun.lockb ./

# Instalar todas as dependências (incluindo dev)
RUN npm install

# Copiar código fonte
COPY . .

# Expor porta de desenvolvimento
EXPOSE 8181

# Comando para desenvolvimento
CMD ["npm", "run", "dev"]

# ========================================
# INSTRUÇÕES DE USO:
# 
# Para BUILD de produção:
# docker build --target production -t hotel-campaign-cards:prod .
# docker run -p 80:80 hotel-campaign-cards:prod
#
# Para desenvolvimento:
# docker build --target development -t hotel-campaign-cards:dev .
# docker run -p 8181:8181 -v $(pwd):/app hotel-campaign-cards:dev
#
# Para usar com docker-compose:
# Crie um arquivo docker-compose.yml na raiz do projeto
# ========================================