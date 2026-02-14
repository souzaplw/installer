#!/bin/bash
# Funções de sistema - atualização, Node, PostgreSQL, Nginx, PM2

system_update() {
  log_step "Atualizando pacotes do sistema..."
  sudo apt-get update -qq && sudo apt-get upgrade -y -qq
  log_ok "Sistema atualizado"
}

system_node_install() {
  if command -v node &>/dev/null && [[ "$(node -v | cut -d. -f1 | tr -d v)" -ge 22 ]]; then
    log_ok "Node.js $(node -v) já instalado"
    return 0
  fi
  log_step "Instalando Node.js 24 (LTS mais recente)..."
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
  log_ok "Node.js $(node -v) instalado"
}

system_postgres_install() {
  if command -v psql &>/dev/null; then
    log_ok "PostgreSQL já instalado ($(psql --version 2>/dev/null || echo 'psql'))"
    return 0
  fi
  log_step "Configurando repositório oficial PGDG e instalando PostgreSQL (versão mais recente)..."
  sudo apt-get install -y postgresql-common ca-certificates
  [[ -x /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh ]] && sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
  sudo apt-get update -qq
  sudo apt-get install -y postgresql postgresql-contrib
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  log_ok "PostgreSQL instalado"
}

system_pm2_install() {
  if command -v pm2 &>/dev/null; then
    log_ok "PM2 já instalado"
    return 0
  fi
  log_step "Instalando PM2..."
  sudo npm install -g pm2
  log_ok "PM2 instalado"
}

system_nginx_install() {
  if command -v nginx &>/dev/null; then
    log_ok "Nginx já instalado"
    return 0
  fi
  log_step "Instalando Nginx..."
  sudo apt-get install -y nginx
  sudo systemctl enable nginx
  log_ok "Nginx instalado"
}

system_certbot_install() {
  if command -v certbot &>/dev/null; then
    log_ok "Certbot já instalado"
    return 0
  fi
  log_step "Instalando Certbot..."
  sudo apt-get install -y certbot python3-certbot-nginx
  log_ok "Certbot instalado"
}

# Cria usuário deploy com home /home/deploy para rodar a aplicação
system_create_deploy_user() {
  local deploy_user="${1:-deploy}"
  if id "$deploy_user" &>/dev/null; then
    log_ok "Usuário $deploy_user já existe"
    return 0
  fi
  log_step "Criando usuário $deploy_user..."
  sudo useradd -m -s /bin/bash "$deploy_user"
  sudo mkdir -p "/home/$deploy_user/.pm2"
  sudo chown -R "$deploy_user:$deploy_user" "/home/$deploy_user"
  log_ok "Usuário $deploy_user criado"
}

# Configura PM2 startup para rodar como deploy user após reboot
system_pm2_startup() {
  local deploy_user="${1:-deploy}"
  log_step "Configurando PM2 para iniciar no boot como $deploy_user..."
  sudo -u "$deploy_user" env PATH="$PATH" pm2 startup systemd -u "$deploy_user" --hp "/home/$deploy_user" 2>/dev/null || true
  log_ok "PM2 startup configurado"
}
