-- ============================================================
-- KLICHE — Funciones para reportes y estadísticas
-- ============================================================

-- ── Dashboard stats ──────────────────────────────────────────
create or replace function public.get_dashboard_stats()
returns json as $$
  select json_build_object(
    'total_payable',
      (select coalesce(sum(balance), 0) from public.invoice_summary where balance > 0.01),
    'total_overdue',
      (select coalesce(sum(balance), 0) from public.invoice_summary where status = 'overdue'),
    'paid_this_month',
      (select coalesce(sum(amount), 0)
       from public.payments
       where date_trunc('month', payment_date) = date_trunc('month', current_date)),
    'pending_count',
      (select count(*) from public.invoice_summary where status = 'pending'),
    'overdue_count',
      (select count(*) from public.invoice_summary where status = 'overdue'),
    'partial_count',
      (select count(*) from public.invoice_summary where status = 'partial')
  );
$$ language sql stable;

-- ── Resumen por proveedor ────────────────────────────────────
create or replace function public.get_supplier_summary()
returns table (
  supplier_id    uuid,
  supplier_name  text,
  total_invoices bigint,
  total_amount   numeric,
  total_paid     numeric,
  pending_amount numeric,
  overdue_amount numeric
) as $$
  select
    s.id,
    s.name,
    count(inv.id),
    coalesce(sum(inv.final_amount), 0),
    coalesce(sum(inv.total_paid), 0),
    coalesce(sum(case when inv.status in ('pending','partial') then inv.balance else 0 end), 0),
    coalesce(sum(case when inv.status = 'overdue' then inv.balance else 0 end), 0)
  from public.suppliers s
  left join public.invoice_summary inv on inv.supplier_id = s.id
  group by s.id, s.name
  order by coalesce(sum(case when inv.status in ('pending','partial') then inv.balance else 0 end), 0) desc;
$$ language sql stable;

-- ── Flujo mensual (últimos 6 meses) ─────────────────────────
create or replace function public.get_monthly_flow(months_back int default 6)
returns table (
  month_label  text,
  month_date   date,
  paid         numeric,
  pending      numeric,
  overdue      numeric
) as $$
  with months as (
    select generate_series(
      date_trunc('month', current_date - (months_back - 1 || ' months')::interval),
      date_trunc('month', current_date),
      '1 month'::interval
    )::date as month_date
  )
  select
    to_char(m.month_date, 'Mon') as month_label,
    m.month_date,
    coalesce((
      select sum(p.amount)
      from public.payments p
      where date_trunc('month', p.payment_date) = m.month_date
    ), 0) as paid,
    coalesce((
      select sum(inv.balance)
      from public.invoice_summary inv
      where date_trunc('month', inv.issue_date::date) = m.month_date
        and inv.status in ('pending', 'partial')
    ), 0) as pending,
    coalesce((
      select sum(inv.balance)
      from public.invoice_summary inv
      where date_trunc('month', inv.issue_date::date) = m.month_date
        and inv.status = 'overdue'
    ), 0) as overdue
  from months m
  order by m.month_date;
$$ language sql stable;

-- ── Distribución por categoría ───────────────────────────────
create or replace function public.get_category_breakdown()
returns table (
  category    text,
  amount      numeric,
  percentage  numeric,
  count       bigint
) as $$
  with totals as (
    select coalesce(sum(final_amount), 1) as grand_total
    from public.invoice_summary
    where status != 'rejected'
  )
  select
    sup.category,
    sum(inv.final_amount) as amount,
    round(sum(inv.final_amount) / t.grand_total * 100, 2) as percentage,
    count(inv.id)
  from public.invoice_summary inv
  join public.suppliers sup on sup.id = inv.supplier_id
  cross join totals t
  where inv.status != 'rejected'
  group by sup.category, t.grand_total
  order by amount desc;
$$ language sql stable;
