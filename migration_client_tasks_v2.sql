-- ============================================================
-- IDX Sistema Operacional — Migration client_tasks (v3)
-- Execute no Supabase: SQL Editor → New Query → Run
-- ============================================================

-- PASSO 1: Função set_updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- PASSO 2: Criar tabela (só cria se não existir)
CREATE TABLE IF NOT EXISTS public.client_tasks (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id   uuid,
  titulo      text        NOT NULL,
  tipo        text        NOT NULL DEFAULT 'demanda',
  descricao   text,
  prioridade  text        NOT NULL DEFAULT 'media',
  prazo       date,
  responsavel text,
  pop_content text,
  concluida   boolean     NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- PASSO 3: Adicionar colunas que faltam (ADD COLUMN IF NOT EXISTS é idempotente)
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS tipo        text        NOT NULL DEFAULT 'demanda';
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS descricao   text;
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS prioridade  text        NOT NULL DEFAULT 'media';
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS prazo       date;
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS responsavel text;
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS pop_content text;
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS concluida   boolean     NOT NULL DEFAULT false;
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS created_at  timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.client_tasks ADD COLUMN IF NOT EXISTS updated_at  timestamptz NOT NULL DEFAULT now();

-- PASSO 4: Índices
CREATE INDEX IF NOT EXISTS idx_client_tasks_client    ON public.client_tasks (client_id);
CREATE INDEX IF NOT EXISTS idx_client_tasks_prazo     ON public.client_tasks (prazo);
CREATE INDEX IF NOT EXISTS idx_client_tasks_resp      ON public.client_tasks (responsavel);
CREATE INDEX IF NOT EXISTS idx_client_tasks_concluida ON public.client_tasks (concluida);

-- PASSO 5: Trigger updated_at
DROP TRIGGER IF EXISTS trg_client_tasks_updated_at ON public.client_tasks;
CREATE TRIGGER trg_client_tasks_updated_at
  BEFORE UPDATE ON public.client_tasks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- PASSO 6: RLS
ALTER TABLE public.client_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tasks_public_access" ON public.client_tasks;
CREATE POLICY "tasks_public_access"
  ON public.client_tasks
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- PASSO 7: Comentários
COMMENT ON TABLE  public.client_tasks IS 'Tarefas por cliente — sistema de gestão com POP e responsável';
COMMENT ON COLUMN public.client_tasks.tipo        IS 'demanda | subir_anuncio | nova_campanha | ligar_cliente | relatorio | reuniao | otimizacao | criativo | outro';
COMMENT ON COLUMN public.client_tasks.prioridade  IS 'baixa | media | alta | urgente';
COMMENT ON COLUMN public.client_tasks.responsavel IS 'Nome do responsável (usuário do sistema IDX)';
COMMENT ON COLUMN public.client_tasks.pop_content IS 'Processo Operacional Padrão — passo a passo da atividade';

-- ── VERIFICAÇÃO: rode isso após o script para confirmar ───────
-- SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='client_tasks'
--   ORDER BY ordinal_position;
