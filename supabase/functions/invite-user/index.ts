import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const allowedRoles = new Set(['Tuteur', 'Responsable d’agence', 'RH'])

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Méthode non autorisée' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Authentification requise' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const url = Deno.env.get('SUPABASE_URL')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    })
    const adminClient = createClient(url, serviceKey)

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) throw new Error('Utilisateur non authentifié')

    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('id, role, agency')
      .eq('id', user.id)
      .maybeSingle()

    if (profileError) throw profileError
    if (!profile || profile.role !== 'Formateur Master') {
      return new Response(JSON.stringify({ error: 'Seul un Formateur Master peut inviter des utilisateurs.' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const email = String(body.email ?? '').trim().toLowerCase()
    const role = String(body.role ?? '').trim()
    const agency = body.agency ? String(body.agency).trim() : null

    if (!email || !email.includes('@')) throw new Error('Adresse e-mail invalide')
    if (!allowedRoles.has(role)) throw new Error('Rôle d’invitation invalide')
    if (role === 'Responsable d’agence' && !agency) {
      throw new Error('Une agence doit être sélectionnée pour un Responsable d’agence')
    }

    const { data: existingPending } = await adminClient
      .from('invitations')
      .select('id')
      .eq('status', 'pending')
      .ilike('email', email)
      .maybeSingle()

    if (existingPending) throw new Error('Une invitation est déjà en attente pour cette adresse.')

    const redirectTo = 'https://antonyflichy-ai.github.io/adept-pro-track-mate-test/complete-invitation.html'
    const { data: invited, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(email, {
      redirectTo,
      data: { invited_role: role, invited_agency: agency },
    })

    if (inviteError) throw inviteError

    const { error: insertError } = await adminClient.from('invitations').insert({
      email,
      role,
      agency,
      invited_by: user.id,
      auth_user_id: invited.user.id,
      status: 'pending',
    })

    if (insertError) throw insertError

    return new Response(JSON.stringify({ ok: true, invitation_id: invited.user.id }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'Erreur serveur' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
