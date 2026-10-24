# Sofia — auditoria e implementação baseada em evidências

Trabalhe apenas no repositório atual Sofia. Não apague dados, não desinstale apps, não troque IDs de pacote sem plano de migração e não remova câmera, live ou integrações existentes antes de auditar.

Objetivo: corrigir o máximo de funcionalidades comprovadamente ausentes e deixar um relatório verificável. Não declare percentuais sem checklist com evidência.

1. Faça backup/branch antes de alterações e leia docs locais e commits.
2. Audite login, cadastro, logout, recuperação, papéis admin, API e persistência; confirme rotas no backend. Nunca imprima tokens, chaves ou senhas.
3. Audite câmera, permissões, áudio RTC, microfone mute/unmute, entrar/sair de canal, assentos e mudança de assento. A câmera já abre: preserve-a. Socket.IO sozinho não transmite áudio; confirme SDK RTC cliente e integração real antes de dizer que voz funciona.
4. Audite presentes, saldo, transações, metas/foguete, ranking, efeitos e carteira. Confirme débito/crédito no servidor; remova apenas simulações claramente identificadas e substitua por fluxo real seguro quando o backend já suportar.
5. Audite painel admin central/regional e autorização server-side. Não confie em controles apenas visuais.
6. Compare docs e exemplos locais e documentação oficial de dependências já adotadas. Prefira documentação oficial/licenças verificadas; não copie marcas ou código proprietário de apps de terceiros.
7. Implemente em passos pequenos, mantendo compatibilidade. Após cada etapa execute testes, análise estática e build. Teste API e app; documente testes que exigem segundo aparelho/credenciais.
8. Gere APK debug e instale no Android conectado via ADB Wi-Fi somente após build bem-sucedido; não desinstale nem limpe dados para contornar assinatura incompatível.
9. iOS: não tente gerar IPA em Windows. Documente o bloqueio e os requisitos de macOS/Xcode, assinatura Apple e dispositivo de teste.
10. Atualize AUDITORIA_SOFIA.md com tabela: item, estado (comprovado/pendente/falhou), evidência, arquivo/rota, teste, risco e próximo passo. Registre exatamente os arquivos alterados e comandos executados.
11. Pare se faltar credencial, licença, SDK ou autorização. Não fabrique credenciais nem invente endpoints. Informe o bloqueio específico e uma alternativa segura.

Relate apenas fatos comprovados e separe build instalado de teste funcional real. Preserve o layout original da live; corrija proporções das cadeiras sem desmontar câmera nem painel.