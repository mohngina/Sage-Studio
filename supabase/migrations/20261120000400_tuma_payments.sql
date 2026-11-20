-- =====================================================================
-- Tuma STK Push payment metadata & server-side helper functions
-- =====================================================================

begin;

alter table public.orders
  add column if not exists checkout_request_id text unique;

update public.store_settings
   set payments_enabled = true
 where id = 1;

-- Server-side only: records the Tuma checkout_request_id on a pending order.
create or replace function public.record_tuma_stk_init(
  p_order_id uuid,
  p_checkout_request_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.orders
     set payment_provider = 'tuma',
         checkout_request_id = p_checkout_request_id
   where id = p_order_id
     and status = 'pending_payment';
end;
$$;

revoke execute on function public.record_tuma_stk_init(uuid, text) from public, anon, authenticated;
grant execute on function public.record_tuma_stk_init(uuid, text) to service_role;

grant select, update on public.orders to service_role;

-- Server-side only: processes a Tuma payment callback by checkout_request_id
-- without requiring direct table privileges on public.orders.
create or replace function public.process_tuma_callback(
  p_checkout_request_id text,
  p_is_success boolean,
  p_receipt text,
  p_paid_amount numeric,
  p_sandbox_amount numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_verified_amount numeric;
begin
  select *
    into v_order
    from public.orders
   where checkout_request_id = p_checkout_request_id
   for update;

  if not found then
    return jsonb_build_object('found', false, 'reason', 'order not found');
  end if;

  if p_is_success then
    if p_paid_amount is null then
      raise exception 'Paid amount is required' using errcode = 'P0007';
    elsif p_sandbox_amount > 0
       and p_sandbox_amount < 100
       and p_paid_amount = p_sandbox_amount then
      v_verified_amount := v_order.total_ksh;
    else
      v_verified_amount := p_paid_amount;
    end if;

    perform public.mark_order_paid(
      v_order.id,
      'tuma',
      coalesce(nullif(trim(p_receipt), ''), p_checkout_request_id),
      v_verified_amount
    );

    return jsonb_build_object(
      'found', true,
      'order_id', v_order.id,
      'status', 'paid'
    );
  elsif v_order.status = 'pending_payment' then
    update public.orders
       set status = 'failed'
     where id = v_order.id
       and status = 'pending_payment';

    return jsonb_build_object(
      'found', true,
      'order_id', v_order.id,
      'status', 'failed'
    );
  end if;

  return jsonb_build_object(
    'found', true,
    'order_id', v_order.id,
    'status', v_order.status
  );
end;
$$;

revoke execute on function public.process_tuma_callback(text, boolean, text, numeric, numeric) from public, anon, authenticated;
grant execute on function public.process_tuma_callback(text, boolean, text, numeric, numeric) to service_role;

commit;
