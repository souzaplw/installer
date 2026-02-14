#!/bin/bash
# Trocar domínio - atualiza Nginx, Certbot SSL e variáveis da aplicação
# Uso: sudo ./scripts/trocar_dominio.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

source "${PROJECT_ROOT}/variables/manifest.sh"
source "${PROJECT_ROOT}/utils/manifest.sh"
source "${PROJECT_ROOT}/lib/manifest.sh"

echo ""
echo "=============================================="
echo "  Trocar domínio - WhatsApp Group Sender"
echo "=============================================="
echo ""

if [[ ! -f "${PROJECT_ROOT}/config" ]]; then
  log_err "Nenhuma instalação encontrada. Execute primeiro a instalação primária."
  exit 1
fi

source "${PROJECT_ROOT}/config"

log_info "Domínios atuais:"
echo "  API:  ${SUBDOMAIN_BACKEND:-nenhum}"
echo "  App:  ${SUBDOMAIN_FRONTEND:-nenhum}"
echo ""

if [[ -z "$SUBDOMAIN_BACKEND" && -z "$SUBDOMAIN_FRONTEND" ]]; then
  log_warn "Instalação atual não usa domínios (rodando em localhost)."
  log_info "Digite os novos domínios para configurar Nginx + Certbot:"
fi

prompt_text NEW_SUBDOMAIN_BACKEND "Novo subdomínio API (ex: api.seudominio.com)" "$SUBDOMAIN_BACKEND"
prompt_text NEW_SUBDOMAIN_FRONTEND "Novo subdomínio App (ex: app.seudominio.com)" "$SUBDOMAIN_FRONTEND"

[[ -z "$NEW_SUBDOMAIN_BACKEND" && -z "$NEW_SUBDOMAIN_FRONTEND" ]] && {
  log_err "Informe pelo menos um domínio."
  exit 1
}

# Atualiza config
SUBDOMAIN_BACKEND="$NEW_SUBDOMAIN_BACKEND"
SUBDOMAIN_FRONTEND="$NEW_SUBDOMAIN_FRONTEND"
BACKEND_URL="https://${SUBDOMAIN_BACKEND}"
FRONTEND_URL="https://${SUBDOMAIN_FRONTEND}"
FRONTEND_API_URL="$BACKEND_URL"

# Salva config
sed -i "s|^SUBDOMAIN_BACKEND=.*|SUBDOMAIN_BACKEND=$SUBDOMAIN_BACKEND|" "${PROJECT_ROOT}/config"
sed -i "s|^SUBDOMAIN_FRONTEND=.*|SUBDOMAIN_FRONTEND=$SUBDOMAIN_FRONTEND|" "${PROJECT_ROOT}/config"
sed -i "s|^BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|" "${PROJECT_ROOT}/config"
sed -i "s|^FRONTEND_URL=.*|FRONTEND_URL=$FRONTEND_URL|" "${PROJECT_ROOT}/config"
sed -i "s|^FRONTEND_API_URL=.*|FRONTEND_API_URL=$FRONTEND_API_URL|" "${PROJECT_ROOT}/config"

# Nginx - recria configs
if [[ -n "$SUBDOMAIN_BACKEND" ]]; then
  backend_nginx_setup "$INSTANCE_NAME" "$SUBDOMAIN_BACKEND" "$PORT_BACKEND"
fi
if [[ -n "$SUBDOMAIN_FRONTEND" ]]; then
  frontend_nginx_setup "$INST_DIR" "$INSTANCE_NAME" "$SUBDOMAIN_FRONTEND" "$PORT_BACKEND"
fi

system_nginx_restart

# Certbot - novo SSL
if [[ -n "$SUBDOMAIN_BACKEND" || -n "$SUBDOMAIN_FRONTEND" ]]; then
  log_step "Gerando certificado SSL com Certbot..."
  cert_args=(--nginx --non-interactive --agree-tos --redirect -m "${ADMIN_EMAIL}")
  [[ -n "$SUBDOMAIN_BACKEND" ]] && cert_args+=(-d "$SUBDOMAIN_BACKEND")
  [[ -n "$SUBDOMAIN_FRONTEND" ]] && cert_args+=(-d "$SUBDOMAIN_FRONTEND")
  sudo certbot "${cert_args[@]}" 2>/dev/null || log_warn "Certbot: verifique se os domínios apontam para este servidor (DNS)"
fi

# Atualiza .env do backend
if [[ -d "${INST_DIR}/backend" ]]; then
  log_step "Atualizando .env do backend..."
  sed -i "s|^BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|" "${INST_DIR}/backend/.env"
  sed -i "s|^FRONTEND_URL=.*|FRONTEND_URL=$FRONTEND_URL|" "${INST_DIR}/backend/.env"
  sed -i "s|^CORS_ORIGIN=.*|CORS_ORIGIN=$FRONTEND_URL|" "${INST_DIR}/backend/.env"
fi

# Atualiza e rebuild frontend (VITE_API_BASE_URL)
if [[ -d "${INST_DIR}/frontend" ]]; then
  log_step "Atualizando e recompilando frontend..."
  api_url="${BACKEND_URL}"
  [[ "$api_url" != */api ]] && api_url="${api_url}/api"
  echo "VITE_API_BASE_URL=${api_url}" > "${INST_DIR}/frontend/config/.env.production"
  cp "${INST_DIR}/frontend/config/.env.production" "${INST_DIR}/frontend/config/.env" 2>/dev/null || true
  sudo -u "${DEPLOY_USER:-deploy}" bash -c "cd '${INST_DIR}/frontend' && npm run build"
  nginx_fix_frontend_permissions "$INST_DIR"
fi

# Reinicia PM2 frontend se estava rodando
sudo -u "${DEPLOY_USER:-deploy}" pm2 restart "${INSTANCE_NAME}-frontend" 2>/dev/null || true

echo ""
log_ok "Domínio atualizado!"
echo "  API:  $BACKEND_URL"
echo "  App:  $FRONTEND_URL"
echo ""
