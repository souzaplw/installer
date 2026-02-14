# Instalador - WhatsApp Group Sender SaaS

Instalador estilo [Whaticket SaaS](https://github.com/plwdesign/instaladorwhatsapsaas-main-new) para deploy em servidor Linux (Ubuntu/Debian).

## Pré-requisitos

- Ubuntu 20.04+ ou Debian 11+
- Acesso root (sudo)
- Domínio apontando para o IP do servidor (para SSL)
- Repositório Git do projeto

## Primeira instalação

```bash
# Atualizar sistema
sudo apt update
sudo apt upgrade -y

# Clonar e executar
sudo apt install -y git
git clone https://github.com/SEU_USUARIO/automacao.git
cd automacao/installer
chmod +x install_primaria install_instancia
sudo ./install_primaria
```

### Perguntas durante a instalação

| Campo | Exemplo | Descrição |
|-------|---------|-----------|
| Nome da instância | post01, cliente1 | Identificador único da instalação |
| URL do repositório | https://github.com/... | Git do projeto |
| Senha do banco | *** | Senha PostgreSQL para o banco |
| Usuário PostgreSQL | postgres | Usuário do banco |
| Porta do backend | 4250 | Porta da API |
| Porta do frontend | 3000 | Porta se usar PM2 para servir |
| Subdomínio backend | api.seudominio.com | Para produção com Nginx |
| Subdomínio frontend | app.seudominio.com | Para produção com Nginx |
| E-mail admin | admin@admin.com | Login do SuperAdmin |
| Senha admin | *** | Senha do SuperAdmin |

### Subdomínios

Antes de rodar o instalador, configure os DNS:
- `api.seudominio.com` → IP do servidor
- `app.seudominio.com` → IP do servidor

O Certbot solicitará certificado SSL automaticamente após a instalação.

## Instalações adicionais (múltiplas instâncias)

Para criar outra instância no mesmo servidor:

```bash
cd automacao/installer
sudo ./install_instancia
```

Será solicitado o nome da nova instância, senha do banco e subdomínios. Cada instância usa portas e bancos diferentes.

## Estrutura após instalação

```
/var/www/post01/          # Nome da instância
├── backend/
│   ├── .env
│   └── dist/
├── frontend/
│   ├── config/.env.production
│   └── dist/
└── ...
```

## Comandos úteis

```bash
# Ver processos PM2
pm2 list

# Reiniciar backend
pm2 restart post01-backend

# Logs
pm2 logs post01-backend
```

## Configuração salva

O arquivo `installer/config` contém senhas e configurações. **Não versionar no Git.**

## Personalizar repositório

Antes de instalar, edite `installer/variables/_app.sh` e defina `REPO_URL` com a URL do seu repositório, ou informe durante o prompt.
