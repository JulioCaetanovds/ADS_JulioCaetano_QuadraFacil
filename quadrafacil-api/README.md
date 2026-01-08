# QuadraFácil — Backend (quadrafacil-api)

API REST para o aplicativo QuadraFácil — gerencia quadras, partidas, reservas, chats e autenticação.

## Visão geral
Este projeto contém o backend do QuadraFácil, uma API em Node.js/TypeScript (com Dockerfile e docker-compose) usada pelo app cliente Flutter.

Principais responsabilidades:
- Autenticação (Firebase)
- CRUD de quadras e disponibilidade
- Gerenciamento de partidas (matches)
- Reservas (bookings)
- Chat entre participantes

## Tecnologias
- Node.js + TypeScript
- Express (rotas/controllers)
- Firebase (service account)
- Docker / Docker Compose

## Estrutura principal
- `src/` — código fonte
  - `routes/` — definições das rotas (auth, booking, chat, court, match)
  - `controllers/` — lógica das rotas
  - `config/firebase.ts` — inicialização do Firebase
  - `middleware/` — middlewares (ex.: `auth.middleware.ts`)
- `Dockerfile` / `docker-compose.yml`
- `serviceAccountKey.json` — chave de serviço do Firebase (já presente; mantenha confidencial)

## Endpoints principais (resumo)
Esses endpoints são os mais relevantes para o cliente Flutter:
- `GET /courts/public` — quadras públicas / listagem (Explore)
- `GET /courts/:id/public-details` — detalhes públicos de uma quadra
- `GET /courts/:id/availability` — disponibilidade/agenda da quadra
- `GET /matches/public` — partidas abertas
- `GET /matches/:id` — detalhes da partida
- `POST /matches/:id/join` — solicitar participação
- `POST /matches/:id/leave` — sair da partida
- `GET /bookings/athlete` — reservas do atleta
- `/chat/*` — endpoints de chat por partida

(Consulte `src/routes` e `src/controllers` para a lista completa e formatos de request/response.)

## Pré-requisitos
- Docker + Docker Compose ou Node.js + npm
- (Opcional) Conta Firebase / credenciais em `serviceAccountKey.json`

## Execução — via Docker Compose (recomendado)
No diretório `quadrafacil-api`:

```powershell
docker-compose up --build
```

Isso inicializa a API e quaisquer serviços vinculados definidos no `docker-compose.yml`.

## Execução — sem Docker (node)
No diretório `quadrafacil-api`:

```powershell
npm install
npm run build    # se existir script de build/tsc
npm start
```

Ajuste os scripts conforme `package.json`.

## Variáveis e segredos
- `serviceAccountKey.json` — chave de serviço do Firebase necessária para operações autenticadas do servidor. Nunca comite versões públicas dessa chave em repositórios públicos.
- Outros segredos/URLs podem ser carregados via variáveis de ambiente — ver `src/config`.

## Desenvolvimento e contribuição
- Use as rotas em `src/routes` como ponto de entrada.
- Controllers em `src/controllers` seguem a lógica de negócio.
- Padronize com as regras do `tsconfig.json`.

## Licença
Confira o arquivo `LICENSE` na raiz do repositório para os termos de licença.

## Contato
Para dúvidas sobre o backend, abra uma issue no repositório ou contate o mantenedor.
