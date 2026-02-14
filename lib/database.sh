#!/bin/bash
# Funções de banco de dados PostgreSQL

backend_db_create() {
  log_step "Criando banco de dados PostgreSQL..."
  local db_user="$1"
  local db_pass="$2"
  local db_name="$3"
  
  sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='$db_name'" -t -A 2>/dev/null | grep -q 1 && {
    log_warn "Banco '$db_name' já existe"
    return 0
  }
  
  sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_pass';" 2>/dev/null || true
  sudo -u postgres psql -c "CREATE DATABASE $db_name OWNER $db_user;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
  sudo -u postgres psql -c "ALTER USER $db_user CREATEDB;"
  log_ok "Banco '$db_name' criado"
}
