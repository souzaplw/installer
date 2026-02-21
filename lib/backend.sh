#!/bin/bash
# Funções do backend

backend_set_env() {
  local inst_dir="$1"
  local backend_env="${inst_dir}/backend/.env"
  local db_pass_encoded
  db_pass_encoded=$(printf '%s' "$DB_PASS" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))" 2>/dev/null) || db_pass_encoded="$DB_PASS"
  
  log_step "Configurando .env do backend..."
  
  # Redis: REDIS_URI ou IO_REDIS_* (senha vazia = backend usa DB_PASS)
  local redis_block="REDIS_URI=
USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true"
  if [[ -n "${IO_REDIS_SERVER:-}" ]]; then
    redis_block="# Redis (IO_REDIS_* ou REDIS_URI). Senha vazia = usa DB_PASS
REDIS_URI=
IO_REDIS_SERVER=${IO_REDIS_SERVER:-127.0.0.1}
IO_REDIS_PORT=${IO_REDIS_PORT:-6379}
IO_REDIS_PASSWORD=${IO_REDIS_PASSWORD:-}
IO_REDIS_DB_SESSION=${IO_REDIS_DB_SESSION:-2}
USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true"
  fi

  # Chrome/Puppeteer (WhatsApp)
  local chrome_bin="${CHROME_BIN:-}"
  local chrome_ws="${CHROME_WS:-}"
  
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

$redis_block

# Chrome/Puppeteer (WhatsApp). protocolTimeout evita timeout no sync de grupos
CHROME_BIN=$chrome_bin
CHROME_WS=$chrome_ws
CHROME_ARGS=--no-sandbox --disable-setuid-sandbox
CHROME_PROTOCOL_TIMEOUT=180000

# Segurança (rate limits, blocklist)
RATE_LIMIT_GENERAL=100
RATE_LIMIT_AUTH=10
RATE_LIMIT_REGISTER=5
RATE_LIMIT_SENSITIVE=30
SECURITY_BLOCKLIST=false
BLOCKLIST_IPS=
ENVEOF
  sed -i "s|PLACEHOLDER_PASS|${db_pass_encoded}|g" "$backend_env"
  chmod 600 "$backend_env"
  log_ok ".env do backend criado"
}

backend_node_dependencies() {
  local inst_dir="$1"
  local deploy_user="${DEPLOY_USER:-deploy}"
  log_step "Instalando dependências do backend..."
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && npm ci 2>/dev/null || npm install --production=false"
  log_ok "Dependências instaladas"
}

backend_node_build() {
  local inst_dir="$1"
  local deploy_user="${DEPLOY_USER:-deploy}"
  log_step "Compilando backend..."
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && npx prisma generate && npm run build"
  log_ok "Backend compilado"
}

backend_db_migrate() {
  local inst_dir="$1"
  local deploy_user="${DEPLOY_USER:-deploy}"
  log_step "Executando migrations..."
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && npx prisma migrate deploy"
  log_ok "Migrations aplicadas"
}

backend_db_seed() {
  local inst_dir="$1"
  local deploy_user="${DEPLOY_USER:-deploy}"
  log_step "Criando admin inicial..."
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && (node dist/scripts/seedAdmin.js 2>/dev/null || (npm run build 2>/dev/null; node dist/scripts/seedAdmin.js))"
  log_ok "Admin criado"
}

backend_start_pm2() {
  local inst_dir="$1"
  local inst_name="$2"
  local deploy_user="${DEPLOY_USER:-deploy}"
  log_step "Iniciando backend no PM2 (como $deploy_user)..."
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && pm2 delete '${inst_name}-backend' 2>/dev/null; true"
  sudo -u "$deploy_user" bash -c "cd '${inst_dir}/backend' && pm2 start dist/index.js --name '${inst_name}-backend' && pm2 save"
  log_ok "Backend rodando"
}
