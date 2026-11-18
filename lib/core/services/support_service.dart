import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/support_ticket.dart';
import '../network/firebase_providers.dart';

class SupportService {
  final FirebaseDatabase _db;

  SupportService(this._db);

  static final List<SupportTicket> demoTickets = [
    SupportTicket(
      id: 'ticket-1',
      userId: 'demo-customer-sara-003',
      userName: 'سارة محمود',
      subject: 'استفسار عن موعد توصيل وجبة المحشي',
      status: TicketStatus.inProgress,
      priority: TicketPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      lastMessage: 'تم التواصل مع الشيف وجاري التجهيز للتوصيل خلال 20 دقيقة.',
    ),
    SupportTicket(
      id: 'ticket-2',
      userId: 'demo-vendor-omahmed-002',
      userName: 'أم أحمد (ست الكل)',
      subject: 'طلب تفعيل خيار الدفع عبر إنستاباي',
      status: TicketStatus.open,
      priority: TicketPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      lastMessage:
          'أريد إضافة رقم إنستاباي الخاص بي لاستقبال مدفوعات العملاء مباشرة.',
    ),
    SupportTicket(
      id: 'ticket-3',
      userId: 'demo-customer-sara-003',
      userName: 'محمود عبد الله',
      subject: 'مشكلة في تطبيق كود الخصم',
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      resolvedAt: DateTime.now().subtract(const Duration(hours: 12)),
      lastMessage: 'تم تفعيل كود الخصم الترويجي بحسابك بنجاح.',
    ),
  ];

  Future<List<SupportTicket>> getTickets(
      {String? userId, bool isAdmin = false}) async {
    try {
      final snapshot = await _db.ref('support_tickets').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries
            .map((e) {
              final map = Map<String, dynamic>.from(e.value as Map);
              map['id'] ??= e.key;
              return SupportTicket.fromJson(map);
            })
            .where((t) => isAdmin || userId == null || t.userId == userId)
            .toList();

        if (list.isNotEmpty) {
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        }
      }
    } catch (e) {
      debugPrint('[SupportService] Error getting tickets: $e');
    }
    return demoTickets;
  }

  Future<SupportTicket?> createTicket({
    required String userId,
    required String subject,
    required String initialMessage,
    TicketPriority priority = TicketPriority.medium,
  }) async {
    try {
      final ticketRef = _db.ref('support_tickets').push();
      final ticketId =
          ticketRef.key ?? 'ticket_${DateTime.now().millisecondsSinceEpoch}';
      final nowIso = DateTime.now().toIso8601String();

      final ticketData = {
        'id': ticketId,
        'user_id': userId,
        'subject': subject,
        'status': TicketStatus.open.dbValue,
        'priority': priority.dbValue,
        'last_message': initialMessage,
        'created_at': nowIso,
        'updated_at': nowIso,
      };

      await ticketRef.set(ticketData);

      final msgRef = _db.ref('support_messages/$ticketId').push();
      await msgRef.set({
        'id': msgRef.key,
        'ticket_id': ticketId,
        'sender_id': userId,
        'message': initialMessage,
        'is_from_admin': false,
        'created_at': nowIso,
      });

      return SupportTicket.fromJson(ticketData);
    } catch (e) {
      debugPrint('[SupportService] Error creating ticket: $e');
      return null;
    }
  }

  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _db.ref('support_tickets/$ticketId').update({
        'status': status.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == TicketStatus.resolved || status == TicketStatus.closed)
          'resolved_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[SupportService] Error updating ticket status: $e');
      return false;
    }
  }

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    try {
      final snapshot = await _db.ref('support_messages/$ticketId').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return SupportMessage.fromJson(map);
        }).toList();

        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      }
    } catch (e) {
      debugPrint('[SupportService] Error getting messages: $e');
    }

    return [
      SupportMessage(
        id: 'msg-1',
        ticketId: ticketId,
        senderId: 'user-1',
        senderName: 'العميل',
        message: 'مرحباً، لدي استفسار بخصوص الطلب.',
        isFromAdmin: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SupportMessage(
        id: 'msg-2',
        ticketId: ticketId,
        senderId: 'admin-1',
        senderName: 'فريق دعم ست الكل',
        message:
            'أهلاً بك! نسعد بمساعدتك، فريق العمل يتابع طلبك وسنوافيك بالتفاصيل فوراً.',
        isFromAdmin: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  Future<bool> sendMessage({
    required String ticketId,
    required String senderId,
    required String message,
    bool isFromAdmin = false,
  }) async {
    try {
      final msgRef = _db.ref('support_messages/$ticketId').push();
      final nowIso = DateTime.now().toIso8601String();
      await msgRef.set({
        'id': msgRef.key,
        'ticket_id': ticketId,
        'sender_id': senderId,
        'message': message,
        'is_from_admin': isFromAdmin,
        'created_at': nowIso,
      });

      await _db.ref('support_tickets/$ticketId').update({
        'updated_at': nowIso,
        'last_message': message,
      });

      return true;
    } catch (e) {
      debugPrint('[SupportService] Error sending message: $e');
      return false;
    }
  }
}

final supportServiceProvider = Provider<SupportService>((ref) {
  final db = ref.watch(firebaseDatabaseProvider);
  return SupportService(db);
});

final allSupportTicketsProvider =
    FutureProvider<List<SupportTicket>>((ref) async {
  final service = ref.watch(supportServiceProvider);
  return service.getTickets(isAdmin: true);
});
