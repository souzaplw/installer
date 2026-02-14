#!/bin/bash
# Atualizar - puxa alterações do GitHub e recompila
# Uso: sudo ./scripts/atualizar.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

source "${PROJECT_ROOT}/variables/manifest.sh"
source "${PROJECT_ROOT}/utils/manifest.sh"
source "${PROJECT_ROOT}/lib/manifest.sh"

echo ""
echo "=============================================="
echo "  Atualizar - Puxar alterações do GitHub"
echo "=============================================="
echo ""

if [[ ! -f "${PROJECT_ROOT}/config" ]]; then
  log_err "Nenhuma instalação encontrada. Execute primeiro a instalação primária."
  exit 1
fi

source "${PROJECT_ROOT}/config"

if [[ ! -d "$INST_DIR" ]]; then
  log_err "Diretório da instância não encontrado: $INST_DIR"
  exit 1
fi

log_info "Instância: $INSTANCE_NAME"
log_info "Diretório: $INST_DIR"
log_info "Repositório: $REPO_URL (branch: $REPO_BRANCH)"
echo ""

read -p "Atualizar esta instância? (S/n): " r
r="${r:-s}"
[[ "$r" != "s" && "$r" != "S" ]] && { echo "Cancelado."; exit 0; }

# Git pull
log_step "Puxando alterações do GitHub..."
sudo -u "${DEPLOY_USER:-deploy}" bash -c "cd '$INST_DIR' && git fetch origin && git checkout '$REPO_BRANCH' && git pull origin '$REPO_BRANCH'"
log_ok "Código atualizado"

# Backend
log_step "Atualizando backend (deps, prisma, build, migrate)..."
backend_node_dependencies "$INST_DIR"
backend_node_build "$INST_DIR"
backend_db_migrate "$INST_DIR"
log_ok "Backend atualizado"

# Frontend
log_step "Atualizando frontend (deps, build)..."
frontend_node_dependencies "$INST_DIR"
frontend_node_build "$INST_DIR"
log_ok "Frontend atualizado"

# Permissões Nginx (se usar)
if [[ -n "$SUBDOMAIN_FRONTEND" ]] && [[ -d "${INST_DIR}/frontend/dist" ]]; then
  nginx_fix_frontend_permissions "$INST_DIR"
fi

# Reiniciar PM2
log_step "Reiniciando processos PM2..."
sudo -u "${DEPLOY_USER:-deploy}" pm2 restart "${INSTANCE_NAME}-backend" 2>/dev/null || true
sudo -u "${DEPLOY_USER:-deploy}" pm2 restart "${INSTANCE_NAME}-frontend" 2>/dev/null || true
sudo -u "${DEPLOY_USER:-deploy}" pm2 save 2>/dev/null || true
log_ok "PM2 reiniciado"

echo ""
log_ok "Atualização concluída!"
echo "  Instância: $INSTANCE_NAME"
echo "  Backend:   ${BACKEND_URL}"
echo "  Frontend:  ${FRONTEND_URL}"
echo ""
