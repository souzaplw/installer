#!/bin/bash
# Funções de sistema - atualização, Node, PostgreSQL, Nginx, PM2

system_update() {
  log_step "Atualizando pacotes do sistema..."
  sudo apt-get update -qq && sudo apt-get upgrade -y -qq
  log_ok "Sistema atualizado"
}

system_node_install() {
  if command -v node &>/dev/null && [[ "$(node -v | cut -d. -f1 | tr -d v)" -ge 20 ]]; then
    log_ok "Node.js $(node -v) já instalado"
    return 0
  fi
  log_step "Instalando Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  log_ok "Node.js $(node -v) instalado"
}

system_postgres_install() {
  if command -v psql &>/dev/null; then
    log_ok "PostgreSQL já instalado"
    return 0
  fi
  log_step "Instalando PostgreSQL..."
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
