import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firebaseDatabaseProvider);
  final userId = auth.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await db.ref('notifications/$userId').get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      return data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['id'] ??= e.key;
        return map;
      }).toList();
    }
  } catch (_) {}

  return [
    {
      'id': 'notif-1',
      'title': 'أهلاً بك في ست الكل! 🎉',
      'body': 'استمتع بأشهى وألذ الأكلات البيتي المصرية الأصيلة.',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
      'is_read': false,
    },
    {
      'id': 'notif-2',
      'title': 'كوبون خصم جديد 🎁',
      'body': 'استخدم كود SETELKOL20 واحصل على خصم 20% على طلبك القادم.',
      'created_at':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'is_read': true,
    },
  ];
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الإشعارات')),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد إشعارات',
              icon: Icons.notifications_none_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) {
              final n = notifs[i];
              final isRead = n['is_read'] as bool? ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isRead
                      ? AppColors.surface
                      : AppColors.primary.withOpacity(0.05),
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: isRead
                        ? AppColors.cardBorder
                        : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (n['title'] != null)
                            Text(
                              n['title'] as String,
                              style: AppTypography.titleSmall,
                            ),
                          if (n['body'] != null)
                            Text(
                              n['body'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => const AppErrorWidget(message: 'تعذر تحميل الإشعارات'),
      ),
    );
  }
}
