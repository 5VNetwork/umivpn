# Supabase (backend)

The backend of the app is a Supabase project:

- **Postgres**: the users and everything that belongs to them.
- **Auth**: the accounts (`auth.users`), the registration and the sign in.
- **Edge functions**: `delete-account`, `get-profile`, `cancel-subscription`,
  `create-stripe-checkout-session`, `create-stripe-portal-session`, ...

## "Delete the account, then the email can not be registered again"

### What happens

1. The user deletes the account. The app calls the `delete-account` edge
   function (`lib/auth/account_service.dart`).
2. The edge function deletes the auth user of the account.
3. The user tries to register the same email again. GoTrue creates a new auth
   user, a trigger on `auth.users` creates the rows that belong to the user
   (profile, devices, ...) and the database rejects the insert:

   ```
   AuthRetryableFetchException(
     message: {"code":"unexpected_failure",
               "message":"Database error saving new user"},
     statusCode: 500)
   ```

The auth user itself is gone, GoTrue would answer with `User already
registered` if it was still there. The error comes from the database, so a row
of the deleted account is still in the database and conflicts with the new
user. The usual reasons:

- The rows of the user were not deleted together with the auth user (the
  foreign keys to `auth.users` do not `on delete cascade`).
- The `delete-account` edge function deleted the auth user, but the deletion of
  the other rows failed, and the failure was not reported to the app.
- An identity of the deleted user (`auth.identities`) was left behind. The
  unique index on `(provider_id, provider_user_id)` rejects the new user of the
  same email.

### How to find the leftovers

Run `diagnose.sql` in the Supabase SQL editor. It lists

- the tables that belong to a user (foreign key to `auth.users`) and their
  `on delete` behaviour,
- the rows of the deleted email in those tables,
- the identities that were left behind,
- the tables with rows that reference a user that does not exist anymore.

### How to fix it

1. Apply `migrations/20261113_fix_account_deletion.sql`. It adds
   `public.purge_user_data(user_id, email)`, which removes every row that
   belongs to a user, and a trigger on `auth.users` that removes the leftovers
   of a deleted account before a new user with the same email is created. The
   trigger makes the registration work again for the accounts that were deleted
   with the old code.
2. Deploy `functions/delete-account/index.ts`. It removes the rows of the user
   before it deletes the auth user and it reports a failure instead of
   answering with `200` when the cleanup did not work.
3. Clean up the accounts that are already broken:

   ```sql
   -- the auth user still exists
   select public.purge_user_data(id, email) from auth.users where email = 'deleted@example.com';

   -- the auth user is already gone
   select public.purge_user_data(null, 'deleted@example.com');
   ```

### The app

- `lib/auth/account_service.dart` deletes the account and checks the response
  of the edge function. A failed deletion is reported to the user instead of
  being silently accepted, so the app never leaves the user with a half
  deleted account.
- `patches/flutter_common/0001-friendly-auth-errors.patch` replaces the raw
  error of the supabase client (the whole response of the server) with a
  short message, for example
  `AuthRetryableFetchException(message: {"code":"unexpected_failure", ...})`.
