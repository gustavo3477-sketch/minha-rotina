# Minha Rotina

App de escala de trabalho, agenda e compromissos — offline-first, feito em Flutter/Dart com banco de dados local (SQLite). Não depende de internet nem de um servidor: tudo fica guardado no próprio aparelho.

## O que o app faz

- **Escala de trabalho configurável**: qualquer ciclo (2x2, 4x2, turnos com nomes e horários próprios...), com dias fixos por dia da semana (ex.: domingo sempre de folga) e exceções manuais pontuais.
- **Hoje**: o que o dia de hoje representa, quando é a próxima folga, e os compromissos de hoje.
- **Calendário**: visão do mês inteiro, cada dia colorido pela categoria da escala.
- **Compromissos**: criar, editar, excluir — com ou sem recorrência (diária, semanal, mensal, anual), lembretes locais, e "trabalho extra" (mesmo formulário, com um campo de valor opcional).
- **Agenda**: lista dos próximos compromissos, com busca.
- **Ajustes**: categorias (nomes, cores, ícones) e a escala em si, totalmente editáveis.
- **Backup/restauração**: exporta tudo num único arquivo, que pode ser salvo ou enviado por qualquer app do sistema (Drive, e-mail...); restaura a partir desse mesmo arquivo.
- **Widget na tela inicial (Android)**: mostra a categoria do dia sem precisar abrir o app.

## Status do desenvolvimento

O desenvolvimento segue 16 etapas. As etapas 1 a 13 (tudo que funciona em Android) estão completas e testadas:

| Etapa | O que é | Status |
|---|---|---|
| 1 | Ambiente e estrutura do projeto | ✅ |
| 2 | Banco de dados, modelos e repositórios | ✅ |
| 3 | Motor da escala (com testes automatizados) | ✅ |
| 4 | Calendário | ✅ |
| 5 | Tela Hoje + detalhe do dia | ✅ |
| 6 | Compromissos (criar/editar/excluir) | ✅ |
| 7 | Compromissos recorrentes | ✅ |
| 8 | Agenda | ✅ |
| 9 | Notificações (lembretes locais) | ✅ Android |
| 10 | Configurações (categorias e escala) | ✅ |
| 11 | Backup e restauração | ✅ |
| 12 | Polimento | ✅ |
| 13 | Widget da tela inicial | ✅ Android |
| 14 | Preparação iOS | 🟡 parcial — ver abaixo |
| 15 | Widget iOS (WidgetKit/SwiftUI) | ⏳ precisa de Mac |
| 16 | Build e testes reais em iOS | ⏳ precisa de Mac |

## Rodando os testes

Com o Flutter instalado e `flutter pub get` já executado:

```bash
flutter analyze
flutter test
```

Isso não exige Android nem iOS de verdade: os testes usam um banco SQLite em memória (`sqflite_common_ffi`).

## Continuando no Android

```bash
flutter build apk --debug
```

gera o instalável em `build/app/outputs/flutter-apk/app-debug.apk`. Para rodar num emulador ou aparelho conectado, `flutter run`.

## Continuando no iOS (precisa de um Mac)

As etapas 14 (parte que depende de Xcode), 15 e 16 só podem ser feitas com um Mac — não existe forma de compilar, assinar ou testar um app iOS a partir do Windows. O que já foi preparado sem precisar de Mac:

- `ios/Runner/Info.plist`: nome de exibição do app já está correto ("Minha Rotina").
- `ios/Runner/AppDelegate.swift`: já registra o app como delegate de notificações (exigido pelo `flutter_local_notifications` para notificações aparecerem com o app aberto) — mas isso nunca foi compilado nem testado de verdade, só escrito seguindo o padrão documentado do plugin.

### Passo a passo para retomar num Mac

1. **Instalar o Flutter no Mac**, se ainda não tiver: siga <https://docs.flutter.dev/get-started/install/macos>.
2. **Instalar o Xcode** pela App Store (gratuito). Depois de instalado, abra o Xcode uma vez para ele terminar a instalação de componentes adicionais.
3. **Copiar o projeto para o Mac** (por exemplo, via `git clone` do mesmo repositório, ou copiando a pasta inteira).
4. Num Terminal, dentro da pasta do projeto, rode:
   ```bash
   flutter pub get
   ```
5. Abra o projeto iOS no Xcode: dentro da pasta do projeto, abra o arquivo `ios/Runner.xcworkspace` (não o `.xcodeproj`) — dando duplo clique nele, ou rodando `open ios/Runner.xcworkspace` no Terminal.
6. No Xcode, clique em "Runner" na lista à esquerda, depois na aba "Signing & Capabilities":
   - Marque "Automatically manage signing".
   - Em "Team", escolha sua conta de desenvolvedor Apple (é preciso ter uma — grátis para testar no seu próprio aparelho, paga para publicar na App Store).
   - Se aparecer erro de "Bundle Identifier" já em uso, troque `com.minharotina.minha_rotina` por algo único seu (esse identificador está em `ios/Runner.xcodeproj` e em `android/app/build.gradle.kts` — no Android já está certo, só o lado iOS precisa combinar com sua conta).
7. Conecte um iPhone por cabo (ou escolha um simulador na barra superior do Xcode) e clique no botão de "play" (▶) para compilar e rodar.
8. **Verifique, nessa ordem** (a mesma lista de qualquer etapa nova):
   - O app abre sem travar.
   - A configuração inicial de escala funciona.
   - As 5 abas (Hoje, Calendário, +, Agenda, Ajustes) abrem.
   - Criar um compromisso com lembrete: aceite a permissão de notificação quando aparecer, e confirme que o lembrete chega na hora certa.
   - Exportar e restaurar um backup.
9. Depois disso, quem estiver com acesso ao Mac pode voltar a pedir a continuação das Etapas 15 (widget iOS) e 16 (testes finais), já com o ambiente funcionando.

Se qualquer passo acima der um erro que não é claro, é mais seguro colar a mensagem de erro completa e pedir ajuda do que tentar adivinhar a causa.
