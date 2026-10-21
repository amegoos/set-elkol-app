import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/support_ticket.dart';
import '../network/supabase_client.dart';

class SupportService {
  final SupabaseClient _client;

  SupportService(this._client);

  static final List<SupportTicket> demoTickets = [
    SupportTicket(
      id: 'ticket-1',
      userId: '00000000-0000-0000-0000-000000000002',
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
      userId: '00000000-0000-0000-0000-000000000001',
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
      userId: '00000000-0000-0000-0000-000000000002',
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
      var query =
          _client.from('support_tickets').select('*, profiles(full_name)');
      if (!isAdmin && userId != null) {
        query = query.eq('user_id', userId);
      }
      final data = await query.order('created_at', ascending: false);

      final list = (data as List)
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
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
      final ticketData = await _client
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'subject': subject,
            'status': TicketStatus.open.dbValue,
            'priority': priority.dbValue,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final ticketId = ticketData['id'] as String;

      await _client.from('support_messages').insert({
        'ticket_id': ticketId,
        'sender_id': userId,
        'message': initialMessage,
        'is_from_admin': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return SupportTicket.fromJson(ticketData);
    } catch (e) {
      debugPrint('[SupportService] Error creating ticket: $e');
      return null;
    }
  }

  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _client.from('support_tickets').update({
        'status': status.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == TicketStatus.resolved || status == TicketStatus.closed)
          'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      return true;
    } catch (e) {
      debugPrint('[SupportService] Error updating ticket status: $e');
      return false;
    }
  }

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    try {
      final data = await _client
          .from('support_messages')
          .select('*, profiles(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return (data as List)
          .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupportService] Error getting messages: $e');
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
  }

  Future<bool> sendMessage({
    required String ticketId,
    required String senderId,
    required String message,
    bool isFromAdmin = false,
  }) async {
    try {
      await _client.from('support_messages').insert({
        'ticket_id': ticketId,
        'sender_id': senderId,
        'message': message,
        'is_from_admin': isFromAdmin,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _client.from('support_tickets').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);

      return true;
    } catch (e) {
      debugPrint('[SupportService] Error sending message: $e');
      return false;
    }
  }
}

final supportServiceProvider = Provider<SupportService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupportService(client);
});

final allSupportTicketsProvider =
    FutureProvider<List<SupportTicket>>((ref) async {
  final service = ref.watch(supportServiceProvider);
  return service.getTickets(isAdmin: true);
});
