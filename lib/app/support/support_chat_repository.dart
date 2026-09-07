import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_common/support/support_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:umivpn/app/support/support_message_local_store.dart';
import 'package:umivpn/common/common.dart';

import 'package:umivpn/utils/logger.dart';

import 'package:umivpn/main.dart';

class SupportMessage {
  SupportMessage({
    required this.id,

    required this.content,

    required this.createdAt,

    required this.isFromSupport,

    required this.userId,

    this.userRead = false,

    this.supportRead = false,
  });

  final String id;

  final String content;

  final DateTime createdAt;

  final bool isFromSupport;

  final String userId;

  final bool userRead;

  final bool supportRead;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: supportMessageIdFromJson(json['id']),
      content: json['content'] as String? ?? '',

      createdAt: DateTime.parse(json['created_at'] as String),

      isFromSupport: json['is_from_support'] as bool,

      userId: json['user_id'] as String,

      userRead: json['user_read'] as bool? ?? false,

      supportRead: json['support_read'] as bool? ?? false,
    );
  }
}

/// PostgREST returns bigint ids as JSON numbers; chat UI uses string ids.
String supportMessageIdFromJson(dynamic raw) {
  if (raw == null) return '';
  if (raw is int) return raw.toString();
  if (raw is num) return raw.toInt().toString();
  return raw.toString();
}

class SupportConversationDeleted implements Exception {
  const SupportConversationDeleted();
}

class SupportConversationStatus {
  const SupportConversationStatus({
    required this.id,
    required this.fromSupport,
    this.lastMessage,
  });

  final String id;
  final bool fromSupport;
  final String? lastMessage;
}

class SupportChatRepository {
  SupportChatRepository({
    SupabaseClient? client,

    SupportMessageLocalStore? localStore,
    SupportChatStorage? storage,
  }) : _client = client ?? supabase,

       _localStore = localStore ?? SupportMessageLocalStore(),
       _storage = storage ?? SupportChatStorage();

  final SupabaseClient _client;

  final SupportMessageLocalStore _localStore;
  final SupportChatStorage _storage;

  String? _conversationId;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Returns the user's existing support conversation id if it exists.
  /// Does not create a new conversation.
  Future<String?> getExistingConversationId() async {
    if (_conversationId != null) {
      return _conversationId;
    }

    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    final row = await _client
        .from('support_conversations')
        .select('id')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) return null;

    final id = row['id'] as String?;
    if (id == null || id.isEmpty) return null;

    _conversationId = id;
    return id;
  }

  /// Current conversation wait state. Null if the user has no conversation.
  Future<SupportConversationStatus?> fetchConversationStatus() async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    final row = await _client
        .from('support_conversations')
        .select('id, from_support, last_message')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) {
      _conversationId = null;
      return null;
    }

    final id = row['id'] as String?;
    if (id == null || id.isEmpty) {
      _conversationId = null;
      return null;
    }

    _conversationId = id;
    return SupportConversationStatus(
      id: id,
      fromSupport: row['from_support'] as bool? ?? false,
      lastMessage: row['last_message'] as String?,
    );
  }

  void forgetConversation() {
    _conversationId = null;
  }

  Future<String> ensureConversation() async {
    if (_conversationId != null) {
      return _conversationId!;
    }

    final conversationId =
        await _client.rpc(
              'get_or_create_support_conversation',
              params: {
                'p_device_platform': Platform.operatingSystem,
                'p_device_version': version,
                'p_device_is_store_version': _isStoreVersion(),
              },
            )
            as String;

    _conversationId = conversationId;

    return conversationId;
  }

  bool _isStoreVersion() {
    if (Platform.isAndroid) {
      return !androidNonStore;
    }
    if (Platform.isWindows) {
      return isWinStore;
    }
    if (Platform.isIOS) {
      return true;
    }
    if (Platform.isMacOS) {
      return !isPkg;
    }
    return false;
  }

  /// Device cache only (no network). Used for instant chat UI on open.
  Future<List<SupportMessage>> loadCachedMessages() async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Not signed in');
    }
    await _localStore.ensureWelcomeMessage(userId);
    return _localStore.loadMessages(userId);
  }

  Future<List<SupportMessage>> loadMessages(String conversationId) async {
    final userId = currentUserId;

    if (userId == null) {
      throw StateError('Not signed in');
    }

    await _localStore.ensureWelcomeMessage(userId);

    try {
      await _fetchNewMessages(conversationId, userId);
      await _localStore.setLastRemoteFetchAt(userId, DateTime.now().toUtc());
      await _localStore.prune(userId);
    } catch (_) {
      // Offline: return cached messages only.
    }

    final merged = await _localStore.loadMessages(userId);

    return merged;
  }

  Future<SupportMessage> sendMessage({
    required String conversationId,

    required String content,

    required String userId,
  }) async {
    final row = await _client
        .from('support_messages')
        .insert({
          'conversation_id': conversationId,

          'user_id': userId,

          'content': content.trim(),

          'is_from_support': false,
        })
        .select()
        .single();

    final message = SupportMessage.fromJson(row);

    final currentUserId = this.currentUserId;

    if (currentUserId != null) {
      await _localStore.upsertMessage(currentUserId, message);
    }

    return message;
  }

  Future<SupportMessage> sendImage({
    required String conversationId,
    required String userId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
    int? pixelWidth,
    int? pixelHeight,
  }) async {
    final path = await _storage.uploadImage(
      userId: userId,
      conversationId: conversationId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
    );

    return sendMessage(
      conversationId: conversationId,
      userId: userId,
      content: supportImageContentFromPath(path),
    );
  }

  /// Marks every conversation read when [conversationId] is omitted.
  Future<void> markUserRead([String? conversationId]) async {
    await _client.rpc(
      'mark_support_messages_user_read',

      params: {'p_conversation_id': conversationId},
    );
  }

  /// Syncs by user rather than by conversation. Used once an agent has closed
  /// the conversation: the client has no conversation id left, but replies that
  /// arrived before the close are still readable and must not be stranded.
  Future<List<SupportMessage>> fetchMissedMessages() async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    return _fetchNewMessages(null, userId);
  }

  Future<List<SupportMessage>> _fetchNewMessages(
    String? conversationId,
    String userId,
  ) async {
    logger.d('fetchNewMessages $conversationId $userId');

    final afterId = await _localStore.lastFetchMaxMessageId(userId);

    final selected = _client.from('support_messages').select();
    var query = conversationId == null
        ? selected.eq('user_id', userId)
        : selected.eq('conversation_id', conversationId);
    if (afterId > 0) {
      query = query.gt('id', afterId);
    }
    final rows = await query.order('created_at', ascending: true);

    final remote = (rows as List)
        .map((row) => SupportMessage.fromJson(row as Map<String, dynamic>))
        .toList();

    if (remote.isNotEmpty) {
      await _localStore.mergeRemoteMessages(userId, remote);
      await _localStore.updateLastFetchMaxMessageId(userId, remote);
    }

    return remote;
  }

  Stream<SupportMessage> watchMessages(String conversationId) {
    final controller = StreamController<SupportMessage>.broadcast();
    Timer? pollTimer;
    var cancelled = false;

    Future<void> pollNewMessages() async {
      if (cancelled || controller.isClosed) {
        return;
      }

      final userId = currentUserId;
      if (userId == null) {
        return;
      }

      try {
        final remote = await _fetchNewMessages(conversationId, userId);
        if (remote.isNotEmpty) {
          await _localStore.setLastRemoteFetchAt(
            userId,
            DateTime.now().toUtc(),
          );
        } else {
          final status = await fetchConversationStatus();
          if (status == null || status.id != conversationId) {
            if (!controller.isClosed) {
              controller.addError(const SupportConversationDeleted());
            }
            cancelled = true;
            pollTimer?.cancel();
            return;
          }
        }

        for (final message in remote) {
          if (!controller.isClosed) {
            controller.add(message);
          }
        }
      } catch (error, stack) {
        logger.e(
          'Support message poll failed ($conversationId)',
          error: error,
          stackTrace: stack,
        );
      }
    }

    unawaited(pollNewMessages());
    pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(pollNewMessages()),
    );

    controller.onCancel = () {
      logger.d('support message stream canceld');
      cancelled = true;
      pollTimer?.cancel();
    };

    return controller.stream;
  }
}

// Stream<SupportMessage> watchMessages(String conversationId) {
//   final controller = StreamController<SupportMessage>.broadcast();

//   final channel = _client
//       .channel('support_messages:$conversationId')
//       .onPostgresChanges(
//         event: PostgresChangeEvent.insert,
//         schema: 'public',
//         table: 'support_messages',
//         filter: PostgresChangeFilter(
//           type: PostgresChangeFilterType.eq,
//           column: 'conversation_id',
//           value: conversationId,
//         ),

//         callback: (payload) async {
//           final record = payload.newRecord;

//           if (record.isEmpty) return;

//           final message = SupportMessage.fromJson(record);

//           final userId = currentUserId;

//           if (userId != null) {
//             await _localStore.upsertMessage(userId, message);
//           }

//           controller.add(message);
//         },
//       )
//       .subscribe();

//   controller.onCancel = () {
//     _client.removeChannel(channel);
//   };

//   return controller.stream;
// }
