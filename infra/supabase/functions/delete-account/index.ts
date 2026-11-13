// Deletes the account of the signed in user.
//
// The rows of the user have to be removed before the auth user is deleted.
// Otherwise they are left behind in the database and the database rejects a
// new user with the same email ("Database error saving new user"), so the
// user can never register that email again.
//
// Adapt the imports to the edge runtime that is used by the project (Deno
// with `jsr:@supabase/supabase-js@2` or `npm:@supabase/supabase-js@2`).

import { createClient } from 'jsr:@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'missing authorization' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }
  const token = authHeader.replace('Bearer ', '')

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  )

  const {
    data: { user },
    error: userError,
  } = await supabaseAdmin.auth.getUser(token)

  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Remove the rows of the user (profile, devices, subscriptions, ...).
  const { error: purgeError } = await supabaseAdmin.rpc('purge_user_data', {
    p_user_id: user.id,
    p_email: user.email,
  })

  if (purgeError) {
    return new Response(
      JSON.stringify({ error: `failed to purge user data: ${purgeError.message}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }

  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

  if (deleteError) {
    return new Response(
      JSON.stringify({ error: `failed to delete user: ${deleteError.message}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
