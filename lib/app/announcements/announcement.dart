class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.link,
  });

  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final String? link;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String).toUtc(),
      link: json['link'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'publishedAt': publishedAt.toUtc().toIso8601String(),
    if (link != null) 'link': link,
  };
}
