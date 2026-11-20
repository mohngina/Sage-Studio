// Supabase Edge Function: tuma-callback
//
// Receives asynchronous payment outcome webhooks from Tuma (`api.tuma.co.ke`)
// and marks the matching order paid ONLY on verified success.
// Idempotent: duplicate callbacks for the same checkout_request_id / receipt
// are safely ignored by `public.mark_order_paid`.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

function constantTimeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) {
    diff |= ab[i] ^ bb[i];
  }
  return diff === 0;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const webhookSecret = Deno.env.get('TUMA_WEBHOOK_SECRET') ?? '';
  if (!webhookSecret) {
    return new Response(JSON.stringify({ error: 'Webhook verification is not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const url = new URL(req.url);
  const queryToken = url.searchParams.get('token') ?? '';
  const headerToken = req.headers.get('x-tuma-webhook-secret') ?? '';
  const providedToken = headerToken || queryToken;
  if (!providedToken || !constantTimeEqual(providedToken, webhookSecret)) {
    return new Response(JSON.stringify({ error: 'Unauthorized webhook request' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const payload = await req.json();
    const stkCallback = payload?.Body?.stkCallback;
    const data = stkCallback ?? payload?.data ?? payload;

    const checkoutRequestId = String(
      data?.checkout_request_id ??
        data?.CheckoutRequestID ??
        payload?.checkout_request_id ??
        payload?.CheckoutRequestID ??
        '',
    ).trim();
    console.log('[tuma-callback] received', { checkoutRequestId, keys: Object.keys(payload ?? {}) });
    if (!checkoutRequestId) {
      return new Response(JSON.stringify({ received: true, ignored: 'missing checkout_request_id' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const rawStatus = String(data?.status ?? payload?.status ?? payload?.event ?? '').toLowerCase();
    const resultCode = data?.result_code ?? data?.ResultCode ?? payload?.result_code ?? payload?.ResultCode;
    const isSuccess =
      resultCode === 0 ||
      resultCode === '0' ||
      rawStatus === 'completed' ||
      rawStatus === 'success' ||
      rawStatus === 'paid' ||
      rawStatus === 'payment.success';

    const receipt = String(
      data?.mpesa_receipt_number ?? data?.MpesaReceiptNumber ?? data?.reference ?? checkoutRequestId,
    ).trim();
    const rawAmount = data?.amount ?? data?.Amount ?? payload?.amount;
    const parsedAmount = rawAmount !== undefined && rawAmount !== null ? Number(rawAmount) : null;
    const paidAmount = parsedAmount !== null && Number.isFinite(parsedAmount) ? parsedAmount : null;
    if (isSuccess && paidAmount === null) {
      return new Response(JSON.stringify({ error: 'Missing or invalid paid amount' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    const sandboxAmount = Number(Deno.env.get('TUMA_SANDBOX_AMOUNT_KSH') ?? '0');

    const { data: rpcResult, error: rpcErr } = await adminClient.rpc('process_tuma_callback', {
      p_checkout_request_id: checkoutRequestId,
      p_is_success: isSuccess,
      p_receipt: receipt,
      p_paid_amount: paidAmount,
      p_sandbox_amount: Number.isFinite(sandboxAmount) ? sandboxAmount : 0,
    });

    if (rpcErr) {
      console.error('[tuma-callback] process_tuma_callback failed', rpcErr.message);
    } else {
      console.log('[tuma-callback] processed', checkoutRequestId, rpcResult);
    }

    return new Response(JSON.stringify({ received: true, result: rpcResult ?? null }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (_err) {
    return new Response(JSON.stringify({ error: 'Invalid callback payload' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
