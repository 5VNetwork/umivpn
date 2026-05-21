import 'package:umivpn/app/support/support_chat_repository.dart';

/// Local-only welcome message (never synced to Supabase).
const supportWelcomeMessageId = 'local-welcome';

SupportMessage buildLocalWelcomeMessage(String userId) {
  return SupportMessage(
    id: supportWelcomeMessageId,
    // Shown via [AppLocalizations.supportWelcomeMessage] in the chat UI.
    content: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    isFromSupport: true,
    userId: userId,
    userRead: true,
    supportRead: true,
  );
}

bool isLocalWelcomeMessage(SupportMessage message) =>
    message.id == supportWelcomeMessageId;
