-- SOFIA PostgreSQL / Supabase schema
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  email TEXT UNIQUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS rooms (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  region TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rooms_active ON rooms(is_active);

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  type TEXT,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tx_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_tx_type ON transactions(type);

CREATE TABLE IF NOT EXISTS gift_catalog (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS gift_log (
  id SERIAL PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS economy_config (
  id INT PRIMARY KEY DEFAULT 1,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pending_payments (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  type TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  external_id TEXT,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_payments(status);

CREATE TABLE IF NOT EXISTS job_runs (
  job_name TEXT PRIMARY KEY,
  last_run_at TIMESTAMPTZ,
  data JSONB
);

-- Collections used by the Directus administrative panel.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS administradores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  senha TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('central', 'regional')),
  regiao TEXT NOT NULL DEFAULT 'todas',
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  data_criacao TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_usuario TEXT NOT NULL,
  email TEXT UNIQUE,
  regiao TEXT NOT NULL,
  saldo_moedas INTEGER NOT NULL DEFAULT 0 CHECK (saldo_moedas >= 0),
  bio TEXT,
  url_imagem_perfil TEXT,
  status TEXT NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'banido'))
);

CREATE TABLE IF NOT EXISTS salas_agencias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  regiao TEXT NOT NULL,
  url_imagem TEXT,
  descricao TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  alterado_por UUID REFERENCES administradores(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS solicitacoes_moedas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  quantidade_solicitada INTEGER NOT NULL CHECK (quantidade_solicitada > 0),
  quantidade_liberada INTEGER CHECK (quantidade_liberada IS NULL OR quantidade_liberada > 0),
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovada', 'rejeitada')),
  data_solicitacao TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  aprovado_por UUID REFERENCES administradores(id) ON DELETE SET NULL,
  data_aprovacao TIMESTAMPTZ,
  observacao TEXT
);

CREATE TABLE IF NOT EXISTS mensagens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  remetente_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  destinatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  texto TEXT NOT NULL,
  data_envio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  apagado_por_usuario BOOLEAN NOT NULL DEFAULT FALSE,
  data_apagamento TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS logs_auditoria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_admin_id UUID REFERENCES administradores(id) ON DELETE SET NULL,
  acao TEXT NOT NULL,
  tabela_alterada TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  dados_anteriores JSONB,
  dados_novos JSONB,
  ip INET,
  data_hora TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conteudo_moderacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_conteudo TEXT NOT NULL CHECK (tipo_conteudo IN ('nome', 'imagem', 'bio', 'mensagem')),
  conteudo_original TEXT,
  entidade_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'revisao', 'removido')),
  sinalizado_por UUID REFERENCES administradores(id) ON DELETE SET NULL,
  revisado_por UUID REFERENCES administradores(id) ON DELETE SET NULL,
  data_revisao TIMESTAMPTZ,
  analise_ia JSONB
);

CREATE TABLE IF NOT EXISTS configuracao_solicitacoes_moedas (
  id BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (id = TRUE),
  habilitado BOOLEAN NOT NULL DEFAULT TRUE,
  alterado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  alterado_por UUID REFERENCES administradores(id) ON DELETE SET NULL
);
INSERT INTO configuracao_solicitacoes_moedas (id) VALUES (TRUE) ON CONFLICT (id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_admin_usuarios_regiao ON usuarios(regiao);
CREATE INDEX IF NOT EXISTS idx_admin_salas_regiao ON salas_agencias(regiao);
CREATE INDEX IF NOT EXISTS idx_admin_solicitacoes_status ON solicitacoes_moedas(status);
CREATE INDEX IF NOT EXISTS idx_admin_mensagens_data ON mensagens(data_envio DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_data ON logs_auditoria(data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_admin_moderacao_status ON conteudo_moderacao(status);

CREATE OR REPLACE FUNCTION sofia_aplicar_solicitacao_moedas()
RETURNS TRIGGER AS $$
DECLARE
  liberado INTEGER;
BEGIN
  IF NEW.status = 'aprovada' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'aprovada') THEN
    liberado := COALESCE(NEW.quantidade_liberada, NEW.quantidade_solicitada);
    IF liberado <= 0 OR liberado > NEW.quantidade_solicitada THEN
      RAISE EXCEPTION 'quantidade_liberada deve estar entre 1 e quantidade_solicitada';
    END IF;
    NEW.quantidade_liberada := liberado;
    NEW.data_aprovacao := COALESCE(NEW.data_aprovacao, NOW());
    UPDATE usuarios SET saldo_moedas = saldo_moedas + liberado WHERE id = NEW.usuario_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'usuario da solicitacao nao encontrado'; END IF;
    INSERT INTO logs_auditoria (
      usuario_admin_id, acao, tabela_alterada, registro_id,
      dados_anteriores, dados_novos
    ) VALUES (
      NEW.aprovado_por, 'liberacao_moedas', 'solicitacoes_moedas', NEW.id::TEXT,
      CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
      to_jsonb(NEW)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_solicitacao_moedas_aprovada ON solicitacoes_moedas;
CREATE TRIGGER trg_solicitacao_moedas_aprovada
BEFORE INSERT OR UPDATE OF status, quantidade_liberada ON solicitacoes_moedas
FOR EACH ROW EXECUTE FUNCTION sofia_aplicar_solicitacao_moedas();

CREATE OR REPLACE FUNCTION sofia_impedir_alteracao_log()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'logs_auditoria e somente leitura';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_logs_auditoria_no_update ON logs_auditoria;
DROP TRIGGER IF EXISTS trg_logs_auditoria_no_delete ON logs_auditoria;
CREATE TRIGGER trg_logs_auditoria_no_update BEFORE UPDATE ON logs_auditoria
FOR EACH ROW EXECUTE FUNCTION sofia_impedir_alteracao_log();
CREATE TRIGGER trg_logs_auditoria_no_delete BEFORE DELETE ON logs_auditoria
FOR EACH ROW EXECUTE FUNCTION sofia_impedir_alteracao_log();
