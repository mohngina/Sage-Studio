// Supabase Edge Function: send-enquiry
//
// Dispatches project enquiry and studio order .docx emails to
// sagestudio.ke@gmail.com via Resend so static/cPanel deployments do not
// require a separate Dart backend server.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const STUDIO_EMAIL = 'sagestudio.ke@gmail.com';

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const resendKey = Deno.env.get('RESEND_API_KEY') ?? '';
    if (!resendKey) {
      return new Response(JSON.stringify({ error: 'RESEND_API_KEY is not configured.' }), {
        status: 503,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const data = await req.json();
    const fullName = String(data?.fullName ?? 'Valued Client').trim();
    const clientEmail = String(data?.email ?? '').trim();
    const clientPhone = String(data?.phone ?? '').trim();
    const serviceCategory = String(data?.serviceCategory ?? 'General Enquiry').trim();
    const message = String(data?.message ?? '').trim();
    const fileName = String(data?.fileName ?? 'Sage_Studio_Enquiry.docx').trim();
    const docxBase64 = typeof data?.docxBase64 === 'string' ? data.docxBase64 : null;
    const orderRef = String(data?.orderRef ?? '').trim();
    const isOrder = orderRef.length > 0;

    if (!fullName || !clientEmail.includes('@')) {
      return new Response(JSON.stringify({ error: 'Valid client name and email are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const emailSubject = isOrder
      ? `${serviceCategory} — ${fullName}`
      : `New Project Enquiry: ${serviceCategory} — ${fullName}`;

    const htmlBody = `
<h2>${isOrder ? 'Sage Studio Order' : 'New Project Enquiry — Sage Studio'}</h2>
<p><strong>Client Name:</strong> ${escapeHtml(fullName)}</p>
<p><strong>Client Email:</strong> ${escapeHtml(clientEmail)}</p>
<p><strong>Phone Number:</strong> ${escapeHtml(clientPhone || 'Not provided')}</p>
<p><strong>${isOrder ? 'Order' : 'Service / Category'}:</strong> ${escapeHtml(serviceCategory)}</p>
<p><strong>${isOrder ? 'Order Details' : 'Project Details / Message'}:</strong><br>${
      message ? escapeHtml(message).replace(/\n/g, '<br>') : 'No additional message provided.'
    }</p>
<hr>
<p><em>The generated Microsoft Word (.docx) ${isOrder ? 'order' : 'enquiry'} document (${escapeHtml(
      fileName,
    )}) is attached to this email.</em></p>
`;

    const resendPayload: Record<string, unknown> = {
      from: 'Sage Studio <onboarding@resend.dev>',
      to: [STUDIO_EMAIL],
      reply_to: clientEmail,
      subject: emailSubject,
      html: htmlBody,
    };

    if (docxBase64) {
      resendPayload.attachments = [{ filename: fileName, content: docxBase64 }];
    }

    const resp = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(resendPayload),
    });

    if (!resp.ok) {
      const errText = await resp.text();
      console.error('[send-enquiry] Resend error', resp.status, errText);
      return new Response(JSON.stringify({ error: 'Failed to dispatch email via Resend.' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        dispatched: true,
        fileName,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (_err) {
    return new Response(JSON.stringify({ error: 'Invalid enquiry payload.' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
