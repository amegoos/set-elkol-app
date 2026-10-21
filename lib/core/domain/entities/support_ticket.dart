import 'package:equatable/equatable.dart';

enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static TicketStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String get dbValue {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String get arabicLabel {
    switch (this) {
      case TicketStatus.open:
        return 'مفتوحة';
      case TicketStatus.inProgress:
        return 'قيد المعالجة';
      case TicketStatus.resolved:
        return 'تم الحل';
      case TicketStatus.closed:
        return 'مغلقة';
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  static TicketPriority fromString(String val) {
    switch (val.toLowerCase()) {
      case 'low':
        return TicketPriority.low;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.medium;
    }
  }

  String get dbValue => name;

  String get arabicLabel {
    switch (this) {
      case TicketPriority.low:
        return 'منخفضة';
      case TicketPriority.medium:
        return 'متوسطة';
      case TicketPriority.high:
        return 'عالية';
      case TicketPriority.urgent:
        return 'عاجلة 🔥';
    }
  }
}

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.userId,
    this.userName,
    required this.subject,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    this.assignedAdminId,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.lastMessage,
  });

  final String id;
  final String userId;
  final String? userName;
  final String subject;
  final TicketStatus status;
  final TicketPriority priority;
  final String? assignedAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? lastMessage;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['profiles']?['full_name'] as String? ??
          json['user_name'] as String?,
      subject: json['subject'] as String? ?? '',
      status: TicketStatus.fromString(json['status'] as String? ?? 'open'),
      priority:
          TicketPriority.fromString(json['priority'] as String? ?? 'medium'),
      assignedAdminId: json['assigned_admin_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
      lastMessage: json['last_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'status': status.dbValue,
      'priority': priority.dbValue,
      'assigned_admin_id': assignedAdminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        subject,
        status,
        priority,
        assignedAdminId,
        createdAt,
        updatedAt,
        resolvedAt,
        lastMessage,
      ];
}

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    this.senderName,
    required this.message,
    this.isFromAdmin = false,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String senderId;
  final String? senderName;
  final String message;
  final bool isFromAdmin;
  final DateTime createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['profiles']?['full_name'] as String? ??
          (json['is_from_admin'] == true ? 'الدعم الفني' : 'العميل'),
      message: json['message'] as String? ?? '',
      isFromAdmin: json['is_from_admin'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message,
      'is_from_admin': isFromAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        senderId,
        senderName,
        message,
        isFromAdmin,
        createdAt,
      ];
}
