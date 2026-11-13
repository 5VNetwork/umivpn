-- Fixes "delete the account, then the email can not be registered again".
--
-- Background
-- ----------
-- Registering an account creates the auth user (auth.users). A trigger on
-- auth.users creates the rows that belong to the user (profile, devices, ...).
-- If a row of a previously deleted account is still in the database, the
-- trigger fails and the database rejects the new user:
--
--   AuthRetryableFetchException(
--     message: {"code":"unexpected_failure",
--               "message":"Database error saving new user"},
--     statusCode: 500)
--
-- The rows are left behind because the `delete-account` edge function removes
-- the auth user, but not (or not reliably) the rows that belong to it.
--
-- This migration
-- --------------
-- 1. adds `public.purge_user_data()`, which removes every row that belongs to
--    a user, and
-- 2. adds a BEFORE INSERT trigger on auth.users that removes the leftovers of
--    a deleted account with the same email before a new user is created, so
--    that an account that was deleted with the old code can be registered
--    again.

-- ---------------------------------------------------------------------------
-- 1. Remove every row that belongs to a user.
-- ---------------------------------------------------------------------------
create or replace function public.purge_user_data(
  p_user_id uuid,
  p_email   text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  -- Rows that reference the user (foreign key to auth.users).
  for r in
    select c.relname as tbl, a.attname as col
    from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      join pg_constraint con
        on con.conrelid = c.oid
       and con.contype = 'f'
       and con.confrelid = 'auth.users'::regclass
      join pg_attribute a
        on a.attrelid = c.oid
       and a.attnum = any (con.conkey)
    where n.nspname = 'public'
      and c.relkind = 'r'
      and a.attnum > 0
      and not a.attisdropped
      and pg_catalog.format_type(a.atttypid, a.atttypmod) = 'uuid'
  loop
    execute format('delete from public.%I where %I = $1', r.tbl, r.col)
      using p_user_id;
  end loop;

  -- Rows that are keyed by the email of the user. They block the registration
  -- of the same email, even when the auth user is already gone.
  if p_email is not null then
    for r in
      select c.relname as tbl, a.attname as col
      from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        join pg_constraint con
          on con.conrelid = c.oid
         and con.contype = 'f'
         and con.confrelid = 'auth.users'::regclass
        join pg_attribute a
          on a.attrelid = c.oid
         and a.attnum = any (con.conkey)
      where n.nspname = 'public'
        and c.relkind = 'r'
        and a.attname = 'email'
        and a.attnum > 0
        and not a.attisdropped
    loop
      execute format('delete from public.%I where lower(%I) = lower($1)', r.tbl, r.col)
        using p_email;
    end loop;

    -- Identities of an auth user that was deleted without cleaning up the
    -- identities. The unique index on (provider_id, provider_user_id) would
    -- reject the new user of the same email.
    delete from auth.identities
    where lower(coalesce(identity_data ->> 'email', provider_user_id)) = lower(p_email);
  end if;
end;
$$;

comment on function public.purge_user_data(uuid, text)
  is 'Removes every row that belongs to the given user, so that the email can be registered again.';

-- The function is security definer, only the service role (the edge function)
-- may call it.
revoke execute on function public.purge_user_data(uuid, text) from public, anon, authenticated;
grant execute on function public.purge_user_data(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- 2. Clean up the leftovers of a deleted account before a new user with the
--    same email is created.
-- ---------------------------------------------------------------------------
create or replace function public.purge_user_data_before_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Never touch the rows of an account that still exists, the insert of the
  -- new user is rejected by the database anyway.
  if exists (
    select 1 from auth.users where lower(email) = lower(new.email)
  ) then
    return new;
  end if;

  perform public.purge_user_data(new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_purge_data on auth.users;

create trigger on_auth_user_created_purge_data
  before insert on auth.users
  for each row
  execute function public.purge_user_data_before_insert();

-- ---------------------------------------------------------------------------
-- 3. Clean up the accounts that are already in the broken state.
--    Run the diagnose script first to see which rows are left over.
-- ---------------------------------------------------------------------------
-- select public.purge_user_data(id, email) from auth.users where email = $1;
--
-- For accounts whose auth user is already gone, remove the leftovers by
-- email only:
-- select public.purge_user_data(null, 'deleted@example.com');
