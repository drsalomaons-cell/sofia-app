-- Migração Fase 1: Adicionar cover_url e frame_id à tabela de usuários
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS cover_url TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS frame_id TEXT;
