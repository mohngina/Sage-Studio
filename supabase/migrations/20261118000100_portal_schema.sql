-- =====================================================================
-- Sage Studio client portal schema
-- Profiles, favourites, carts, reviews, orders + RLS + avatar storage.
--
-- Security model
--  * RLS is enabled on every table; anything not explicitly granted is denied.
--  * Customers can only see/modify their own private rows.
--  * Trusted fields (roles, prices, order totals, payment status, review
--    moderation) are NOT writable by customers: column privileges are
--    restricted and triggers enforce the rules even if a policy is loosened.
--  * Orders are only created through public.create_pending_order(), which
--    recalculates totals from public.catalogue_products. Orders can only be
--    marked paid via public.mark_order_paid(), executable by service_role
--    (i.e. a server-side payment webhook / Edge Function), never by browsers.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- Catalogue price list (server-side mirror of lib/data/product_data.dart)
-- Seeded by the generated migration 20261118000200_catalogue_seed.sql.
-- ---------------------------------------------------------------------
create table if not exists public.catalogue_products (
  product_id            text primary key check (product_id ~ '^[a-z0-9-]{3,64}$'),
  code                  text not null,
  title                 text not null,
  subtitle              text not null default '',
  clan                  text not null default '',
  image_path            text not null default '',
  price_ksh             numeric(12,2) not null check (price_ksh >= 0),
  cover_only_price_ksh  numeric(12,2) check (cover_only_price_ksh is null or cover_only_price_ksh >= 0),
  price_label           text,
  active                boolean not null default true,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger catalogue_products_updated_at
  before update on public.catalogue_products
  for each row execute function public.set_updated_at();

alter table public.catalogue_products enable row level security;

-- Public, read-only reference data (the same prices are already public on the site).
create policy "catalogue is publicly readable"
  on public.catalogue_products for select
  to anon, authenticated
  using (true);

revoke insert, update, delete on public.catalogue_products from anon, authenticated;

-- Unit price for a product + variant, or null if unavailable.
create or replace function public.catalogue_unit_price(p_product_id text, p_variant text)
returns numeric
language sql
stable
set search_path = ''
as $$
  select case
    when p_variant = 'cover-only' then c.cover_only_price_ksh
    when p_variant = 'cover-insert' and c.cover_only_price_ksh is not null then c.price_ksh
    when p_variant = 'standard' and c.cover_only_price_ksh is null then c.price_ksh
    else null
  end
  from public.catalogue_products c
  where c.product_id = p_product_id and c.active;
$$;

-- ---------------------------------------------------------------------
-- Store settings (delivery fee etc.). NULL means "not configured" — the
-- checkout then states that delivery is confirmed by the studio and does
-- not invent a value.
-- ---------------------------------------------------------------------
create table if not exists public.store_settings (
  id                 smallint primary key default 1 check (id = 1),
  currency           text not null default 'KES',
  delivery_fee_ksh   numeric(12,2) check (delivery_fee_ksh is null or delivery_fee_ksh >= 0),
  payments_enabled   boolean not null default false,
  updated_at         timestamptz not null default now()
);

insert into public.store_settings (id) values (1) on conflict (id) do nothing;

create trigger store_settings_updated_at
  before update on public.store_settings
  for each row execute function public.set_updated_at();

alter table public.store_settings enable row level security;

create policy "store settings are publicly readable"
  on public.store_settings for select
  to anon, authenticated
  using (true);

revoke insert, update, delete on public.store_settings from anon, authenticated;

-- ---------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  full_name      text check (full_name is null or char_length(full_name) <= 100),
  phone          text check (phone is null or phone ~ '^\+?[0-9 ()\-]{7,20}$'),
  address_line1  text check (address_line1 is null or char_length(address_line1) <= 200),
  address_line2  text check (address_line2 is null or char_length(address_line2) <= 200),
  city           text check (city is null or char_length(city) <= 100),
  region         text check (region is null or char_length(region) <= 100),
  postal_code    text check (postal_code is null or char_length(postal_code) <= 20),
  country        text check (country is null or char_length(country) <= 100),
  avatar_path    text check (avatar_path is null or char_length(avatar_path) <= 300),
  role           text not null default 'customer' check (role in ('customer', 'admin')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create policy "users read own profile"
  on public.profiles for select
  to authenticated
  using (id = (select auth.uid()));

create policy "users insert own profile"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy "users update own profile"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Customers may only write their own editable fields — never `role`.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant insert (id, full_name, phone, address_line1, address_line2, city, region, postal_code, country, avatar_path)
  on public.profiles to authenticated;
grant update (full_name, phone, address_line1, address_line2, city, region, postal_code, country, avatar_path)
  on public.profiles to authenticated;

-- Auto-create a profile when a user registers (email or Google).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    nullif(left(coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''), 100), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Favourites (references the existing catalogue by product id only)
-- ---------------------------------------------------------------------
create table if not exists public.favourites (
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id  text not null references public.catalogue_products (product_id) on update cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, product_id)
);

alter table public.favourites enable row level security;

create policy "users read own favourites"
  on public.favourites for select to authenticated
  using (user_id = (select auth.uid()));

create policy "users add own favourites"
  on public.favourites for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "users remove own favourites"
  on public.favourites for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.favourites from anon;
revoke update on public.favourites from authenticated;

-- ---------------------------------------------------------------------
-- Cart
-- ---------------------------------------------------------------------
create table if not exists public.cart_items (
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id  text not null references public.catalogue_products (product_id) on update cascade,
  variant     text not null default 'standard' check (variant in ('standard', 'cover-insert', 'cover-only')),
  quantity    integer not null check (quantity between 1 and 99),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (user_id, product_id, variant)
);

create trigger cart_items_updated_at
  before update on public.cart_items
  for each row execute function public.set_updated_at();

alter table public.cart_items enable row level security;

create policy "users read own cart"
  on public.cart_items for select to authenticated
  using (user_id = (select auth.uid()));

create policy "users add to own cart"
  on public.cart_items for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "users update own cart"
  on public.cart_items for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "users delete from own cart"
  on public.cart_items for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.cart_items from anon;
revoke update on public.cart_items from authenticated;
-- product_id/variant are included because PostgREST upserts SET every payload
-- column; ownership (user_id) can never be changed by the client.
grant update (product_id, variant, quantity) on public.cart_items to authenticated;

-- ---------------------------------------------------------------------
-- Orders (created only via create_pending_order; paid only via mark_order_paid)
-- ---------------------------------------------------------------------
create table if not exists public.orders (
  id                 uuid primary key default gen_random_uuid(),
  order_ref          text not null unique
                     default ('SS-' || to_char(now(), 'YYMMDD') || '-' ||
                              upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6))),
  user_id            uuid not null references auth.users (id) on delete restrict,
  status             text not null default 'pending_payment'
                     check (status in ('pending_payment', 'paid', 'failed', 'cancelled', 'fulfilled')),
  currency           text not null default 'KES',
  subtotal_ksh       numeric(12,2) not null check (subtotal_ksh >= 0),
  delivery_fee_ksh   numeric(12,2) check (delivery_fee_ksh is null or delivery_fee_ksh >= 0),
  total_ksh          numeric(12,2) not null check (total_ksh >= 0),
  contact_name       text not null check (char_length(contact_name) between 2 and 100),
  contact_email      text not null check (char_length(contact_email) between 3 and 254),
  contact_phone      text not null check (contact_phone ~ '^\+?[0-9 ()\-]{7,20}$'),
  delivery_address   jsonb not null,
  notes              text check (notes is null or char_length(notes) <= 1000),
  payment_provider   text,
  payment_reference  text unique,
  paid_at            timestamptz,
  idempotency_key    uuid not null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create index if not exists orders_user_created_idx on public.orders (user_id, created_at desc);

create trigger orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

create table if not exists public.order_items (
  id                 uuid primary key default gen_random_uuid(),
  order_id           uuid not null references public.orders (id) on delete cascade,
  product_id         text not null references public.catalogue_products (product_id) on update cascade,
  variant            text not null,
  product_code       text not null,
  title              text not null,
  subtitle           text not null,
  image_path         text not null,
  unit_price_ksh     numeric(12,2) not null check (unit_price_ksh >= 0),
  quantity           integer not null check (quantity between 1 and 99),
  line_total_ksh     numeric(12,2) not null check (line_total_ksh >= 0)
);

create index if not exists order_items_order_idx on public.order_items (order_id);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "users read own orders"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()));

create policy "admins read all orders"
  on public.orders for select to authenticated
  using ((select public.is_admin()));

create policy "users read own order items"
  on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = (select auth.uid())));

create policy "admins read all order items"
  on public.order_items for select to authenticated
  using ((select public.is_admin()));

-- No direct writes from browsers at all.
revoke insert, update, delete on public.orders from anon, authenticated;
revoke insert, update, delete on public.order_items from anon, authenticated;
revoke all on public.orders from anon;
revoke all on public.order_items from anon;

-- Creates a PENDING order from the caller's server-side cart.
-- Totals come from catalogue_products, never from the client. Idempotent per
-- (user, idempotency key) so double clicks / retries return the same order.
-- This does NOT collect or record payment.
create or replace function public.create_pending_order(
  p_idempotency_key uuid,
  p_contact_name text,
  p_contact_email text,
  p_contact_phone text,
  p_delivery_address jsonb,
  p_notes text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_existing public.orders;
  v_order public.orders;
  v_subtotal numeric(12,2);
  v_fee numeric(12,2);
  v_missing int;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_idempotency_key is null then
    raise exception 'Missing idempotency key' using errcode = '22023';
  end if;

  select * into v_existing from public.orders
  where user_id = v_uid and idempotency_key = p_idempotency_key;
  if found then
    return v_existing;
  end if;

  if jsonb_typeof(p_delivery_address) is distinct from 'object'
     or coalesce(btrim(p_delivery_address ->> 'line1'), '') = ''
     or coalesce(btrim(p_delivery_address ->> 'city'), '') = '' then
    raise exception 'Delivery address line 1 and city are required' using errcode = '22023';
  end if;

  if not exists (select 1 from public.cart_items where user_id = v_uid) then
    raise exception 'Your cart is empty' using errcode = 'P0001';
  end if;

  select count(*) into v_missing
  from public.cart_items ci
  where ci.user_id = v_uid and public.catalogue_unit_price(ci.product_id, ci.variant) is null;
  if v_missing > 0 then
    raise exception 'Some items in your cart are no longer available' using errcode = 'P0002';
  end if;

  select coalesce(sum(public.catalogue_unit_price(ci.product_id, ci.variant) * ci.quantity), 0)
    into v_subtotal
  from public.cart_items ci where ci.user_id = v_uid;

  select delivery_fee_ksh into v_fee from public.store_settings where id = 1;

  insert into public.orders (
    user_id, subtotal_ksh, delivery_fee_ksh, total_ksh,
    contact_name, contact_email, contact_phone, delivery_address, notes, idempotency_key
  ) values (
    v_uid, v_subtotal, v_fee, v_subtotal + coalesce(v_fee, 0),
    btrim(p_contact_name), lower(btrim(p_contact_email)), btrim(p_contact_phone),
    p_delivery_address, nullif(btrim(coalesce(p_notes, '')), ''), p_idempotency_key
  )
  returning * into v_order;

  insert into public.order_items (
    order_id, product_id, variant, product_code, title, subtitle, image_path,
    unit_price_ksh, quantity, line_total_ksh
  )
  select v_order.id, c.product_id, ci.variant, c.code, c.title,
         c.subtitle || case ci.variant when 'cover-only' then ' (Cover only)'
                                       when 'cover-insert' then ' (Cover & Insert)' else '' end,
         c.image_path,
         public.catalogue_unit_price(ci.product_id, ci.variant),
         ci.quantity,
         public.catalogue_unit_price(ci.product_id, ci.variant) * ci.quantity
  from public.cart_items ci
  join public.catalogue_products c on c.product_id = ci.product_id
  where ci.user_id = v_uid;

  delete from public.cart_items where user_id = v_uid;

  return v_order;
end;
$$;

revoke execute on function public.create_pending_order(uuid, text, text, text, jsonb, text) from public, anon;
grant execute on function public.create_pending_order(uuid, text, text, text, jsonb, text) to authenticated;

-- Customers may cancel their own order only while it is still pending payment.
create or replace function public.cancel_pending_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
begin
  update public.orders
     set status = 'cancelled'
   where id = p_order_id and user_id = auth.uid() and status = 'pending_payment'
  returning * into v_order;
  if not found then
    raise exception 'Order cannot be cancelled' using errcode = 'P0003';
  end if;
  return v_order;
end;
$$;

revoke execute on function public.cancel_pending_order(uuid) from public, anon;
grant execute on function public.cancel_pending_order(uuid) to authenticated;

-- Server-side only: called by a payment webhook / Edge Function AFTER the
-- provider has verified the payment. Idempotent on payment_reference and
-- verifies the paid amount matches the trusted order total.
create or replace function public.mark_order_paid(
  p_order_id uuid,
  p_provider text,
  p_payment_reference text,
  p_amount_ksh numeric
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found' using errcode = 'P0004';
  end if;
  if v_order.status = 'paid' then
    if v_order.payment_reference = p_payment_reference then
      return v_order; -- duplicate callback: no-op
    end if;
    raise exception 'Order already paid with a different reference' using errcode = 'P0005';
  end if;
  if v_order.status <> 'pending_payment' then
    raise exception 'Order is not awaiting payment' using errcode = 'P0006';
  end if;
  if p_amount_ksh is distinct from v_order.total_ksh then
    raise exception 'Paid amount does not match order total' using errcode = 'P0007';
  end if;
  update public.orders
     set status = 'paid', payment_provider = p_provider,
         payment_reference = p_payment_reference, paid_at = now()
   where id = p_order_id
  returning * into v_order;
  return v_order;
end;
$$;

revoke execute on function public.mark_order_paid(uuid, text, text, numeric) from public, anon, authenticated;
grant execute on function public.mark_order_paid(uuid, text, text, numeric) to service_role;

-- ---------------------------------------------------------------------
-- Reviews (moderated; only approved reviews are public)
-- ---------------------------------------------------------------------
create table if not exists public.reviews (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id         text not null references public.catalogue_products (product_id) on update cascade,
  rating             smallint not null check (rating between 1 and 5),
  title              text check (title is null or char_length(title) <= 120),
  body               text not null check (char_length(btrim(body)) between 10 and 2000),
  reviewer_name      text not null check (char_length(btrim(reviewer_name)) between 1 and 100),
  moderation_status  text not null default 'pending' check (moderation_status in ('pending', 'approved', 'rejected')),
  moderated_at       timestamptz,
  verified_purchase  boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (user_id, product_id)
);

create index if not exists reviews_public_idx on public.reviews (moderation_status, created_at desc);
create index if not exists reviews_product_idx on public.reviews (product_id, moderation_status);

create trigger reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

-- Enforce moderation rules regardless of grants/policies:
--  * new reviews always start pending; verified_purchase is computed here
--  * only admins (or server-side roles with no auth.uid()) may change moderation
--  * when an author edits content, the review returns to pending
create or replace function public.reviews_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_admin boolean := coalesce(public.is_admin(), false);
  v_server boolean := auth.uid() is null;
begin
  if tg_op = 'INSERT' then
    if not v_server then
      new.moderation_status := 'pending';
      new.moderated_at := null;
    end if;
    new.verified_purchase := exists (
      select 1 from public.orders o
      join public.order_items oi on oi.order_id = o.id
      where o.user_id = new.user_id and oi.product_id = new.product_id and o.status in ('paid', 'fulfilled')
    );
    return new;
  end if;

  if new.user_id <> old.user_id or new.product_id <> old.product_id then
    raise exception 'Review owner and product cannot change' using errcode = '42501';
  end if;
  new.verified_purchase := old.verified_purchase;

  if new.moderation_status is distinct from old.moderation_status then
    if not (v_is_admin or v_server) then
      raise exception 'Only administrators can moderate reviews' using errcode = '42501';
    end if;
    new.moderated_at := now();
  elsif not (v_is_admin or v_server)
        and (new.rating, new.title, new.body, new.reviewer_name)
            is distinct from (old.rating, old.title, old.body, old.reviewer_name) then
    new.moderation_status := 'pending';
    new.moderated_at := null;
  end if;
  return new;
end;
$$;

create trigger reviews_guard
  before insert or update on public.reviews
  for each row execute function public.reviews_guard();

alter table public.reviews enable row level security;

create policy "approved reviews are public"
  on public.reviews for select
  to anon, authenticated
  using (moderation_status = 'approved');

create policy "authors read own reviews"
  on public.reviews for select to authenticated
  using (user_id = (select auth.uid()));

create policy "admins read all reviews"
  on public.reviews for select to authenticated
  using ((select public.is_admin()));

create policy "authors create own reviews"
  on public.reviews for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "authors edit own reviews"
  on public.reviews for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "admins moderate reviews"
  on public.reviews for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "authors delete own reviews"
  on public.reviews for delete to authenticated
  using (user_id = (select auth.uid()));

-- Anonymous visitors only see display-safe columns (no user_id).
revoke all on public.reviews from anon;
grant select (id, product_id, rating, title, body, reviewer_name, verified_purchase, created_at, moderation_status)
  on public.reviews to anon;

revoke insert, update on public.reviews from authenticated;
grant select, delete on public.reviews to authenticated;
grant insert (user_id, product_id, rating, title, body, reviewer_name) on public.reviews to authenticated;
grant update (rating, title, body, reviewer_name, moderation_status) on public.reviews to authenticated;

-- Explicit table SELECT/INSERT/DELETE grants for PostgREST roles (RLS enforces row ownership)
grant usage on schema public to anon, authenticated;
grant select on public.catalogue_products to anon, authenticated;
grant select on public.store_settings to anon, authenticated;
grant select on public.profiles to authenticated;
grant select, insert, delete on public.favourites to authenticated;
grant select, insert, delete on public.cart_items to authenticated;
grant select on public.orders to authenticated;
grant select on public.order_items to authenticated;

-- Aggregates for approved reviews only (no customer data).
create or replace view public.product_review_stats
with (security_invoker = true) as
  select product_id, count(*)::int as review_count, round(avg(rating)::numeric, 1) as average_rating
  from public.reviews
  where moderation_status = 'approved'
  group by product_id;

grant select on public.product_review_stats to anon, authenticated;

-- ---------------------------------------------------------------------
-- Storage: private avatars bucket, each user limited to avatars/<uid>/...
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "users read own avatar"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "users upload own avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "users update own avatar"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "users delete own avatar"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

commit;
