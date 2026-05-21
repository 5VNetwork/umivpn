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

  StreamSubscription<SupportMessage>? _subscription;

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

      final conversationId = await _repository.ensureConversation();
      final loaded = await _repository.loadMessages(conversationId);

      for (final message in loaded) {
        await supportChatInsertOrReconcileIncoming(
          controller: _chatController,
          incoming: _toChatMessage(message, userId),
        );
      }

      await _repository.markUserRead(conversationId);

      if (!mounted) return;

      context.read<SupportUnreadBadgeController>().clear();

      setState(() {
        _conversationId = conversationId;
        _syncing = false;
      });

      _subscription = _repository
          .watchMessages(conversationId)
          .listen(_onIncomingMessage);
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

  Message _toChatMessage(SupportMessage message, String currentUserId) {
    final authorId = message.isFromSupport ? _supportUserId : currentUserId;

    if (isLocalWelcomeMessage(message)) {
      return Message.text(
        id: message.id,
        authorId: _supportUserId,
        createdAt: message.createdAt,
        text: AppLocalizations.of(context)!.supportWelcomeMessage,
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

    final conversationId = _conversationId;
    final userId = _currentUserId;
    if (conversationId == null || userId == null) return;

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
    final conversationId = _conversationId;
    final userId = _currentUserId;
    if (conversationId == null || userId == null) return;

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
    final conversationId = _conversationId;
    final userId = _currentUserId;
    if (conversationId == null || userId == null) return;

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
        if (_syncing)
          const LinearProgressIndicator(minHeight: 2),
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
