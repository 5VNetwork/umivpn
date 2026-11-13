# Patches

Patches for the packages that are used as a path dependency and are maintained
in their own repository.

## flutter_common

`flutter_common/0001-friendly-auth-errors.patch`

- Shows a short message instead of the raw error of the supabase client when
  the registration or the sign in fails. The raw error contains the whole
  response of the server, for example
  `AuthRetryableFetchException(message: {"code":"unexpected_failure","message":"Database error saving new user"}, statusCode: 500)`.
- Checks the response of the `delete-account` edge function in
  `AuthProvider.deleteAccount()`. A failed deletion was silently reported as a
  success, which leaves the account half deleted.

Apply it in the `flutter_common` repository:

```sh
git apply /path/to/umivpn/patches/flutter_common/0001-friendly-auth-errors.patch
```
