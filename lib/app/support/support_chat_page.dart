import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_common/support/support_chat.dart';
import 'package:flutter_common/support/support_chat_send.dart';
import 'package:provider/provider.dart';
import 'package:umivpn/app/settings/setting.dart';
import 'package:umivpn/app/support/support_chat_repository.dart';
import 'package:umivpn/app/support/support_unread_badge.dart';
import 'package:umivpn/app/support/support_welcome.dart';
import 'package:umivpn/l10n/app_localizations.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

const _supportUserId = 'support';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _repository = SupportChatRepository();

  late final InMemoryChatController _chatController;

  String? _conversationId;

  String? _currentUserId;

  String? _error;

  bool _syncing = false;

  Future<String>? _ensureConversationFuture;

  StreamSubscription<SupportMessage>? _subscription;

  SupportUnreadBadgeController? _unreadBadge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unreadBadge = context.read<SupportUnreadBadgeController>();
    _unreadBadge!.pausePolling();
  }

  @override
  void initState() {
    super.initState();

    _chatController = InMemoryChatController();

    if (supabase.auth.currentSession == null) {
      _error = 'Please sign in to contact support';
    } else {
      final userId = _repository.currentUserId;
      if (userId == null) {
        _error = 'Supabase session is missing';
      } else {
        _currentUserId = userId;
        _syncing = true;
      }
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _populateFromCache(userId);
      if (!mounted) return;

      setState(() {});

      // Drain any replies the watermark hasn't seen yet — including those from
      // a conversation the agent already closed — before looking at the active
      // conversation. Do NOT create a conversation just by opening the page.
      await _syncMissedMessages(userId);
      if (!mounted) return;

      final conversationId = await _repository.getExistingConversationId();

      if (conversationId == null) {
        setState(() {
          _syncing = false;
        });
        return;
      }

      final loaded = await _repository.loadMessages(conversationId);

      for (final message in loaded) {
        await supportChatInsertOrReconcileIncoming(
          controller: _chatController,
          incoming: _toChatMessage(message, userId),
        );
      }

      await _repository.markUserRead(conversationId);

      if (!mounted) return;

      final unread = context.read<SupportUnreadBadgeController>();
      unread.markConversationActive();
      unread.pausePolling();
      unread.clear();

      setState(() {
        _conversationId = conversationId;
        _syncing = false;
      });

      _subscription ??= _repository
          .watchMessages(conversationId)
          .listen(_onIncomingMessage, onError: _onWatchError);
    } catch (error) {
      logger.e(error);
      if (!mounted) return;

      setState(() {
        if (_chatController.messages.isEmpty) {
          _error = error.toString();
        }
        _syncing = false;
      });
    }
  }

  Future<String> _ensureConversationReady() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Future.error(StateError('Not signed in'));
    }

    final existingId = _conversationId;
    if (existingId != null) {
      return Future.value(existingId);
    }

    final inflight = _ensureConversationFuture;
    if (inflight != null) {
      return inflight;
    }

    final future =
        () async {
              if (mounted) {
                setState(() {
                  _syncing = true;
                  _error = null;
                });
              }

              final conversationId = await _repository.ensureConversation();

              if (!mounted) return conversationId;

              setState(() {
                _conversationId = conversationId;
                _syncing = false;
              });

              _subscription ??= _repository
                  .watchMessages(conversationId)
                  .listen(_onIncomingMessage, onError: _onWatchError);

              return conversationId;
            }()
            .catchError((error) {
              logger.e(error);
              if (mounted) {
                setState(() {
                  _syncing = false;
                  _error ??= error.toString();
                });
              }
              throw error;
            })
            .whenComplete(() {
              _ensureConversationFuture = null;
            });

    _ensureConversationFuture = future;
    return future;
  }

  Future<void> _populateFromCache(String userId) async {
    try {
      final cached = await _repository.loadCachedMessages();
      for (final message in cached) {
        await supportChatInsertOrReconcileIncoming(
          controller: _chatController,
          incoming: _toChatMessage(message, userId),
        );
      }
    } catch (error) {
      logger.e(error);
    }
  }

  void _markConversationActive() {
    if (!mounted) return;
    context.read<SupportUnreadBadgeController>().markConversationActive();
  }

  void _onWatchError(Object error, [StackTrace? stack]) {
    if (error is SupportConversationDeleted) {
      unawaited(_handleConversationDeleted());
      return;
    }
    logger.e(error, stackTrace: stack);
  }

  /// There is no visible conversation, either because an agent closed it or
  /// because the user never opened one. Replies from just before the close are
  /// still readable by user id, so pull them in rather than losing them.
  Future<void> _syncMissedMessages(String userId) async {
    try {
      final missed = await _repository.fetchMissedMessages();
      for (final message in missed) {
        await supportChatInsertOrReconcileIncoming(
          controller: _chatController,
          incoming: _toChatMessage(message, userId),
        );
      }
      if (missed.any((message) => message.isFromSupport)) {
        await _repository.markUserRead();
      }
    } catch (error) {
      logger.e(error);
    }
    if (!mounted) return;
    context.read<SupportUnreadBadgeController>().clear();
  }

  Future<void> _handleConversationDeleted() async {
    await _subscription?.cancel();
    _subscription = null;
    final userId = _currentUserId;
    if (userId != null) {
      await _syncMissedMessages(userId);
    }
    _repository.forgetConversation();
    if (!mounted) return;
    context.read<SupportUnreadBadgeController>().stopWaitingForReply();
    setState(() {
      _conversationId = null;
      _syncing = false;
    });
  }

  Future<void> _onIncomingMessage(SupportMessage message) async {
    final currentUserId = _currentUserId;

    if (currentUserId == null) return;

    final chatMessage = _toChatMessage(message, currentUserId);
    await supportChatInsertOrReconcileIncoming(
      controller: _chatController,
      incoming: chatMessage,
    );

    if (message.isFromSupport) {
      final conversationId = _conversationId;

      if (conversationId != null) {
        await _repository.markUserRead(conversationId);
        if (mounted) {
          context.read<SupportUnreadBadgeController>().clear();
        }
      }
    }
  }

  String _getFaqUrl() {
    return 'https://www.umivpn.com/faq';
  }

  Message _toChatMessage(SupportMessage message, String currentUserId) {
    final authorId = message.isFromSupport ? _supportUserId : currentUserId;

    if (isLocalWelcomeMessage(message)) {
      return Message.text(
        id: message.id,
        authorId: _supportUserId,
        createdAt: message.createdAt,
        text: AppLocalizations.of(context)!.supportWelcomeMessage(_getFaqUrl()),
      );
    }

    if (isSupportImageContent(message.content)) {
      return Message.image(
        id: message.id,
        authorId: authorId,
        createdAt: message.createdAt,
        source: supportImageReferenceFromContent(message.content),
      );
    }

    return Message.text(
      id: message.id,
      authorId: authorId,
      createdAt: message.createdAt,
      text: message.content,
    );
  }

  Future<void> _handleMessageSend(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userId = _currentUserId;
    if (userId == null) return;

    final conversationId = await _ensureConversationReady();

    final pendingId = supportChatNewLocalTextId();
    final pending = supportChatPendingTextMessage(
      id: pendingId,
      authorId: userId,
      text: trimmed,
    );
    await _chatController.insertMessage(pending);

    await supportChatDeliverOutboundText(
      controller: _chatController,
      pending: pending,
      send: () async {
        final message = await _repository.sendMessage(
          conversationId: conversationId,
          content: trimmed,
          userId: userId,
        );
        _markConversationActive();
        return _toChatMessage(message, userId);
      },
    );
  }

  Future<void> _retryTextMessage(TextMessage failed) async {
    final conversationId = _conversationId;
    final userId = _currentUserId;
    if (conversationId == null ||
        userId == null ||
        failed.status != MessageStatus.error) {
      return;
    }

    final retrying = Message.text(
      id: failed.id,
      authorId: userId,
      createdAt: failed.createdAt,
      text: failed.text,
      status: MessageStatus.sending,
    );
    await _chatController.updateMessage(failed, retrying);

    await supportChatDeliverOutboundText(
      controller: _chatController,
      pending: retrying,
      send: () async {
        final message = await _repository.sendMessage(
          conversationId: conversationId,
          content: failed.text,
          userId: userId,
        );
        _markConversationActive();
        return _toChatMessage(message, userId);
      },
    );
  }

  void _onMessageTap(
    BuildContext context,
    Message message, {
    int? index,
    TapUpDetails? details,
  }) {
    if (message is TextMessage &&
        message.status == MessageStatus.error &&
        message.authorId == _currentUserId) {
      unawaited(_retryTextMessage(message));
    }
  }

  Future<void> _handleAttachmentTap() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _ensureConversationReady();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;

    await _sendImageBytes(file.bytes!, file.name);
  }

  Future<void> _handleImagePaste(Uint8List bytes, String fileName) async {
    await _sendImageBytes(bytes, fileName);
  }

  Future<void> _sendImageBytes(Uint8List bytes, String fileName) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final conversationId = await _ensureConversationReady();

    final dimensions = await decodeSupportImageDimensions(bytes);
    final pendingId = 'local-image-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = Message.image(
      id: pendingId,
      authorId: userId,
      createdAt: DateTime.now(),
      source: fileName,
      metadata: {
        supportChatLocalImageBytesMetadataKey: bytes,
        supportChatImageUploadingMetadataKey: true,
        supportChatImagePixelWidthMetadataKey: dimensions.width,
        supportChatImagePixelHeightMetadataKey: dimensions.height,
      },
    );
    await _chatController.insertMessage(pendingMessage);

    try {
      final message = await _repository.sendImage(
        conversationId: conversationId,
        userId: userId,
        fileName: fileName,
        bytes: bytes,
        pixelWidth: dimensions.width,
        pixelHeight: dimensions.height,
      );

      final chatMessage = _toChatMessage(message, userId);
      await supportChatConfirmOutbound(
        controller: _chatController,
        pending: pendingMessage,
        delivered: chatMessage,
      );
      _markConversationActive();
    } catch (error) {
      await _chatController.updateMessage(
        pendingMessage,
        Message.image(
          id: pendingId,
          authorId: userId,
          createdAt: pendingMessage.createdAt,
          failedAt: DateTime.now(),
          source: fileName,
          status: MessageStatus.error,
          metadata: {
            supportChatLocalImageBytesMetadataKey: bytes,
            supportChatImageUploadErrorMetadataKey: true,
            supportChatImagePixelWidthMetadataKey: dimensions.width,
            supportChatImagePixelHeightMetadataKey: dimensions.height,
          },
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $error')));
    }
  }

  Future<User?> _resolveUser(UserID id) async {
    if (id == _supportUserId) {
      return const User(id: _supportUserId, name: 'Support');
    }

    return User(id: id, name: 'You');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _unreadBadge?.startPollingIfNeeded();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: widget.showAppBar
          ? getAdaptiveAppBar(context, const Text('Support chat'))
          : null,
      body: _buildBody(isLightTheme),
    );
  }

  Widget _buildBody(bool isLightTheme) {
    if (_error != null && _currentUserId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_syncing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Chat(
            currentUserId: currentUserId,
            resolveUser: _resolveUser,
            chatController: _chatController,
            onMessageSend: _handleMessageSend,
            onMessageTap: _onMessageTap,
            onAttachmentTap: _handleAttachmentTap,
            builders: supportChatBuilders(onImagePaste: _handleImagePaste),
            theme: supportChatTheme(context, isLight: isLightTheme),
          ),
        ),
      ],
    );
  }
}
