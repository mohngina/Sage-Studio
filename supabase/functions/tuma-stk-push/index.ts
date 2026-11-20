// Supabase Edge Function: tuma-stk-push
//
// Server-side Tuma STK Push initiator for Sage Select orders.
// Secrets are read ONLY from Supabase Edge Function environment variables:
//   - TUMA_EMAIL          (e.g. sagestudio.ke@gmail.com)
//   - TUMA_API_KEY        (from Tuma Merchant Portal -> Developer)
//   - TUMA_ACCOUNT_ALIAS  (optional; omit to use primary Equity Bank account)
//
// Never put TUMA_API_KEY in Flutter client code.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function normalizeKenyanPhone(raw: string): string | null {
  const digits = raw.replace(/\D/g, '');
  if (digits.startsWith('254') && digits.length === 12) return digits;
  if (digits.startsWith('0') && digits.length === 10 && (digits[1] === '7' || digits[1] === '1')) {
    return `254${digits.slice(1)}`;
  }
  if ((digits.startsWith('7') || digits.startsWith('1')) && digits.length === 9) {
    return `254${digits}`;
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const tumaEmail = Deno.env.get('TUMA_EMAIL') ?? '';
    const tumaApiKey = Deno.env.get('TUMA_API_KEY') ?? '';
    const tumaAccount = Deno.env.get('TUMA_ACCOUNT_ALIAS') ?? '';
    const webhookSecret = Deno.env.get('TUMA_WEBHOOK_SECRET') ?? '';
    const sandboxAmount = Number(Deno.env.get('TUMA_SANDBOX_AMOUNT_KSH') ?? '0');

    if (!tumaEmail || !tumaApiKey || !webhookSecret) {
      return new Response(
        JSON.stringify({ error: 'Tuma payment credentials are not configured on the server.' }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 1. Verify caller identity via their Supabase JWT
    const apiKey = req.headers.get('apikey') ?? supabaseAnonKey;
    const userClient = createClient(supabaseUrl, apiKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const orderId = String(body.order_id ?? '').trim();
    const rawPhone = String(body.phone ?? '').trim();
    const phone = normalizeKenyanPhone(rawPhone);

    if (!orderId) {
      return new Response(JSON.stringify({ error: 'Missing order_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!phone) {
      return new Response(
        JSON.stringify({ error: 'Please enter a valid Kenyan M-Pesa phone number (e.g. 0712345678 or +254712345678).' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 2. Load the trusted order total using the caller's authenticated client (enforces RLS)
    const { data: order, error: orderErr } = await userClient
      .from('orders')
      .select('id, user_id, order_ref, total_ksh, status')
      .eq('id', orderId)
      .maybeSingle();

    if (orderErr) {
      return new Response(JSON.stringify({ error: `Order lookup failed: ${orderErr.message}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!order || order.user_id !== userData.user.id) {
      return new Response(JSON.stringify({ error: `Order not found (${orderId})` }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (order.status !== 'pending_payment') {
      return new Response(JSON.stringify({ error: 'Order is no longer awaiting payment' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // 3. Authenticate with Tuma API
    const tokenResp = await fetch('https://api.tuma.co.ke/auth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: tumaEmail, api_key: tumaApiKey }),
    });
    const tokenJson = await tokenResp.json();
    const bearer = tokenJson?.data?.token;
    if (!tokenResp.ok || !bearer) {
      return new Response(
        JSON.stringify({ error: tokenJson?.message ?? 'Could not authenticate with Tuma payment gateway.' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 4. Initiate STK Push (use TUMA_SANDBOX_AMOUNT_KSH only when explicitly set for Sandbox testing)
    const callbackUrl = `${supabaseUrl}/functions/v1/tuma-callback?token=${encodeURIComponent(webhookSecret)}`;
    const chargeAmount =
      sandboxAmount > 0 && sandboxAmount < 100 ? sandboxAmount : Number(order.total_ksh);
    const stkPayload: Record<string, unknown> = {
      amount: chargeAmount,
      phone,
      callback_url: callbackUrl,
      description: `Sage Studio ${order.order_ref}`,
    };
    if (tumaAccount.trim().length > 0) {
      stkPayload.account = tumaAccount.trim();
    }

    const stkResp = await fetch('https://api.tuma.co.ke/payment/stk-push', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${bearer}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(stkPayload),
    });
    const stkJson = await stkResp.json();

    if (!stkResp.ok || stkJson?.success === false) {
      return new Response(
        JSON.stringify({ error: stkJson?.message ?? 'Could not initiate M-Pesa STK Push.' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const checkoutRequestId = String(stkJson?.data?.checkout_request_id ?? '');
    if (checkoutRequestId && serviceRoleKey) {
      try {
        await adminClient.rpc('record_tuma_stk_init', {
          p_order_id: order.id,
          p_checkout_request_id: checkoutRequestId,
        });
      } catch (_) {
        // Non-fatal if migration has not been applied yet; STK push was already sent.
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        order_id: order.id,
        order_ref: order.order_ref,
        checkout_request_id: checkoutRequestId,
        customer_message:
          stkJson?.data?.customer_message ??
          stkJson?.message ??
          'SIM toolkit prompt sent. Please enter your M-Pesa PIN on your phone.',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (_err) {
    return new Response(JSON.stringify({ error: 'Unable to initiate payment request.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
