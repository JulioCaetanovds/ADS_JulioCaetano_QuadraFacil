# QuadraFácil

Repositório com duas partes principais:

- `quadrafacil-api` — backend (Node.js + TypeScript) com endpoints REST para quadras, partidas, reservas e chat; integra com Firebase para autenticação.
- `quadrafacil-flutter` — aplicativo cliente em Flutter que consome a API e usa Firebase Auth para login.

Este README de nível superior descreve a arquitetura do projeto, instruções rápidas para rodar localmente (backend + frontend), variáveis sensíveis e links para os READMEs específicos de cada subprojeto.

---

## Visão rápida
QuadraFácil é uma aplicação para descoberta e reserva de quadras e organização de partidas. O backend expõe recursos para quadras, partidas, reservas e comunicação entre usuários; o frontend é um app móvel Flutter com telas para atletas e donos de quadra.

## Conteúdo do repositório
- `quadrafacil-api/` — código do backend (Express + TypeScript). Contém `Dockerfile`, `docker-compose.yml`, `serviceAccountKey.json` e `src/` com rotas e controllers.
- `quadrafacil-flutter/` — app Flutter (código em `lib/`, `pubspec.yaml`, `firebase_options.dart`).
- `LICENSE`, `analysis_options.yaml`, etc.

## Arquitetura e fluxo
1. O app Flutter (cliente) faz requisições HTTP para a API (endpoints documentados nos READMEs e em `quadrafacil-api/src/routes`).
2. O backend usa Firebase para autenticação e validação de tokens; também realiza lógica de negócios (reservas, criação/gerenciamento de partidas, chat).
3. Comunicação entre frontend e backend é via REST JSON; o app também usa Firebase (Auth) para login.

## Tecnologias principais
- Backend: Node.js, TypeScript, Express, Firebase Admin SDK, Docker
- Frontend: Flutter (Dart), Firebase Auth

## Instruções rápidas (Windows PowerShell)

Pré-requisitos
- Docker & Docker Compose (opcional — recomendado para backend)
- Node.js & npm (se preferir rodar backend sem Docker)
- Flutter SDK (para rodar o app)

Rodando o backend (recomendado: Docker Compose)
No diretório `quadrafacil-api` execute:

```powershell
cd quadrafacil-api
docker-compose up --build
```

Isso irá construir e subir o serviço da API conforme `docker-compose.yml`.

Rodando o backend sem Docker

```powershell
cd quadrafacil-api
npm install
npm run build   # se houver script de build/tsc
npm start
```

Rodando o frontend (Flutter)
No diretório `quadrafacil-flutter` execute:

```powershell
cd quadrafacil-flutter
flutter pub get
flutter run
```

Ajustes locais
- Backend: confere `quadrafacil-api/src/config` para configurações relacionadas ao Firebase e variáveis de ambiente.
- Frontend: ajuste a URL da API em `quadrafacil-flutter/lib/core/config.dart` (variável `AppConfig.apiUrl`) para apontar para o backend (ex.: `http://localhost:3000`).

## Variáveis sensíveis e arquivos de credenciais
- `quadrafacil-api/serviceAccountKey.json` — chave de serviço do Firebase (já presente). Mantenha este arquivo privado e não o publique em repositórios públicos.
- Outros segredos (tokens, senhas de DB) devem ser configurados via variáveis de ambiente no ambiente de deployment ou no `docker-compose.yml`.

## Endpoints importantes (resumo)
Veja `quadrafacil-api/src/routes` para a lista completa; exemplos:
- `GET /courts/public` — listar quadras públicas (usado no Explore do app)
- `GET /courts/:id/public-details` — detalhes da quadra
- `GET /courts/:id/availability` — disponibilidade/agenda da quadra
- `GET /matches/public` — partidas abertas
- `GET /matches/:id` — detalhes da partida
- `POST /matches/:id/join` — entrar em partida
- `GET /bookings/athlete` — reservas do atleta
- `/chat/*` — endpoints relacionados a chat por partida

## Estrutura de pastas (resumida)
- `quadrafacil-api/`
  - `src/routes/` — rotas
  - `src/controllers/` — controladores
  - `src/config/` — configuração (Firebase, etc.)
  - `Dockerfile`, `docker-compose.yml`, `serviceAccountKey.json`
- `quadrafacil-flutter/`
  - `lib/` — código Flutter (features, core, shared)
  - `pubspec.yaml`, `firebase_options.dart`

## README específicos
- Backend: veja `quadrafacil-api/README.md` (instruções detalhadas para desenvolvimento e execução)
- Frontend: veja `quadrafacil-flutter/README.md` (instruções do Flutter e configuração do Firebase)

## Como contribuir
- Abra uma issue descrevendo o problema/feature.
- Faça um fork/branch e abra um Pull Request com descrições claras e screenshots quando relevantes.
- Adote os padrões de lint do Flutter (`analysis_options.yaml`) e as convenções TypeScript do backend (`tsconfig.json`).

## Testes
- Backend: veja scripts em `quadrafacil-api/package.json` (se houver). Rode testes locais conforme configuração do projeto.
- Frontend: `flutter test` para rodar testes Dart/Flutter.

## Deploy
- Backend: Docker image + orquestração (ex.: `docker-compose`, Kubernetes). Ajuste variáveis de ambiente e substitua `serviceAccountKey.json` por uma forma segura de injetar credenciais.
- Frontend: gerar builds (`flutter build apk` / `flutter build ios`) e publicar nas lojas ou distribuir internamente.

## Licença
Veja o arquivo `LICENSE` na raiz do repositório.

## Contato
Abra uma issue neste repositório ou contate o mantenedor do projeto para dúvidas e suporte.
