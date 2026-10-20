import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vendor/presentation/providers/vendor_providers.dart';
import '../providers/customer_providers.dart';

enum PaymentMethod { card, cash, instapay, vodafoneCash }
enum DeliveryType { delivery, pickup }

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _walletReferenceController = TextEditingController();

  PaymentMethod _payment = PaymentMethod.cash;
  DeliveryType _delivery = DeliveryType.delivery;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _walletReferenceController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_delivery == DeliveryType.delivery && _addressController.text.trim().isEmpty) {
      context.showSnack('أدخل عنوان التوصيل بالتفصيل', isError: true);
      return;
    }

    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      context.showSnack('سلة التسوق فارغة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(currentProfileProvider);
      final currentAuthUser = client.auth.currentUser;
      final userId = currentAuthUser?.id ?? profile?.id ?? '00000000-0000-0000-0000-000000000002';

      final orderId = const Uuid().v4();
      final vendorId = cart.vendorId ?? '00000000-0000-0000-0000-000000000001';

      double deliveryFee = 0;
      if (_delivery == DeliveryType.delivery && cart.vendor?.deliveryFee != null) {
        deliveryFee = cart.vendor!.deliveryFee!;
      }

      final totalAmount = cart.subtotal + deliveryFee;

      // Map to PostgreSQL payment_method constraint ('cash', 'instapay', 'vodafone_cash')
      String paymentDbValue;
      switch (_payment) {
        case PaymentMethod.card:
        case PaymentMethod.cash:
          paymentDbValue = 'cash';
          break;
        case PaymentMethod.instapay:
          paymentDbValue = 'instapay';
          break;
        case PaymentMethod.vodafoneCash:
          paymentDbValue = 'vodafone_cash';
          break;
      }

      final deliveryAddr = _delivery == DeliveryType.delivery
          ? _addressController.text.trim()
          : 'استلام من المقر';

      final orderItemsList = cart.items.values.map((item) {
        return {
          'product_id': item.product.id,
          'product_name_snapshot': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'subtotal': item.product.price * item.quantity,
          'products': {
            'name': item.product.name,
            'image_url': item.product.imageUrl,
          },
        };
      }).toList();

      // 1. Always create and persist local OrderModel into DemoDataService immediately
      final newOrder = OrderModel(
        id: orderId,
        status: 'pending',
        totalAmount: totalAmount,
        paymentMethod: paymentDbValue,
        createdAt: DateTime.now(),
        vendorName: cart.vendor?.name ?? 'مطبخ ست الكل (أم أحمد)',
        deliveryAddress: deliveryAddr,
        items: orderItemsList,
      );

      DemoDataService.instance.addCustomerOrder(
        newOrder,
        customerName: profile?.name ?? 'سارة محمود',
      );

      // 2. Safe attempt to sync order into Supabase backend
      try {
        if (currentAuthUser != null) {
          await client.from('orders').insert({
            'id': orderId,
            'customer_id': userId,
            'vendor_id': vendorId,
            'order_status': 'pending',
            'subtotal': cart.subtotal,
            'total_amount': totalAmount,
            'delivery_fee': deliveryFee,
            'fulfillment_type': _delivery == DeliveryType.delivery ? 'delivery' : 'pickup',
            'payment_method': paymentDbValue,
            'payment_status': _payment == PaymentMethod.card ? 'verified' : 'pending',
            'customer_note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          for (final item in cart.items.values) {
            await client.from('order_items').insert({
              'order_id': orderId,
              'product_id': item.product.id,
              'product_name_snapshot': item.product.name,
              'quantity': item.quantity,
              'unit_price': item.product.price,
              'subtotal': item.product.price * item.quantity,
            });
          }
        }
      } catch (supabaseError) {
        debugPrint('[Checkout] Supabase sync skipped or failed (local order safe): $supabaseError');
      }

      // 3. Process payment service log safely
      try {
        final paymentService = ref.read(paymentServiceProvider);
        PaymentGatewayType gatewayType;
        switch (_payment) {
          case PaymentMethod.card:
            gatewayType = PaymentGatewayType.card;
            break;
          case PaymentMethod.cash:
            gatewayType = PaymentGatewayType.cash;
            break;
          case PaymentMethod.instapay:
            gatewayType = PaymentGatewayType.instapay;
            break;
          case PaymentMethod.vodafoneCash:
            gatewayType = PaymentGatewayType.vodafoneCash;
            break;
        }

        await paymentService.processOrderPayment(
          orderId: orderId,
          amount: totalAmount,
          gateway: gatewayType,
          paymentDetails: {
            'wallet_reference': _walletReferenceController.text.trim(),
            'delivery_type': _delivery.name,
          },
        );
      } catch (paymentError) {
        debugPrint('[Checkout] Payment log note: $paymentError');
      }

      // 4. Invalidate provider caches so views update instantly
      ref.invalidate(customerOrdersProvider);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(vendorOrdersListProvider);
      ref.invalidate(vendorEarningsProvider);

      // 5. Clear Cart
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showSnack('تم إرسال طلبك بنجاح! 🎉');
      context.go('/cart/order-confirm/$orderId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showSnack('حدث خطأ أثناء إتمام الطلب: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Type Selection
            Text('طريقة الاستلام', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeChip(
                  label: 'توصيل للمنزل',
                  icon: Icons.delivery_dining,
                  isSelected: _delivery == DeliveryType.delivery,
                  onTap: () => setState(() => _delivery = DeliveryType.delivery),
                ),
                const SizedBox(width: 12),
                _TypeChip(
                  label: 'استلام ذاتي',
                  icon: Icons.storefront_outlined,
                  isSelected: _delivery == DeliveryType.pickup,
                  onTap: () => setState(() => _delivery = DeliveryType.pickup),
                ),
              ],
            ),

            if (_delivery == DeliveryType.delivery) ...[
              const SizedBox(height: 20),
              Text('عنوان التوصيل', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              AppTextField(
                controller: _addressController,
                hint: 'العنوان بالتفصيل (المنطقة، الشارع، المبنى، الشقة)',
                maxLines: 2,
                prefix: const Icon(Icons.location_on_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _noteController,
                hint: 'ملاحظات إضافية للمندوب (اختياري)',
                prefix: const Icon(Icons.note_outlined, size: 20),
              ),
            ],

            const SizedBox(height: 24),
            Text('طريقة الدفع', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            // Online Card Payment
            _PaymentOption(
              label: 'بطاقة ائتمان / فيزا (دفع إلكتروني آمن)',
              icon: Icons.credit_card,
              subtitle: 'دفع مباشر عبر البوابة الإلكترونية',
              isSelected: _payment == PaymentMethod.card,
              onTap: () => setState(() => _payment = PaymentMethod.card),
            ),
            const SizedBox(height: 10),

            // Cash on delivery
            _PaymentOption(
              label: 'كاش عند الاستلام',
              icon: Icons.payments_outlined,
              subtitle: 'الدفع نقداً للمندوب عند الاستلام',
              isSelected: _payment == PaymentMethod.cash,
              onTap: () => setState(() => _payment = PaymentMethod.cash),
            ),
            const SizedBox(height: 10),

            // InstaPay
            _PaymentOption(
              label: 'InstaPay - انستا باي',
              icon: Icons.account_balance_wallet_outlined,
              subtitle: 'تحويل مباشر للحساب البنكي',
              isSelected: _payment == PaymentMethod.instapay,
              onTap: () => setState(() => _payment = PaymentMethod.instapay),
            ),
            const SizedBox(height: 10),

            // Vodafone Cash
            _PaymentOption(
              label: 'فودافون كاش - المحفظة الإلكترونية',
              icon: Icons.phone_android,
              subtitle: 'تحويل عبر رقم المحفظة',
              isSelected: _payment == PaymentMethod.vodafoneCash,
              onTap: () => setState(() => _payment = PaymentMethod.vodafoneCash),
            ),

            if (_payment == PaymentMethod.instapay || _payment == PaymentMethod.vodafoneCash) ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _walletReferenceController,
                hint: 'رقم العملية / الرقم المحول منه',
                prefix: const Icon(Icons.numbers, size: 20),
              ),
            ],

            const SizedBox(height: 28),

            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'المجموع الفرعي', value: '${cart.subtotal.toStringAsFixed(0)} ج.م'),
                  const SizedBox(height: 8),
                  if (_delivery == DeliveryType.delivery)
                    _SummaryRow(
                      label: 'رسوم التوصيل',
                      value: '${(cart.vendor?.deliveryFee ?? 20.0).toStringAsFixed(0)} ج.م',
                    ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'الإجمالي النهائي',
                    value: '${(cart.subtotal + (_delivery == DeliveryType.delivery ? (cart.vendor?.deliveryFee ?? 20.0) : 0)).toStringAsFixed(0)} ج.م',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            AppButton(
              label: 'تأكيد ودفع الطلب',
              onPressed: _placeOrder,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.radio_button_checked, color: AppColors.primary)
            else
              const Icon(Icons.radio_button_unchecked, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTypography.titleMedium : AppTypography.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: isBold ? AppColors.primary : null,
            fontWeight: isBold ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}
