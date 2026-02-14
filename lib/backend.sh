#!/bin/bash
# Funções do backend

backend_set_env() {
  local inst_dir="$1"
  local backend_env="${inst_dir}/backend/.env"
  local db_pass_encoded
  db_pass_encoded=$(printf '%s' "$DB_PASS" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))" 2>/dev/null) || db_pass_encoded="$DB_PASS"
  
  log_step "Configurando .env do backend..."
  
  cat > "$backend_env" << ENVEOF
NODE_ENV=production
PORT=${PORT_BACKEND}
BACKEND_URL=${BACKEND_URL}
FRONTEND_URL=${FRONTEND_URL}
CORS_ORIGIN=${FRONTEND_URL}

# Banco de dados
DB_DIALECT=postgres
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
DATABASE_URL=postgresql://${DB_USER}:PLACEHOLDER_PASS@${DB_HOST}:${DB_PORT}/${DB_NAME}?schema=public

# JWT (gerado automaticamente)
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Admin seed
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ADMIN_NAME=${ADMIN_NAME}

# Redis (opcional)
REDIS_URI=
USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true
ENVEOF
  sed -i "s|PLACEHOLDER_PASS|${db_pass_encoded}|g" "$backend_env"
  chmod 600 "$backend_env"
  log_ok ".env do backend criado"
}

backend_node_dependencies() {
  local inst_dir="$1"
  log_step "Instalando dependências do backend..."
  (cd "${inst_dir}/backend" && npm ci 2>/dev/null || npm install --production=false)
  log_ok "Dependências instaladas"
}

backend_node_build() {
  local inst_dir="$1"
  log_step "Compilando backend..."
  (cd "${inst_dir}/backend" && npx prisma generate && npm run build)
  log_ok "Backend compilado"
}

backend_db_migrate() {
  local inst_dir="$1"
  log_step "Executando migrations..."
  (cd "${inst_dir}/backend" && npx prisma migrate deploy)
  log_ok "Migrations aplicadas"
}

backend_db_seed() {
  local inst_dir="$1"
  log_step "Criando admin inicial..."
  (cd "${inst_dir}/backend" && node dist/scripts/seedAdmin.js 2>/dev/null || (npm run build 2>/dev/null; node dist/scripts/seedAdmin.js))
  log_ok "Admin criado"
}

backend_start_pm2() {
  local inst_dir="$1"
  local inst_name="$2"
  log_step "Iniciando backend no PM2..."
  (cd "${inst_dir}/backend" && pm2 delete "${inst_name}-backend" 2>/dev/null; true)
  (cd "${inst_dir}/backend" && pm2 start dist/index.js --name "${inst_name}-backend" && pm2 save)
  log_ok "Backend rodando"
}
