-- =====================================================================
-- Row Level Security (RLS) verification script for Sage Studio
--
-- Run in a transaction against a local or staging Supabase database after
-- applying 20261118000100_portal_schema.sql and 20261118000200_catalogue_seed.sql.
-- Rolls back at the end so no test fixtures remain.
-- =====================================================================

begin;

do $$
declare
  v_user_a uuid := '00000000-0000-4000-8000-0000000000a1';
  v_user_b uuid := '00000000-0000-4000-8000-0000000000b2';
  v_count  int;
  v_order  public.orders;
begin
  -- Create two test users in auth.users (triggers handle_new_user -> profiles)
  insert into auth.users (id, email, raw_user_meta_data)
  values
    (v_user_a, 'amina.test@sagestudio.local', '{"full_name":"Amina Test"}'::jsonb),
    (v_user_b, 'brian.test@sagestudio.local', '{"full_name":"Brian Test"}'::jsonb)
  on conflict (id) do nothing;

  -- Act as User A
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  -- 1. User A can read own profile but NOT User B's profile
  select count(*) into v_count from public.profiles where id = v_user_b;
  if v_count <> 0 then
    raise exception 'RLS FAILURE: User A read User B profile';
  end if;

  -- 2. User A saves a favourite and cart item
  insert into public.favourites (product_id) values ('ss-bos-002');
  insert into public.cart_items (product_id, variant, quantity) values ('ss-bos-002', 'standard', 1);

  -- 3. User A submits a review -> trigger must force moderation_status = 'pending'
  insert into public.reviews (product_id, rating, title, body, reviewer_name)
  values ('ss-bos-002', 5, 'Loved it', 'Craftsmanship and comfort are outstanding.', 'Amina');

  select count(*) into v_count from public.reviews
  where user_id = v_user_a and moderation_status = 'pending';
  if v_count <> 1 then
    raise exception 'RLS FAILURE: New review did not default to pending';
  end if;

  -- 4. User A creates a pending order -> status must be pending_payment, total from catalogue (111360)
  v_order := public.create_pending_order(
    '11111111-1111-4111-8111-111111111111'::uuid,
    'Amina Test',
    'amina.test@sagestudio.local',
    '+254 700 000001',
    '{"line1":"Karen Rd","city":"Nairobi","country":"Kenya"}'::jsonb,
    'Test pending order'
  );
  if v_order.status <> 'pending_payment' or v_order.total_ksh <> 111360.00 then
    raise exception 'ORDER FAILURE: Unexpected order status (%) or total (%)', v_order.status, v_order.total_ksh;
  end if;

  -- Switch to User B
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', v_user_b::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  -- 5. User B cannot see User A's favourites, cart, orders, or unapproved review
  select count(*) into v_count from public.favourites where user_id = v_user_a;
  if v_count <> 0 then raise exception 'RLS FAILURE: User B read User A favourites'; end if;

  select count(*) into v_count from public.cart_items where user_id = v_user_a;
  if v_count <> 0 then raise exception 'RLS FAILURE: User B read User A cart'; end if;

  select count(*) into v_count from public.orders where user_id = v_user_a;
  if v_count <> 0 then raise exception 'RLS FAILURE: User B read User A orders'; end if;

  select count(*) into v_count from public.reviews where user_id = v_user_a;
  if v_count <> 0 then raise exception 'RLS FAILURE: User B read User A unapproved review'; end if;

  execute 'reset role';
  raise notice 'ALL RLS & ORDER INTEGRITY CHECKS PASSED';
end;
$$;

rollback;
