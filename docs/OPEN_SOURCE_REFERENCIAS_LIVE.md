# Referências open source para o Sofia: rádio e live de vídeo
Data da pesquisa: 14/10/2026

## 1. Sala de áudio com assentos
- Repositório: https://github.com/ZEGOCLOUD/zego_uikit_prebuilt_live_audio_room_flutter
- Licença declarada: MIT.
- O que demonstra: sala de áudio pronta, gestão/troca de assentos, remoção de palestrantes, layout customizável, chat em tempo real, convites para falar e presentes virtuais.
- Exemplo: https://github.com/ZEGOCLOUD/zego_uikit_prebuilt_live_audio_room_example_flutter (MIT).
- Limites: exige projeto ZEGOCLOUD e credenciais AppID/AppSign; o exemplo/documentação recomenda ativar serviço de chat in-app. Licença MIT do wrapper não significa que o serviço de mídia em nuvem seja gratuito ou sem limites.
- Fonte adicional: https://pub.dev/packages/zego_uikit_prebuilt_live_audio_room/license

## 2. Transporte de mídia em tempo real para áudio/vídeo
- Repositório: https://github.com/livekit/client-sdk-flutter
- Licença declarada: Apache-2.0.
- O que demonstra: SDK Flutter para publicar microfone/câmera, conectar salas e reproduzir mídia em Android/iOS/web/desktop.
- Limites: requer servidor LiveKit Cloud ou auto-hospedado e tokens válidos. O SDK sozinho não cria backend, autenticação, cobrança, assentos, PK ou economia.
- Fonte: https://docs.livekit.io/transport/sdk-platforms/flutter/

## 3. Streaming de vídeo
- Repositório: https://github.com/ossrs/flutter_live
- Licença declarada: MIT.
- O que demonstra: app Flutter de reprodução de live com protocolos RTMP/HTTP-FLV/HLS/WebRTC e servidor SRS.
- Limites: é principalmente um player de streaming; não é implementação completa de salas sociais com assentos, gifts, PK e economia.

## Arquitetura recomendada no Sofia (não confundir modos)
### Modo Rádio
- Entrar/sair de sala de áudio sem renderizar câmera por padrão.
- Assentos como estado de sala; uma pessoa não pode ocupar várias cadeiras ao mesmo tempo.
- Estado do microfone precisa controlar publicação real do áudio no SDK RTC, não apenas ícone ou evento Socket.IO.
- Ouvintes não publicam áudio até obterem permissão/assento.
- Chat e presentes são canais de aplicação separados da mídia.

### Modo Live de Vídeo
- Host publica vídeo e áudio.
- Co-hosts podem publicar áudio e, quando permitido, vídeo em tiles menores.
- Batalha PK é uma camada de produto sobre sessões de vídeo: equipes/participantes, pontuação e temporizador precisam de estado sincronizado no servidor.
- Não misturar a live de vídeo com a sala de rádio na navegação nem inicializar câmera em salas de áudio.

## Estado auditado no código Sofia em 13/10/2026
- A tela atual da sala renderiza CameraPreview local e o layout de cadeiras na mesma experiência.
- O serviço de microfone visto no código muda estado local e envia sinal Socket.IO, mas não foi encontrado SDK cliente RTC instalado no pubspec para transportar áudio.
- Existe serviço Zego que obtém token, mas token sem SDK cliente não publica nem reproduz áudio.
- Portanto, a câmera local abrir não prova transmissão de vídeo a outros participantes; é necessário teste entre dois dispositivos.
- A UI administrativa tem dados simulados; não conectar ações reais sem auditar autenticação e rotas.
- A senha/licença/AppID nunca deve ser copiada para documentação ou logs.

## Próximos passos seguros
1. Separar modos rádio e vídeo por tipo de sala já existente, preservando os widgets e rotas originais onde funcionam.
2. Escolher um único SDK RTC compatível com as credenciais realmente disponíveis. Não trocar SDK nem declarar integração completa antes de confirmar licença/conta.
3. Implementar publicação/assinatura real de áudio e vídeo e testar com duas contas em dois aparelhos.
4. Implementar assentos sincronizados no servidor e impedir duplicidade de assento por usuário.
5. Construir PK somente após o fluxo de vídeo/co-host estar estável; manter score/tempo autoritativos no backend.
6. Testar Android. Para iOS é obrigatório macOS com Xcode e assinatura de desenvolvimento Apple; Windows não gera um app iOS instalável.
