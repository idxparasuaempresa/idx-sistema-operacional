-- ============================================================
-- IDX Sistema Operacional — Migration
-- Tabela: client_benchmarks
-- Finalidade: armazenar benchmarks e metas por cliente,
--             incluindo referência de setor e metas customizadas.
-- ============================================================
-- Execute no Supabase: Dashboard → SQL Editor → New Query
-- ============================================================

CREATE TABLE IF NOT EXISTS public.client_benchmarks (
  id               uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id        uuid        NOT NULL,               -- FK para clientes.id
  nicho_ref        text,                               -- chave do nicho ex: 'clinica_saude'

  -- Metas do cliente (personalizadas)
  meta_cpm         numeric(10,2),
  meta_cpc         numeric(10,2),
  meta_ctr         numeric(10,2),
  meta_hook_rate   numeric(10,2),
  meta_connect_rate numeric(10,2),
  meta_cpa_whats   numeric(10,2),
  meta_cpa_lead    numeric(10,2),
  meta_freq_max    numeric(10,2),
  meta_taxa_conv_lp numeric(10,2),
  meta_roas        numeric(10,2),

  obs              text,                               -- observações livres
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- Garante um registro por cliente
CREATE UNIQUE INDEX IF NOT EXISTS idx_client_benchmarks_client
  ON public.client_benchmarks (client_id);

-- Trigger updated_at (reutiliza a função criada pela migration anterior)
DROP TRIGGER IF EXISTS trg_client_benchmarks_updated_at ON public.client_benchmarks;
CREATE TRIGGER trg_client_benchmarks_updated_at
  BEFORE UPDATE ON public.client_benchmarks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE public.client_benchmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "benchmarks_public_access" ON public.client_benchmarks;
CREATE POLICY "benchmarks_public_access"
  ON public.client_benchmarks
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Comentários
COMMENT ON TABLE public.client_benchmarks IS
  'Benchmarks e metas de performance por cliente — referência de setor + metas personalizadas';

-- ============================================================
-- VERIFICAÇÃO após executar:
-- SELECT * FROM public.client_benchmarks LIMIT 5;
-- ============================================================
