# Relatório de execução — Sofia
Data: 14/10/2026

## Atualização de implementação — sala e controles
- Preservada a câmera local e a estrutura original de sala; não foi removido o preview existente.
- Mantida a escala maior das cadeiras: escala responsiva de 0,88–1,00; cadeira comum base de 64 e trono de 76 unidades após a última leitura do código.
- O botão funcional de ranking foi movido para a faixa superior, abaixo do cabeçalho; abre o ranking de contribuições consultado no backend.
- Barra inferior organizada com Chat, microfone, silenciar/voltar a ouvir o áudio recebido, Presentes e Sair. O ranking não fica mais na barra inferior.
- O botão de silenciar usa a API real do ZEGO `muteAllPlayStreamAudio` para silenciar/reativar o áudio remoto neste aparelho; não desliga a transmissão do participante.
- Adicionada pista de rolagem visível ao histórico de chat. Campo de digitação e botão de envio foram preservados.
- O foguete já existia como elemento flutuante na sala e abre o ranking de contribuições. Não foi encontrada na documentação local uma especificação verificável da meta/progresso do foguete; não inventei valor-alvo nem efeito de conclusão.
- Conferidas referências públicas oficiais ZEGO: sala ao vivo usa publicação de áudio pelos speakers e reprodução de streams pelos ouvintes; controle de assentos precisa de estado sincronizado. Referências: https://www.zegocloud.com/docs/live-streaming-flutter/best-practice/implement-a-live-audio-room e https://www.zegocloud.com/unique-api/express-video-sdk/en/dart_flutter/zego_express_engine/ZegoExpressEnginePlayer/muteAllPlayStreamAudio.html.

## Testes e instalação desta atualização
- `flutter test --no-pub`: 1 teste passou após as alterações.
- `flutter analyze --no-pub`: 16 avisos/info existentes de lint/depreciação; não está limpo.
- `flutter build apk --debug --no-pub --build-name=1.0.1 --build-number=8006`: concluído com exit code 0.
- APK copiado para `C:\Users\Usuario\Desktop\Sofia\Builds\Sofia-2026-10-14-room-controls.apk` e para `C:\Users\Usuario\Desktop\Auditorias_e_Relatorios\Builds\Sofia-2026-10-14-room-controls.apk`.
- Atualização instalada via ADB Wi-Fi no Motorola, como pacote de auditoria `com.sofia.sofia.audit`, versionCode 8006 / versionName 1.0.1; o app foi aberto por comando ADB. O app original `com.sofia.sofia` e seus dados foram preservados.

## Limites ainda não comprovados
- O projeto declara `zego_express_engine` no pubspec; `ZegoService` solicita token, entra na sala, publica stream de áudio e inicia reprodução de streams remotos. Porém, não foi possível provar áudio ponta a ponta sem uma segunda conta/aparelho na mesma sala. O teste de áudio entre dois dispositivos continua pendente.
- A câmera mostrada no painel é um `CameraPreview` local; no código lido, o ZEGO desativa a câmera do engine e não publica stream de vídeo. Portanto, abrir a câmera neste aparelho não comprova que outros participantes vejam o vídeo. Não removi a câmera nem alterei esse fluxo nesta correção de layout.
- O `RoomModel` e o backend ainda não têm tipo explícito persistido para rádio/vídeo; a separação completa dos modos e a batalha PK sincronizada ainda não estão implementadas.
- O painel administrativo contém trechos simulados/TODO; não considerar tudo real até auditar e ligar cada ação a endpoints autorizados.
- iOS: este computador usa Windows. Para gerar e assinar um IPA instalável no iPhone 14 Pro Max é necessário macOS com Xcode e assinatura Apple válida. APK não instala no iPhone.

## Próximas verificações
1. Testar o botão de áudio e o silenciar da sala com duas contas/dispositivos, confirmando token e reprodução/publicação ZEGO.
2. Auditar a publicação de vídeo RTC sem retirar o preview existente.
3. Localizar no material Shabab a regra exata de meta do foguete antes de implementar progresso/efeito.
4. Completar tipos de sala e estado de assentos sincronizado no servidor antes de declarar rádio/vídeo e PK concluídos.
