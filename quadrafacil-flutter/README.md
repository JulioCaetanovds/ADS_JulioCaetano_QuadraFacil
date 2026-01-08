# QuadraFácil — Aplicativo Flutter (quadrafacil-flutter)

Aplicativo móvel cliente para o QuadraFácil — permite explorar quadras, criar/entrar em partidas, reservar horários e conversar com outros usuários.

## Visão geral
O app Flutter consome a API do backend (`quadrafacil-api`) e usa Firebase para autenticação. Contém telas para explorar quadras, ver/gerenciar reservas e partidas, além de painel para donos de quadra.

## Tecnologias
- Flutter (Dart)
- Firebase (Auth)
- Consumo de API REST (configurada via `AppConfig.apiUrl`)

## Estrutura principal
- `lib/` — código Fonte
	- `core/` — configuração do app (`config.dart`, `theme/app_theme.dart`)
	- `features/` — funcionalidades (autenticação, home, profile, owner_panel etc.)
	- `firebase_options.dart` — configuração Firebase gerada pelo CLI
- `pubspec.yaml` — dependências e assets

## Tela e rotas importantes
- `AthleteHomePage` — tela principal do atleta (explorar, reservas, perfil)
- `ExploreTab` — busca e listagem de quadras
- `CourtDetailsPage` — detalhes da quadra e agenda
- `MatchDetailsPage` — detalhes da partida e chat
- `OwnerHomePage` — painel do dono (meus espaços, agenda, perfil)

## Configuração (Firebase e API)
- Firebase: `firebase_options.dart` já existe; certifique-se de ter configurado o projeto Firebase localmente e de que os arquivos `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) estejam no lugar quando necessário.
- Endpoint da API: ver `lib/core/config.dart` (`AppConfig.apiUrl`). Ajuste essa variável para apontar para a instância do backend (ex.: `http://localhost:3000` ou URL do Docker).

## Pré-requisitos
- Flutter SDK instalado (compatível com a versão do projeto)
- Android Studio / Xcode conforme plataforma alvo

## Executando localmente
No diretório `quadrafacil-flutter`:

```powershell
flutter pub get
flutter run
```

Para builds de release, use os comandos padrão do Flutter (`flutter build apk`, `flutter build ios`, etc.).

## Testes e lint
- Use `flutter test` para rodar testes (se existirem).
- Siga `analysis_options.yaml` para regras de lint/estilo.

## Notas de desenvolvimento
- Se adicionar endpoints ou alterar o formato de respostas, atualize `AppConfig.apiUrl` e os pontos de consumo no `lib/features/*`.
- Widgets reutilizáveis (ex.: `BookingListItem`, `CourtCard`) estão dentro de `lib/features/home/presentation/pages/` — considere mover para `lib/shared/widgets/` se forem usados em vários lugares.

## Contribuição
- Abra issues para bugs/feature requests.
- Envie PRs explicando o que altera e incluindo screenshots quando for UI.

## Licença
Veja o arquivo `LICENSE` na raiz do repositório.

## Contato
Abra uma issue no repositório ou contacte o mantenedor para dúvidas.
