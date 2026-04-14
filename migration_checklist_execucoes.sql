-- ============================================================
-- IDX Sistema Operacional — Migration
-- Tabela: checklist_execucoes
-- Finalidade: armazenar o estado dos checklists diário,
--             semanal e mensal com histórico completo.
-- ============================================================
-- Execute este SQL no Supabase:
-- Dashboard → SQL Editor → New Query → Cole e execute
-- ============================================================

-- 1. Criar a tabela
CREATE TABLE IF NOT EXISTS public.checklist_execucoes (
  id            uuid             DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo          text             NOT NULL,          -- 'diario' | 'semanal' | 'mensal'
  periodo       text             NOT NULL,          -- '2026-04-14' | '2026-W16' | '2026-04'
  secao_key     text             NOT NULL,          -- ex: 'abertura', 'gestao', 'fechamento'
  item_key      text             NOT NULL,          -- ex: 'a1', 'g3', 'm2'
  concluido     boolean          NOT NULL DEFAULT false,
  concluido_em  timestamptz,                        -- NULL se não concluído
  created_at    timestamptz      NOT NULL DEFAULT now(),
  updated_at    timestamptz      NOT NULL DEFAULT now(),

  -- Garante que cada item de cada período é único
  UNIQUE (tipo, periodo, secao_key, item_key)
);

-- 2. Índices para performance
CREATE INDEX IF NOT EXISTS idx_checklist_tipo_periodo
  ON public.checklist_execucoes (tipo, periodo);

CREATE INDEX IF NOT EXISTS idx_checklist_periodo
  ON public.checklist_execucoes (periodo);

-- 3. Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_checklist_updated_at ON public.checklist_execucoes;
CREATE TRIGGER trg_checklist_updated_at
  BEFORE UPDATE ON public.checklist_execucoes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. Row Level Security (RLS)
-- Habilitar RLS na tabela
ALTER TABLE public.checklist_execucoes ENABLE ROW LEVEL SECURITY;

-- Policy: acesso total (sistema single-user sem auth, usa anon key)
-- Se no futuro usar auth.users, troque por: auth.uid() = user_id
DROP POLICY IF EXISTS "checklist_public_access" ON public.checklist_execucoes;
CREATE POLICY "checklist_public_access"
  ON public.checklist_execucoes
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 5. Comentários para documentação
COMMENT ON TABLE public.checklist_execucoes IS
  'Histórico de execução dos checklists diário, semanal e mensal da IDX Sistema Operacional';
COMMENT ON COLUMN public.checklist_execucoes.tipo IS
  'Tipo do checklist: diario | semanal | mensal';
COMMENT ON COLUMN public.checklist_execucoes.periodo IS
  'Identificador do período: YYYY-MM-DD (diário) | YYYY-WNN (semanal) | YYYY-MM (mensal)';
COMMENT ON COLUMN public.checklist_execucoes.secao_key IS
  'Chave da seção dentro do checklist (ex: abertura, gestao, analise)';
COMMENT ON COLUMN public.checklist_execucoes.item_key IS
  'Chave do item dentro da seção (ex: a1, g3, m2)';
COMMENT ON COLUMN public.checklist_execucoes.concluido IS
  'true = item marcado como concluído; false = pendente';
COMMENT ON COLUMN public.checklist_execucoes.concluido_em IS
  'Timestamp exato em que o item foi marcado como concluído (NULL se pendente)';

-- ============================================================
-- VERIFICAÇÃO: execute após a migration para confirmar sucesso
-- ============================================================
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'checklist_execucoes'
-- ORDER BY ordinal_position;
