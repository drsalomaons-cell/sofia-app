# Sofia — arquitetura consolidada e plano de implementação

**Repositório:** `drsalomaons-cell/sofia-app`  
**Branch de trabalho:** `feat/sofia-live-platform-foundation`  
**Escopo:** Flutter mobile + backend existente. Não criar uma segunda aplicação.

## 1. Validação técnica externa

Os cinco pilares do blueprint são tecnicamente realizáveis com componentes existentes no mercado, mas o conjunto específico de regras, telas, economia, veículos e progressão é produto próprio da Sofia — não uma plataforma pronta que possa ser copiada.

- **Áudio/vídeo em tempo real:** WebRTC com SFU é uma arquitetura consolidada. LiveKit documenta SFU, salas, participantes, tracks e SDK Flutter. A Sofia, porém, já contém dependência e adaptador **ZEGO Express**; manter o fornecedor atual até auditar credenciais, contrato, recursos e implementação evita migração desnecessária.
- **Flutter:** a recomendação oficial é separar UI, view models, repositórios e serviços, com lógica de domínio testável.
- **Salas:** salas, participantes e tracks são recursos distintos. O tamanho da sala de áudio não deve ser confundido com quantidade de streams de vídeo.
- **Ledger:** carteira e transferências precisam de transações no servidor, lançamentos imutáveis de débito/crédito, chave de idempotência, restrições de saldo e trilha de auditoria. A interface não pode alterar saldo diretamente.
- **Mensagens privadas:** “criptografado” só deve ser exibido se houver protocolo de criptografia ponta a ponta implementado e gestão segura de chaves. TLS em trânsito, isoladamente, não é E2EE.
- **PK 50/50:** regra de placar e divisão é lógica de produto; exige eventos auditáveis, janela de apuração, desempate, reconciliação e proteção contra duplicidade.

Referências técnicas:
- LiveKit SFU: https://docs.livekit.io/reference/internals/livekit-sfu/
- LiveKit Flutter / conexão: https://docs.livekit.io/intro/basics/connect/
- LiveKit rooms, participants and tracks: https://docs.livekit.io/intro/basics/rooms-participants-tracks/
- Flutter app architecture: https://docs.flutter.dev/app-architecture/guide
- WebRTC: https://webrtc.org/

## 2. Auditoria inicial do código existente (GitHub main)

Confirmado por leitura dos arquivos do repositório:

- Aplicativo Flutter, pacote `sofia`, versão `1.0.4+12010`.
- Dependências atuais incluem `zego_express_engine`, `camera`, `socket_io_client`, `provider`, `dio`, `flutter_secure_storage`, `audioplayers` e player SVGA.
- Android declara permissões INTERNET, CAMERA e RECORD_AUDIO.
- `MediaService` chama `ZegoService` para obter token e entrar em sala de áudio.
- `ZegoService.joinAudioRoom` desativa a câmera e publica áudio. Portanto, o código inspecionado comprova um caminho de áudio ZEGO, mas **não comprova ainda publicação de vídeo ao vivo ZEGO**. O plugin `camera` inicializa câmera local; isso, sozinho, não transmite vídeo aos demais participantes.
- `RoomService` já possui criação/entrada/saída, assentos, moderação e endpoints de ranking/foguete.
- `EconomyService` consulta regras e saldo, mas a leitura inicial não comprova ledger contábil de dupla entrada nem atomicidade no servidor.
- `RoomScreen` já integra Socket.IO para chat/estado/eventos e efeitos de foguete.
- A tela de criação já oferece presets de cadeiras, mas o componente visual limitava a grade a 20.

## 3. Regras de produto que precisam permanecer explícitas

- Salas de voz e salas de vídeo são modalidades distintas.
- Configurações de cadeiras: 4, 6, 8, 10, 12, 15, 20, 24 e 30; a capacidade máxima deve ser validada também no backend.
- O desenho 3×3 é a primeira área visível; capacidades maiores usam grade rolável, não comprimem 30 assentos numa única tela.
- As regras econômicas históricas da Sofia devem ser tratadas como fonte de verdade do produto e não substituídas pelo rascunho 60/40 ou por qualquer divisão não aprovada.
- A economia de presentes, conversão, auto-presente, Presente da Sorte, taxas, agência e host deve ser implementada no servidor com ledger e testes.
- Metas dos sete foguetes e seus prêmios exigem configuração versionada; não inferir valores diferentes dos já aprovados pelo titular.
- Veículos/entradas 3D exigem assets 3D reais, pipeline de carregamento, otimização por dispositivo e fallback. Uma imagem PNG não equivale a modelo 3D interativo.

## 4. Sequência de implementação

1. **Fundação de salas e mídia:** capacidade validada no cliente e servidor; separar sala de voz e vídeo; auditar token ZEGO, callbacks, permissões, publicação e reprodução de áudio/vídeo; testes em dois dispositivos.
2. **Palco de áudio:** host/trono, assentos, pedir/autorizar microfone, mute individual, lock/unlock, moderadores, lista de participantes e reconexão.
3. **Live vídeo e PK:** publicação de câmera, seleção de streams, limites de participantes, sincronização do placar e encerramento auditável.
4. **Mensagens privadas e chamadas:** autorização por conversa, persistência, entrega, bloqueio/denúncia; E2EE somente após desenho e teste de chaves.
5. **Presentes e ledger:** catálogo, inventário, débito/crédito atômico, idempotência, estorno, histórico e conciliação.
6. **Foguetes e progressão:** metas configuráveis, ranking e snapshots imutáveis de apuração.
7. **Garagem 3D e minigames:** catálogo de assets, permissões de uso, performance, telemetria e regras de jogos.

## 5. Critérios de aceite

- Nenhum saldo ou resultado financeiro é decidido pelo cliente.
- Nenhum token ZEGO/segredo de servidor fica no aplicativo.
- Operações de compra/presente/estorno são idempotentes e transacionais.
- Eventos de sala são autorizados no backend, não apenas emitidos pelo Socket.IO.
- Testes de áudio/vídeo são feitos com dois ou mais dispositivos reais.
- O build Flutter e testes do backend passam antes de publicar APK.
- Cada entrega informa arquivos alterados, commit, testes executados e limitações ainda abertas.

## 6. Limites desta primeira entrega

Este commit inicia a implementação segura e registra a auditoria técnica. Não representa a conclusão dos cinco módulos nem confirma publicação de vídeo, E2EE, ledger atômico, ativos 3D ou APK instalado.
