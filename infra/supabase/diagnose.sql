-- Finds the rows that block the registration of an email.
--
-- Run the queries in the Supabase SQL editor. Replace `deleted@example.com`
-- with the email of the account that can not be registered again.

-- 1. The user scoped tables (tables with a foreign key to auth.users).
select
  c.relname                              as table_name,
  con.conname                            as foreign_key,
  pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
  a.attname                              as column_name,
  case con.confdeltype
    when 'a' then 'no action'
    when 'r' then 'restrict'
    when 'c' then 'cascade'
    when 'n' then 'set null'
    when 'd' then 'set default'
  end                                    as on_delete
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
order by c.relname, a.attname;

-- 2. Rows that are still there for the deleted email.
select c.relname as table_name, a.attname as column_name
from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_attribute a on a.attrelid = c.oid
  join pg_constraint con
    on con.conrelid = c.oid
   and con.contype = 'f'
   and con.confrelid = 'auth.users'::regclass
where n.nspname = 'public'
  and c.relkind = 'r'
  and a.attname = 'email'
  and a.attnum > 0
  and not a.attisdropped;

-- 3. The rows of the email in every table of the list above.
--    Run the query for every table of query 2:
-- select * from public.<table> where lower(email) = lower('deleted@example.com');

-- 4. Identities that were left behind (they block a new user with the same
--    email because of the unique index on (provider_id, provider_user_id)).
select
  id,
  user_id,
  provider_id,
  provider_user_id,
  identity_data ->> 'email' as email
from auth.identities
where lower(coalesce(identity_data ->> 'email', provider_user_id)) =
      lower('deleted@example.com');

-- 5. The rows that reference an auth user that does not exist anymore
--    (dangling rows).
select c.relname as table_name, a.attname as column_name
from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_attribute a on a.attrelid = c.oid
  join pg_constraint con
    on con.conrelid = c.oid
   and con.contype = 'f'
   and con.confrelid = 'auth.users'::regclass
where n.nspname = 'public'
  and c.relkind = 'r'
  and a.attnum > 0
  and not a.attisdropped
  and pg_catalog.format_type(a.atttypid, a.atttypmod) = 'uuid';
