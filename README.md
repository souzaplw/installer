# Instalador - WhatsApp Group Sender SaaS

Instalador estilo [Whaticket SaaS](https://github.com/plwdesign/instaladorwhatsapsaas-main-new) para deploy em servidor Linux (Ubuntu/Debian).

**GP** - Inserir em meu installer | Nginx • Certbot • PM2 • PostgreSQL • Node.js

## Pré-requisitos

- Ubuntu 20.04+ ou Debian 11+
- Acesso root (sudo)
- Domínio apontando para o IP do servidor (para SSL)
- Repositório Git do projeto

## Menu principal (recomendado)

```bash
cd automacao/installer
chmod +x install.sh install_primaria install_instancia scripts/*.sh
sudo ./install.sh
```

### Opções do menu

| Opção | Descrição |
|-------|-----------|
| 1 | **Instalação primária** - Instalar do zero (Nginx, Certbot, SSL) |
| 2 | **Nova instância** - Adicionar outra instância no servidor |
| 3 | **Trocar domínio** - Alterar domínios API/App e gerar novo SSL |
| 4 | **Remover instalação** - Parar PM2, remover Nginx, opcional: banco/dados |
| 5 | **Atualizar** - Puxar alterações do GitHub e recompilar |
| 0 | Sair |

## Primeira instalação (direta)

```bash
# Atualizar sistema
sudo apt update
sudo apt upgrade -y

# Clonar e executar
sudo apt install -y git
git clone https://github.com/SEU_USUARIO/automacao.git
cd automacao/installer
chmod +x install.sh install_primaria install_instancia scripts/*.sh
sudo ./install.sh
# Escolha opção 1 (Instalação primária)
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

No menu principal, opção **2** (Nova instância), ou diretamente:

```bash
cd automacao/installer
sudo ./install_instancia
```

Será solicitado o nome da nova instância, senha do banco e subdomínios. Cada instância usa portas e bancos diferentes.

## Trocar domínio

Para alterar os domínios (ex: migrar para novo domínio) e gerar novo certificado SSL:

```bash
sudo ./install.sh
# Opção 3 (Trocar domínio)
```

Ou diretamente: `sudo ./scripts/trocar_dominio.sh`

## Remover instalação

Para remover uma instância (PM2, Nginx, banco e/ou arquivos):

```bash
sudo ./install.sh
# Opção 4 (Remover instalação)
```

Será perguntado o que remover: processos PM2, configs Nginx, banco de dados e arquivos.

## Estrutura após instalação

```
/home/deploy/instancia/post01/   # Nome da instância (usuário deploy)
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

## Migrations com falha

Se `prisma migrate deploy` falhar com erro P3018, execute primeiro:

```bash
cd backend
npx prisma migrate resolve --rolled-back "NOME_DA_MIGRATION_FALHADA"
npx prisma migrate deploy
```

## Configuração salva

O arquivo `installer/config` contém senhas e configurações. **Não versionar no Git.**

## Personalizar repositório

Antes de instalar, edite `installer/variables/_app.sh` e defina `REPO_URL` com a URL do seu repositório, ou informe durante o prompt.
