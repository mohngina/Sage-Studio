// Supabase Edge Function: create-order
//
// Server-side entrypoint for creating a pending order or verifying a payment
// callback once a payment provider is selected.
//
// Security rules enforced:
//  1. Never trusts prices or totals supplied by the browser; calls the
//     PostgreSQL RPC `public.create_pending_order` as the authenticated user
//     so Row Level Security and `catalogue_products` prices are enforced.
//  2. Never marks an order paid on creation. Orders are created with status
//     `pending_payment` until a verified server-side payment webhook calls
//     `public.mark_order_paid` with the service-role client.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    const client = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const body = await req.json();
    const { data, error } = await client.rpc('create_pending_order', {
      p_idempotency_key: body.idempotency_key,
      p_contact_name: body.contact_name,
      p_contact_email: body.contact_email,
      p_contact_phone: body.contact_phone,
      p_delivery_address: body.delivery_address,
      p_notes: body.notes ?? null,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message, code: error.code }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({
        order: data,
        payment_collected: false,
        notice:
          'Order recorded with status pending_payment. No payment provider is configured yet; order will move to paid history only after server-verified payment.',
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (_err) {
    return new Response(JSON.stringify({ error: 'Unable to process order request' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
