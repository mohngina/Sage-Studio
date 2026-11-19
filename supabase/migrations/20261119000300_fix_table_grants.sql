-- =====================================================================
-- Explicit table & column GRANT privileges for anon and authenticated roles.
--
-- Row Level Security (RLS) controls WHICH rows a role can see or modify,
-- while PostgreSQL GRANT statements allow PostgREST to access the tables.
-- Run this in the Supabase SQL Editor if you saw "permission denied for table".
-- =====================================================================

begin;

grant usage on schema public to anon, authenticated;

-- 1. Catalogue & store settings (publicly readable)
grant select on public.catalogue_products to anon, authenticated;
grant select on public.store_settings to anon, authenticated;

-- 2. Profiles (authenticated customers read/insert/update own profile; never `role`)
grant select on public.profiles to authenticated;
grant insert (id, full_name, phone, address_line1, address_line2, city, region, postal_code, country, avatar_path)
  on public.profiles to authenticated;
grant update (full_name, phone, address_line1, address_line2, city, region, postal_code, country, avatar_path)
  on public.profiles to authenticated;

-- 3. Favourites (authenticated customers read/insert/delete own saved products)
grant select, insert, delete on public.favourites to authenticated;

-- 4. Cart items (authenticated customers read/insert/update/delete own cart lines)
grant select, insert, delete on public.cart_items to authenticated;
grant update (product_id, variant, quantity) on public.cart_items to authenticated;

-- 5. Orders & order items (read-only via RLS; writes happen via create_pending_order RPC)
grant select on public.orders to authenticated;
grant select on public.order_items to authenticated;

-- 6. Reviews & stats view
grant select (id, product_id, rating, title, body, reviewer_name, verified_purchase, created_at, moderation_status)
  on public.reviews to anon;
grant select, delete on public.reviews to authenticated;
grant insert (user_id, product_id, rating, title, body, reviewer_name) on public.reviews to authenticated;
grant update (rating, title, body, reviewer_name, moderation_status) on public.reviews to authenticated;
grant select on public.product_review_stats to anon, authenticated;

commit;
