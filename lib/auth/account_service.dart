import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umivpn/utils/logger.dart';

/// Thrown when the account could not be deleted on the server.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message, {this.statusCode});

  /// Technical reason, only used for logging.
  final String message;

  /// HTTP status returned by the `delete-account` edge function, if any.
  final int? statusCode;

  @override
  String toString() =>
      'AccountDeletionException($message, status: $statusCode)';
}

/// Deletes the account of the currently signed in user.
///
/// `AuthProvider.deleteAccount()` (flutter_common) calls the `delete-account`
/// edge function but ignores its result: when the server side cleanup fails,
/// the app still reports the deletion as successful and signs the user out.
/// The account is then left in a half deleted state - the auth user is gone
/// but the rows that belong to the email are still in the database. Creating
/// a new user with that email is rejected by the database afterwards
/// (`Database error saving new user`), so the user can never register again.
///
/// This service verifies the response of the edge function and only clears the
/// local session when the deletion really succeeded.
class AccountService {
  AccountService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AccountDeletionException('No active session');
    }

    final response = await _client.functions.invoke(
      'delete-account',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    // A response that is not a success is an error, the deletion did not
    // work.
    if (response.status < 200 || response.status >= 300) {
      logger.e(
        'delete-account failed',
        error: 'status: ${response.status}, body: ${response.data}',
      );
      throw AccountDeletionException(
        'delete-account failed',
        statusCode: response.status,
      );
    }

    await _clearLocalSession();
  }

  /// The auth user is already gone on the server, so the sign out request may
  /// fail. The local session is removed before the request is sent, so the
  /// app never keeps a session of a user that does not exist anymore.
  Future<void> _clearLocalSession() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      logger.w('sign out after account deletion failed', error: e);
    }
  }
}
