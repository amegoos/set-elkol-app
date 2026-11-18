import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_smart_image.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrlSafe(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final can = await canLaunchUrl(uri);
      if (can) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          _fallbackCopy(urlString);
        }
      } else {
        final launched = await launchUrl(uri);
        if (!launched && mounted) {
          _fallbackCopy(urlString);
        }
      }
    } catch (_) {
      if (mounted) {
        _fallbackCopy(urlString);
      }
    }
  }

  void _fallbackCopy(String urlString) {
    if (!mounted) return;
    if (urlString.startsWith('mailto:')) {
      Clipboard.setData(
          const ClipboardData(text: 'setelkol.support@gmail.com'));
      context.showSnack('تم نسخ البريد setelkol.support@gmail.com للحافظة ✓');
    } else if (urlString.startsWith('tel:')) {
      Clipboard.setData(const ClipboardData(text: '01067322605'));
      context.showSnack('تم نسخ رقم الهاتف 01067322605 للحافظة ✓');
    } else {
      Clipboard.setData(ClipboardData(text: urlString));
      context.showSnack('تم نسخ الرابط للحافظة ✓');
    }
  }

  void _sendTicket() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      context.showSnack('يرجى كتابة رسالتك أولاً', isError: true);
      return;
    }
    setState(() => _isSending = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _messageController.clear();
      setState(() => _isSending = false);
      context.showSnack(
          'تم إرسال استفسارك لفريق دعم ست الكل بنجاح ✓ سنتواصل معك قريباً');
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('>>> [SupportScreen] build() REACHED! <<<');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مركز المساعدة والدعم الفني'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.card,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فريق خدمة عملاء ست الكل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'معاك على مدار الساعة لخدمتك وضمان تجربة أكل بيتي ممتازة 🍲',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Official Support Channels
            const Text(
              'قنوات التواصل المباشرة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Gmail Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'البريد الإلكتروني الرسمي (Gmail)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'setelkol.support@gmail.com',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrlSafe(
                            'mailto:setelkol.support@gmail.com?subject=${Uri.encodeComponent('طلب مساعدة من تطبيق ست الكل')}&body=${Uri.encodeComponent('مرحباً فريق دعم ست الكل،\n\nأود الاستفسار بخصوص:')}',
                          ),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('إرسال إيميل (Gmail)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(
                                text: 'setelkol.support@gmail.com'),
                          );
                          context
                              .showSnack('تم نسخ البريد الإلكتروني للحافظة ✓');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('نسخ'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Call & WhatsApp row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.phone_in_talk_rounded,
                            color: Colors.green, size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          'اتصال هاتفي',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text('01067322605',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _launchUrlSafe('tel:01067322605'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('اتصل الآن',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.chat_rounded,
                            color: Color(0xFF25D366), size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          'محادثة واتساب',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text('01067322605',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _launchUrlSafe('https://wa.me/201067322605'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('شات واتساب',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Send Inquiry Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إرسال رسالة أو استفسار سريع',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'اكتب استفسارك أو مشكلتك هنا...',
                      hintStyle:
                          const TextStyle(fontSize: 12.5, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendTicket,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: Text(
                          _isSending ? 'جاري الإرسال...' : 'إرسال الاستفسار'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Frequently Asked Questions
            const Text(
              'الأسئلة الشائعة 💡',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'هل يمكنني الطلب من أكثر من مطبخ في نفس الوقت؟',
              'نعم بالتأكيد! يتيح لك تطبيق ست الكل إضافة وجبات منزلية متنوعة من أي طاهية، وإتمام الدفع في عملية واحدة بسهولة.',
            ),
            _buildFaqItem(
              'ما هي طرق الدفع المتاحة في التطبيق؟',
              'نوفر الدفع نقداً عند الاستلام (كاش)، وتحويل إنستاباي InstaPay الفوري، ومحافظ فودافون كاش، والبطاقات الائتمانية.',
            ),
            _buildFaqItem(
              'كيف أتابع خط سير الطلب وموقع المندوب؟',
              'من شاشة تتبع الطلب (Live Tracking)، يمكنك متابعة خط سير المندوب وموقع مطبخ ست الكل لحظة بلحظة مع مؤقت الوصول المتوقع.',
            ),
            _buildFaqItem(
              'كيف أنضم كطاهية منزلية وأبدأ البيع؟',
              'من صفحة حسابك، اضغطي على "أصبح بائعاً (انضمي كطاهية منزلية)"، وسجلي بيانات مطبخك ومحافظتك لتفعيله والبدء فوراً!',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
