import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:umivpn/app/support/support_chat_repository.dart'
    show SupportMessage, supportMessageIdFromJson;
import 'package:umivpn/app/support/support_welcome.dart';
import 'package:umivpn/utils/path.dart';

/// Persists support messages on device for offline reading.
class SupportMessageLocalStore {
  static const _jsonEncoder = JsonEncoder();

  Future<Directory> _folderForUser(String userId) async {
    final dir = await resourceDir();
    final folder = Directory(p.join(dir.path, 'support_chat'));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return folder;
  }

  Future<File> _fileForUser(String userId) async {
    final folder = await _folderForUser(userId);
    return File(p.join(folder.path, '$userId.json'));
  }

  Future<File> _metaFileForUser(String userId) async {
    final folder = await _folderForUser(userId);
    return File(p.join(folder.path, '$userId.meta.json'));
  }

  Future<Map<String, dynamic>> _readMeta(String userId) async {
    final file = await _metaFileForUser(userId);
    if (!file.existsSync()) {
      return {};
    }
    try {
      final raw = await file.readAsString();
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMeta(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final file = await _metaFileForUser(userId);
    final merged = {...await _readMeta(userId), ...updates};
    await file.writeAsString(_jsonEncoder.convert(merged));
  }

  Future<DateTime?> getLastRemoteFetchAt(String userId) async {
    final value = (await _readMeta(userId))['last_remote_fetch_at'] as String?;
    if (value == null) {
      return null;
    }
    try {
      return DateTime.parse(value).toUtc();
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastRemoteFetchAt(String userId, DateTime time) async {
    await _writeMeta(userId, {
      'last_remote_fetch_at': time.toUtc().toIso8601String(),
    });
  }

  /// Largest server message id seen on the last successful fetch (0 if none).
  Future<int> lastFetchMaxMessageId(String userId) async {
    final value = (await _readMeta(userId))['last_fetch_max_message_id'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  Future<void> updateLastFetchMaxMessageId(
    String userId,
    Iterable<SupportMessage> fetched,
  ) async {
    var max = await lastFetchMaxMessageId(userId);
    for (final message in fetched) {
      if (isLocalWelcomeMessage(message)) continue;
      final id = int.tryParse(message.id);
      if (id != null && id > max) {
        max = id;
      }
    }
    await _writeMeta(userId, {'last_fetch_max_message_id': max});
  }

  Future<List<SupportMessage>> loadMessages(String userId) async {
    final file = await _fileForUser(userId);
    if (!file.existsSync()) {
      return [];
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => _messageFromLocalJson(
              userId,
              item as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(
    String userId,
    List<SupportMessage> messages,
  ) async {
    final file = await _fileForUser(userId);
    final sorted = [...messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final payload = sorted.map(_messageToJson).toList();
    await file.writeAsString(_jsonEncoder.convert(payload));
  }

  Future<void> upsertMessage(String userId, SupportMessage message) async {
    final existing = await loadMessages(userId);
    final index = existing.indexWhere((item) => item.id == message.id);
    if (index >= 0) {
      existing[index] = message;
    } else {
      existing.add(message);
    }
    await saveMessages(userId, existing);
  }

  Future<void> ensureWelcomeMessage(String userId) async {
    final messages = await loadMessages(userId);
    if (messages.any(isLocalWelcomeMessage)) {
      return;
    }
    await saveMessages(userId, [buildLocalWelcomeMessage(userId), ...messages]);
  }

  Future<void> mergeRemoteMessages(
    String userId,
    List<SupportMessage> remote,
  ) async {
    final local = await loadMessages(userId);
    final byId = {
      for (final item in local)
        if (!isLocalWelcomeMessage(item)) item.id: item,
    };
    for (final message in remote) {
      if (!isLocalWelcomeMessage(message)) {
        byId[message.id] = message;
      }
    }
    final merged = [
      buildLocalWelcomeMessage(userId),
      ...byId.values,
    ];
    await saveMessages(userId, merged);
  }

  Future<void> prune(String userId) async {
    final now = DateTime.now();
    final messages = await loadMessages(userId);
    final kept = messages.where((message) {
      if (isLocalWelcomeMessage(message)) {
        return true;
      }
      return now.difference(message.createdAt).inDays <= 30;
    }).toList();
    await saveMessages(userId, kept);
  }

  Map<String, dynamic> _messageToJson(SupportMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'created_at': message.createdAt.toIso8601String(),
      'is_from_support': message.isFromSupport,
    };
  }

  SupportMessage _messageFromLocalJson(
    String userId,
    Map<String, dynamic> json,
  ) {
    return SupportMessage(
      id: supportMessageIdFromJson(json['id']),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      isFromSupport: json['is_from_support'] as bool,
      userId: userId,
    );
  }
}
