/// <reference lib="deno.ns" />
/// <reference lib="dom" />

import { createClient } from '@supabase/supabase-js';

type WelcomePayload = {
  email?: string;
  nome?: string;
  status?: string;
};

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get('Authorization');
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const resendApiKey = Deno.env.get('RESEND_API_KEY') ?? '';
    const fromEmail = Deno.env.get('RESEND_FROM_EMAIL') ?? '';

    if (!authorization) {
      return jsonResponse({ error: 'Token ausente.' }, 401);
    }

    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse({ error: 'Configuração do Supabase ausente.' }, 500);
    }

    if (!resendApiKey || !fromEmail) {
      return jsonResponse({ error: 'Configuração de e-mail ausente.' }, 500);
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authorization,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: 'Usuário não autenticado.' }, 401);
    }

    const payload = (await request.json()) as WelcomePayload;
    const email = String(payload.email ?? '').trim();
    const nome = String(payload.nome ?? 'Motorista').trim();
    const status = String(payload.status ?? 'Pendente').trim();

    if (!email || user.email?.toLowerCase() !== email.toLowerCase()) {
      return jsonResponse(
        { error: 'E-mail inválido para o usuário logado.' },
        403,
      );
    }

    const html = `
      <div style="font-family: Arial, sans-serif; background: #fff7ef; padding: 24px; color: #2c2117;">
        <div style="max-width: 560px; margin: 0 auto; background: #ffffff; border: 1px solid #f3c79b; border-radius: 16px; padding: 32px;">
          <h1 style="margin: 0 0 16px; color: #e16f12;">Bem-vindo a GLM Cargas</h1>
          <p style="margin: 0 0 12px;">Ola, ${nome || 'motorista'}.</p>
          <p style="margin: 0 0 12px;">
            Seu cadastro foi recebido com sucesso e o status atual da sua conta é
            <strong>${status}</strong>.
          </p>
          <p style="margin: 0 0 12px;">
            Nossa equipe vai avaliar suas informações e seus documentos em breve.
          </p>
          <p style="margin: 0 0 12px;">
            Você já pode entrar no aplicativo para acompanhar o status da conta e conferir os documentos enviados.
          </p>
          <p style="margin: 24px 0 0;">Equipe GLM Cargas</p>
        </div>
      </div>
    `;

    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [email],
        subject: 'Bem-vindo a GLM Cargas',
        html,
      }),
    });

    if (!resendResponse.ok) {
      const errorText = await resendResponse.text();
      return jsonResponse(
        {
          error: 'Falha ao enviar e-mail.',
          details: errorText,
        },
        502,
      );
    }

    return jsonResponse({ success: true });
  } catch (error) {
    return jsonResponse(
      {
        error: 'Erro inesperado ao enviar e-mail.',
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
