import 'package:uuid/uuid.dart';

class NotificationModel {
  final String id;
  final String title;
  final String type; // 'pickup_request', 'dustbin_full'
  final String status; // 'pending', 'completed'
  final DateTime createdAt;

  NotificationModel({
    String? id,
    required this.title,
    required this.type,
    this.status = 'pending',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Factory constructor to create from Supabase response
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'pickup_request',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  NotificationModel copyWith({
    String? id,
    String? title,
    String? type,
    String? status,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
