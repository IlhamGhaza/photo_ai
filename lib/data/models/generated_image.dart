class GeneratedImage {
  final String id;
  final String url;
  final String style;
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.url,
    required this.style,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'style': style,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'] as String,
      url: json['url'] as String,
      style: json['style'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  GeneratedImage copyWith({
    String? id,
    String? url,
    String? style,
    DateTime? createdAt,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      url: url ?? this.url,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
