import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? actionUrl;
  final NotificationPriority priority;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.data,
    this.imageUrl,
    this.actionUrl,
    this.priority = NotificationPriority.normal,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority? priority,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
    );
  }

  bool get isPromotion => type == 'promotion';
  bool get isTransactional => type == 'transaction';
  bool get isAlert => type == 'alert';
  bool get isGeneral => type == 'general';

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  List<Object?> get props => [id, title, body, type, isRead, createdAt, data, imageUrl, actionUrl, priority];
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationTopic extends Equatable {
  final String id;
  final String name;
  final String description;
  final bool isSubscribed;
  final int subscriberCount;

  const NotificationTopic({
    required this.id,
    required this.name,
    required this.description,
    required this.isSubscribed,
    required this.subscriberCount,
  });

  @override
  List<Object?> get props => [id, name, description, isSubscribed, subscriberCount];
}
