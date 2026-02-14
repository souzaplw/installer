#!/bin/bash
# Clonagem e preparação do repositório

system_git_clone() {
  local inst_dir="$1"
  local repo_url="$2"
  local branch="${3:-main}"
  
  log_step "Clonando repositório..."
  if [[ -d "$inst_dir" && -d "${inst_dir}/.git" ]]; then
    (cd "$inst_dir" && git fetch && git checkout "$branch" && git pull)
    log_ok "Repositório atualizado"
  else
    sudo mkdir -p "$(dirname "$inst_dir")"
    sudo chown "$USER:$USER" "$(dirname "$inst_dir")"
    git clone -b "$branch" "$repo_url" "$inst_dir"
    log_ok "Repositório clonado"
  fi
}
