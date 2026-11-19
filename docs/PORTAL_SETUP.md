# Sage Studio Client Portal & E-Commerce Setup Guide

This guide walks through setting up the Sage Studio Supabase project, applying the database migrations and Row Level Security (RLS) policies, configuring Google OAuth, and running the Flutter web app.

---

## 1. Create the Supabase Project

1. Sign in to [https://supabase.com/dashboard](https://supabase.com/dashboard) with a Sage Studio-owned account.
2. Create an organisation (e.g. **Sage Studio**) and a new project (e.g. **sage-studio-prod**), selecting a strong database password and the closest region.
3. Once provisioned, open **Project Settings → API** and note:
   - **Project URL** (`https://<project-ref>.supabase.co`)
   - **Publishable / `anon` public key**
   > **Security rule:** Never copy the `service_role` / `sb_secret_...` key into Flutter code, `--dart-define`, or public files. The Flutter app includes a guard (`SupabaseConfig.isForbiddenKey`) that actively refuses secret keys.

---

## 2. Apply Database Schema, Catalogue Seed & RLS Policies

In the Supabase Dashboard, open **SQL Editor → New Query** and run the two migration files in order (or run `supabase db push` via the Supabase CLI):

1. [`supabase/migrations/20261118000100_portal_schema.sql`](../supabase/migrations/20261118000100_portal_schema.sql)
   - Creates `catalogue_products`, `store_settings`, `profiles`, `favourites`, `cart_items`, `orders`, `order_items`, `reviews`, and `product_review_stats`.
   - Enables Row Level Security (RLS) on every table with deny-by-default policies.
   - Creates the `on_auth_user_created` trigger so every newly registered user gets a `profiles` row automatically.
   - Creates the private `avatars` Storage bucket (2 MB max, JPG/PNG/WEBP) with per-user folder policies (`avatars/<uid>/...`).
   - Defines `create_pending_order`, `cancel_pending_order`, and `mark_order_paid` (`service_role` only).
2. [`supabase/migrations/20261118000200_catalogue_seed.sql`](../supabase/migrations/20261118000200_catalogue_seed.sql)
   - Generated automatically from `lib/data/product_data.dart` via `dart run tool/export_catalogue_sql.dart` (all 55 existing products and prices).
3. *(Optional verification)* Run [`supabase/tests/rls_tests.sql`](../supabase/tests/rls_tests.sql) in the SQL Editor to verify that one user cannot read or modify another user's profile, cart, favourites, orders, or pending reviews.

---

## 3. Configure Authentication & Google Sign-In

1. In Supabase Dashboard → **Authentication → URL Configuration**:
   - Set **Site URL** to your production domain (or `http://localhost:5000` during local testing).
   - Add your local and production origins to **Redirect URLs** (e.g. `http://localhost:5000/**`, `https://sagestudio.co.ke/**`).
2. In **Authentication → Providers → Email**:
   - Keep **Enable Email provider** turned on.
3. In **Authentication → Providers → Google**:
   - Create an OAuth 2.0 Web Client ID in Google Cloud Console (`APIs & Services → Credentials`).
   - Add `https://<project-ref>.supabase.co/auth/v1/callback` as an **Authorized redirect URI** in Google Cloud Console.
   - Paste the Google **Client ID** and **Client Secret** into the Supabase Google Provider settings and save.

---

## 4. Running & Building the Flutter Web App

Pass the Supabase URL and publishable/anon key via `--dart-define`:

```bash
# Run locally in Chrome on port 5000
flutter run -d chrome --web-port=5000 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-or-publishable-key>

# Build for production
flutter build web \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-or-publishable-key>
```

If `--dart-define` values are omitted, the public website continues to work and the Client Portal displays a graceful notice.

---

## 5. Moderating Reviews & Managing Store Settings

- **Approving customer reviews:** Every new or edited customer review is saved with `moderation_status = 'pending'`. To approve a review so it appears on the product page and homepage:
  - In the Supabase Table Editor (`public.reviews`), change `moderation_status` from `pending` to `approved`, **or**
  - Promote a staff account to admin via the SQL Editor:
    ```sql
    update public.profiles set role = 'admin' where id = '<staff-user-uuid>';
    ```
- **Delivery fee configuration:** `public.store_settings` has `delivery_fee_ksh = null` by default (checkout displays *"Confirmed by studio"* and never invents a fee). To set a flat delivery fee in KSH:
  ```sql
  update public.store_settings set delivery_fee_ksh = 2500.00 where id = 1;
  ```
- **Completing an order after payment verification:** Until a live payment provider is connected, checkout creates orders with `status = 'pending_payment'`. Once payment is verified server-side, call:
  ```sql
  select public.mark_order_paid('<order-uuid>', 'manual_verified', '<receipt-ref>', <amount_ksh>);
  ```
  The order will then move to the customer's **History** tab.
