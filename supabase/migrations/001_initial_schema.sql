-- ============================================================
-- KLICHE — Schema inicial de cuentas por pagar
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- Extensiones
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm"; -- búsqueda fuzzy

-- ============================================================
-- PROVEEDORES
-- ============================================================
create table public.suppliers (
  id            uuid primary key default uuid_generate_v4(),
  name          text not null,
  initials      text not null,
  tax_id        text unique,
  contact_name  text,
  email         text,
  phone         text,
  category      text,
  address       text,
  website       text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- índice para búsqueda
create index idx_suppliers_name on public.suppliers using gin (name gin_trgm_ops);
create index idx_suppliers_active on public.suppliers (is_active);

-- ============================================================
-- FACTURAS
-- ============================================================
create table public.invoices (
  id              uuid primary key default uuid_generate_v4(),
  invoice_number  text not null unique,
  supplier_id     uuid not null references public.suppliers(id) on delete restrict,

  -- Fechas
  issue_date      date not null default current_date,
  due_date        date not null,

  -- Montos
  net_amount      numeric(18, 2) not null check (net_amount > 0),

  -- Novedades
  novedad_type    text not null default 'ok' check (novedad_type in ('ok', 'desc', 'other')),
  novedad_text    text,

  -- Estado administrativo
  is_rejected     boolean not null default false,
  rejection_notes text,

  -- Metadatos
  notes           text,
  created_by      uuid,          -- futuro: users table
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- índices
create index idx_invoices_supplier   on public.invoices (supplier_id);
create index idx_invoices_due_date   on public.invoices (due_date);
create index idx_invoices_number     on public.invoices using gin (invoice_number gin_trgm_ops);
create index idx_invoices_rejected   on public.invoices (is_rejected);

-- ============================================================
-- DESCUENTOS (ítems por factura)
-- ============================================================
create table public.discount_items (
  id                uuid primary key default uuid_generate_v4(),
  invoice_id        uuid not null references public.invoices(id) on delete cascade,
  product           text not null,
  quantity          numeric(12, 4) not null default 1 check (quantity > 0),
  original_value    numeric(18, 2) not null check (original_value >= 0),
  discounted_value  numeric(18, 2) not null check (discounted_value >= 0),
  reason            text,
  created_at        timestamptz not null default now(),

  constraint discounted_lte_original check (discounted_value <= original_value)
);

create index idx_discount_items_invoice on public.discount_items (invoice_id);

-- ============================================================
-- PAGOS
-- ============================================================
create table public.payments (
  id            uuid primary key default uuid_generate_v4(),
  invoice_id    uuid not null references public.invoices(id) on delete restrict,
  payment_date  date not null default current_date,
  amount        numeric(18, 2) not null check (amount > 0),
  method        text not null default 'transfer'
                  check (method in ('transfer', 'cash', 'check', 'card', 'other')),
  notes         text,
  created_by    uuid,
  created_at    timestamptz not null default now()
);

create index idx_payments_invoice    on public.payments (invoice_id);
create index idx_payments_date       on public.payments (payment_date);
create index idx_payments_created_at on public.payments (created_at desc);

-- ============================================================
-- VISTA: invoice_summary
-- Campos calculados: discount_amount, final_amount, total_paid, balance, status
-- ============================================================
create or replace view public.invoice_summary as
select
  inv.id,
  inv.invoice_number,
  inv.supplier_id,
  sup.name               as supplier_name,
  sup.initials           as supplier_initials,
  inv.issue_date,
  inv.due_date,
  inv.net_amount,
  inv.novedad_type,
  inv.novedad_text,
  inv.is_rejected,
  inv.notes,
  inv.created_at,
  inv.updated_at,

  -- Descuentos
  coalesce(
    (select sum((d.original_value - d.discounted_value) * d.quantity)
     from public.discount_items d
     where d.invoice_id = inv.id),
    0
  ) as discount_amount,

  -- Valor final
  inv.net_amount - coalesce(
    (select sum((d.original_value - d.discounted_value) * d.quantity)
     from public.discount_items d
     where d.invoice_id = inv.id),
    0
  ) as final_amount,

  -- Total pagado
  coalesce(
    (select sum(p.amount) from public.payments p where p.invoice_id = inv.id),
    0
  ) as total_paid,

  -- Conteo de pagos
  coalesce(
    (select count(*) from public.payments p where p.invoice_id = inv.id),
    0
  ) as payment_count,

  -- Balance (saldo)
  (
    inv.net_amount - coalesce(
      (select sum((d.original_value - d.discounted_value) * d.quantity)
       from public.discount_items d where d.invoice_id = inv.id), 0)
  ) - coalesce(
    (select sum(p.amount) from public.payments p where p.invoice_id = inv.id), 0
  ) as balance,

  -- Estado derivado
  case
    when inv.is_rejected then 'rejected'
    when (
      (inv.net_amount - coalesce(
        (select sum((d.original_value - d.discounted_value) * d.quantity)
         from public.discount_items d where d.invoice_id = inv.id), 0))
      - coalesce(
        (select sum(p.amount) from public.payments p where p.invoice_id = inv.id), 0)
    ) <= 0.01 then 'paid'
    when coalesce(
      (select sum(p.amount) from public.payments p where p.invoice_id = inv.id), 0
    ) > 0 then 'partial'
    when inv.due_date < current_date then 'overdue'
    else 'pending'
  end as status

from public.invoices inv
join public.suppliers sup on sup.id = inv.supplier_id;

-- ============================================================
-- FUNCIÓN: Validar pago no supera saldo
-- ============================================================
create or replace function public.validate_payment()
returns trigger as $$
declare
  v_final_amount  numeric;
  v_total_paid    numeric;
  v_balance       numeric;
  v_is_rejected   boolean;
begin
  -- Verificar factura no rechazada
  select is_rejected into v_is_rejected
  from public.invoices
  where id = new.invoice_id;

  if v_is_rejected then
    raise exception 'No se puede registrar pagos en facturas rechazadas.';
  end if;

  -- Calcular final_amount
  select
    (i.net_amount - coalesce(
      (select sum((d.original_value - d.discounted_value) * d.quantity)
       from public.discount_items d where d.invoice_id = i.id), 0)
    )
  into v_final_amount
  from public.invoices i
  where i.id = new.invoice_id;

  -- Total pagado ANTES de este pago
  select coalesce(sum(amount), 0)
  into v_total_paid
  from public.payments
  where invoice_id = new.invoice_id
    and id != coalesce(new.id, uuid_nil());

  v_balance := v_final_amount - v_total_paid;

  if new.amount > v_balance + 0.01 then
    raise exception 'El pago (%) supera el saldo pendiente (%).',
      new.amount, v_balance
      using errcode = 'P0001';
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trg_validate_payment
before insert or update on public.payments
for each row execute function public.validate_payment();

-- ============================================================
-- FUNCIÓN: Verificar número de factura único (case-insensitive)
-- ============================================================
create or replace function public.validate_invoice_number()
returns trigger as $$
begin
  if exists (
    select 1 from public.invoices
    where lower(invoice_number) = lower(new.invoice_number)
      and id != coalesce(new.id, uuid_nil())
  ) then
    raise exception 'Ya existe una factura con el número %.', new.invoice_number
      using errcode = 'P0002';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_validate_invoice_number
before insert or update of invoice_number on public.invoices
for each row execute function public.validate_invoice_number();

-- ============================================================
-- FUNCIÓN: updated_at automático
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_suppliers_updated_at
before update on public.suppliers
for each row execute function public.set_updated_at();

create trigger trg_invoices_updated_at
before update on public.invoices
for each row execute function public.set_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.suppliers     enable row level security;
alter table public.invoices      enable row level security;
alter table public.discount_items enable row level security;
alter table public.payments      enable row level security;

-- Políticas temporales: acceso total para usuarios autenticados
-- (Phase 2: agregar roles y restricciones por empresa/usuario)
create policy "Authenticated full access" on public.suppliers
  for all using (auth.role() = 'authenticated');

create policy "Authenticated full access" on public.invoices
  for all using (auth.role() = 'authenticated');

create policy "Authenticated full access" on public.discount_items
  for all using (auth.role() = 'authenticated');

create policy "Authenticated full access" on public.payments
  for all using (auth.role() = 'authenticated');

-- ============================================================
-- DATOS INICIALES (seed — mismos que mock_data.dart)
-- ============================================================
insert into public.suppliers (id, name, initials, tax_id, contact_name, email, phone, category, address, website, is_active) values
  ('00000000-0000-0000-0000-000000000001', 'Tecnología Global SA',       'TG', 'TGS890123AB1', 'Carlos Méndez',   'cmendez@tecglobal.com',  '+52 55 1234 5678', 'Tecnología',  'Av. Insurgentes Sur 1234, CDMX', 'tecglobal.com',   true),
  ('00000000-0000-0000-0000-000000000002', 'Logística Express MX',       'LE', 'LEM950456CD2', 'Ana García',       'agarcia@logexpress.mx',  '+52 81 9876 5432', 'Logística',   'Blvd. Gustavo Díaz Ordaz 3000, MTY', 'logexpress.mx', true),
  ('00000000-0000-0000-0000-000000000003', 'Servicios Corporativos Plus','SC', 'SCP010789EF3', 'Roberto Jiménez', 'rjimenez@scplus.com',    '+52 33 5555 0001', 'Servicios',   'Av. López Mateos 2500, GDL', null,              true),
  ('00000000-0000-0000-0000-000000000004', 'Manufactura Norteña',        'MN', 'MNO850321GH4', 'Patricia López',  'plopez@manornorte.com',  '+52 614 222 3344', 'Manufactura', 'Parque Industrial 45, CHH',  null,              true),
  ('00000000-0000-0000-0000-000000000005', 'Diseño & Creatividad Co.',   'DC', 'DCC200567IJ5', 'Sofía Ramírez',   'sramirez@dcco.design',   '+52 55 8800 1234', 'Diseño',      null,                          null,              false);

insert into public.invoices (id, invoice_number, supplier_id, issue_date, due_date, net_amount, novedad_type, is_rejected, notes) values
  ('10000000-0000-0000-0000-000000000001', 'FAC-2025-0891', '00000000-0000-0000-0000-000000000001', '2025-10-01', '2025-11-30', 98600.00,  'ok',   false, 'Licencias software Q4 2025'),
  ('10000000-0000-0000-0000-000000000002', 'FAC-2025-0892', '00000000-0000-0000-0000-000000000002', '2025-09-05', '2025-10-05', 52432.00,  'ok',   false, null),
  ('10000000-0000-0000-0000-000000000003', 'FAC-2025-0893', '00000000-0000-0000-0000-000000000003', '2025-10-08', '2025-11-08', 103240.00, 'desc', false, 'Consultoría estratégica Oct-Nov'),
  ('10000000-0000-0000-0000-000000000004', 'FAC-2025-0880', '00000000-0000-0000-0000-000000000004', '2025-09-15', '2025-10-15', 290000.00, 'ok',   false, null),
  ('10000000-0000-0000-0000-000000000005', 'FAC-2025-0885', '00000000-0000-0000-0000-000000000001', '2025-09-20', '2025-10-20', 46400.00,  'ok',   false, null),
  ('10000000-0000-0000-0000-000000000006', 'FAC-2025-0894', '00000000-0000-0000-0000-000000000005', '2025-10-10', '2025-11-10', 24360.00,  'ok',   true,  'Rechazada — falta XML timbrado'),
  ('10000000-0000-0000-0000-000000000007', 'FAC-2025-0895', '00000000-0000-0000-0000-000000000002', '2025-10-12', '2025-11-12', 37700.00,  'ok',   false, null),
  ('10000000-0000-0000-0000-000000000008', 'FAC-2025-0896', '00000000-0000-0000-0000-000000000003', '2025-10-14', '2025-11-14', 17980.00,  'ok',   false, null);

-- Descuento para FAC-2025-0893
insert into public.discount_items (invoice_id, product, quantity, original_value, discounted_value, reason) values
  ('10000000-0000-0000-0000-000000000003', 'Consultoría Fase 1', 1, 103240.00, 89000.00, 'Descuento por volumen convenido');

-- Pagos para facturas pagadas/parciales
insert into public.payments (invoice_id, payment_date, amount, method, notes) values
  ('10000000-0000-0000-0000-000000000004', '2025-10-10', 150000.00, 'transfer', 'Primer pago acordado'),
  ('10000000-0000-0000-0000-000000000004', '2025-10-14', 140000.00, 'transfer', 'Pago final liquidación'),
  ('10000000-0000-0000-0000-000000000005', '2025-10-18',  46400.00, 'transfer', null),
  ('10000000-0000-0000-0000-000000000007', '2025-10-20',  20000.00, 'cash',     'Abono inicial');

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
select
  invoice_number,
  supplier_name,
  net_amount,
  discount_amount,
  final_amount,
  total_paid,
  balance,
  status
from public.invoice_summary
order by created_at;
