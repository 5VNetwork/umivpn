import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:umivpn/app/announcements/announcement.dart';
import 'package:umivpn/common/common.dart';

const announcementsR2BaseUrl = 'https://umivpn.r2.5vnetwork.com/announcements';

class AnnouncementsService {
  AnnouncementsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches announcements for [locale], falling back to `en` on failure.
  Future<List<Announcement>> fetch(String locale) async {
    try {
      return await _fetchLocale(locale);
    } catch (_) {
      if (locale == 'en') rethrow;
      return _fetchLocale('en');
    }
  }

  Future<List<Announcement>> _fetchLocale(String locale) async {
    final String jsonString;
    if (debug) {
      jsonString = await rootBundle.loadString('assets/announcements.json');
    } else {
      final url = Uri.parse('$announcementsR2BaseUrl/$locale.json');
      final response = await _client.get(url);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch announcements: ${response.statusCode}',
        );
      }
      jsonString = response.body;
    }
    return parseAnnouncementsJson(jsonString);
  }

  static List<Announcement> parseAnnouncementsJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final raw = data['messages'] as List<dynamic>? ?? const [];
    final messages = raw
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
    messages.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return messages;
  }
}
