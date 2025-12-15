class AppNotification {
  final String notificationId;
  final String title;
  final String body;
  final Map<String, dynamic> additionalData;
  final DateTime receivedAt;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.additionalData,
    required this.receivedAt,
  });

  /// Create AppNotification from OneSignal notification JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      body: json['body'] as String? ?? 'No Body',
      additionalData: json['additionalData'] as Map<String, dynamic>? ?? {},
      receivedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'additionalData': additionalData,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppNotification(id: $notificationId, title: $title, body: $body, data: $additionalData)';
  }
}
