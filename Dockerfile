# Build (usa devDependencies para rodar vite)
FROM node:18-alpine AS builder
WORKDIR /app

ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ENV VITE_SUPABASE_URL=${VITE_SUPABASE_URL}
ENV VITE_SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY}

COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build   # precisa de "build": "vite build" no package.json

# Server Nginx (SPA)
FROM nginx:alpine AS production
RUN apk add --no-cache curl
COPY --from=builder /app/dist /usr/share/nginx/html

# Nginx para SPA: sem proxy /api (Supabase é SaaS)
RUN printf 'events { worker_connections 1024; }\n\
http {\n\
  include /etc/nginx/mime.types;\n\
  default_type application/octet-stream;\n\
  sendfile on;\n\
  server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / { try_files $uri $uri/ /index.html; }\n\
  }\n\
}\n' > /etc/nginx/nginx.conf

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]