-- ============================================================
-- KLICHE — Recordatorio, mora y adjuntos en facturas
-- ============================================================

-- Columnas nuevas en invoices
alter table public.invoices
  add column if not exists reminder_days    int check (reminder_days > 0),
  add column if not exists has_mora         boolean not null default false,
  add column if not exists mora_percentage  numeric(6, 2) check (mora_percentage > 0 and mora_percentage <= 100);

-- Tabla de adjuntos (fotos/PDF por factura y pago)
create table if not exists public.attachments (
  id          uuid primary key default uuid_generate_v4(),
  entity_type text not null check (entity_type in ('invoice', 'payment')),
  entity_id   uuid not null,
  file_name   text not null,
  file_path   text not null,   -- ruta en Supabase Storage
  file_type   text,            -- image/jpeg, application/pdf, etc.
  file_size   bigint,          -- bytes
  uploaded_by uuid,
  created_at  timestamptz not null default now()
);

create index idx_attachments_entity on public.attachments (entity_type, entity_id);

alter table public.attachments enable row level security;

create policy "Authenticated full access" on public.attachments
  for all using (auth.role() = 'authenticated');

-- Función: calcular mora sobre saldo vencido
create or replace function public.calculate_mora(invoice_id uuid)
returns numeric as $$
declare
  v_balance      numeric;
  v_mora_pct     numeric;
  v_has_mora     boolean;
  v_due_date     date;
begin
  select
    s.balance,
    i.has_mora,
    i.mora_percentage,
    i.due_date
  into v_balance, v_has_mora, v_mora_pct, v_due_date
  from public.invoice_summary s
  join public.invoices i on i.id = s.id
  where s.id = invoice_id;

  if not v_has_mora or v_mora_pct is null then
    return 0;
  end if;

  if current_date <= v_due_date or v_balance <= 0 then
    return 0;
  end if;

  -- Mora mensual sobre saldo vencido
  return round(v_balance * (v_mora_pct / 100), 2);
end;
$$ language plpgsql stable;

-- Vista extendida con mora
create or replace view public.invoice_summary_extended as
select
  s.*,
  i.reminder_days,
  i.has_mora,
  i.mora_percentage,
  case
    when i.has_mora and s.status = 'overdue'
    then public.calculate_mora(s.id)
    else 0
  end as mora_amount,
  (select count(*) from public.attachments a
   where a.entity_type = 'invoice' and a.entity_id = s.id
  ) as attachment_count
from public.invoice_summary s
join public.invoices i on i.id = s.id;
