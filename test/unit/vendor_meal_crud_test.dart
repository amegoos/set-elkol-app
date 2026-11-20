import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/core/data/demo_data_service.dart';
import 'package:set_elkol_app/core/domain/entities/order_model.dart';
import 'package:set_elkol_app/core/domain/entities/product.dart';
import 'package:set_elkol_app/core/domain/entities/user_profile.dart';
import 'package:set_elkol_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:set_elkol_app/features/customer/presentation/providers/customer_providers.dart';
import 'package:set_elkol_app/features/vendor/presentation/providers/vendor_providers.dart';
import 'package:set_elkol_app/features/vendor/presentation/screens/vendor_products_screen.dart';

void main() {
  group('Vendor Menu Management CRUD & Security Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. ADD MEAL: Successfully adds a meal and validates required fields',
        () async {
      final service = container.read(vendorProductServiceProvider);

      // Validation test: Missing name throws exception
      expect(
        () => service.addMeal({
          'name': '',
          'price': 120.0,
          'category_id': 'cat-1',
        }),
        throwsA(isA<Exception>()),
      );

      // Validation test: Price <= 0 throws exception
      expect(
        () => service.addMeal({
          'name': 'طاجن بامية باللحمة الضاني',
          'price': 0.0,
          'category_id': 'cat-1',
        }),
        throwsA(isA<Exception>()),
      );

      // Successful add
      final newMealId = await service.addMeal({
        'name': 'طاجن بامية باللحمة الضاني',
        'price': 160.0,
        'category_id': 'cat-1',
        'image_url': 'https://images.unsplash.com/photo-test',
        'vendor_id': 'vendor-test-001',
      });

      expect(newMealId, isNotEmpty);

      // Verify meal is saved in catalog and accessible
      final products = DemoDataService.instance.rawProducts;
      final addedMeal = products.firstWhere((p) => p['id'] == newMealId);
      expect(addedMeal['name'], 'طاجن بامية باللحمة الضاني');
      expect(addedMeal['price'], 160.0);
      expect(addedMeal['is_deleted'], false);
    });

    test('2. EDIT MEAL: Updates name, price, and image correctly', () async {
      final service = container.read(vendorProductServiceProvider);

      // Add meal first
      final mealId = await service.addMeal({
        'name': 'حمام محشي أرز بالكبد والقوانص',
        'price': 180.0,
        'category_id': 'cat-1',
        'vendor_id': 'vendor-test-001',
        'image_url': 'https://images.unsplash.com/photo-pigeon-1',
      });

      // Edit meal
      await service.editMeal(
        productId: mealId,
        updates: {
          'name': 'حمام محشي فريك مصري أصيل',
          'price': 210.0,
          'image_url': 'https://images.unsplash.com/photo-pigeon-2',
        },
      );

      final products = DemoDataService.instance.rawProducts;
      final updatedMeal = products.firstWhere((p) => p['id'] == mealId);
      expect(updatedMeal['name'], 'حمام محشي فريك مصري أصيل');
      expect(updatedMeal['price'], 210.0);
      expect(updatedMeal['image_url'],
          'https://images.unsplash.com/photo-pigeon-2');
    });

    test(
        '3. DELETE MEAL (No orders): Deletes meal and removes from active catalog',
        () async {
      final service = container.read(vendorProductServiceProvider);

      final mealId = await service.addMeal({
        'name': 'شوربة كوارع بالخل والثوم',
        'price': 140.0,
        'category_id': 'cat-1',
        'vendor_id': 'vendor-test-001',
      });

      expect(DemoDataService.instance.rawProducts.any((p) => p['id'] == mealId),
          isTrue);

      // Delete meal
      final success = await service.deleteMeal(mealId);
      expect(success, isTrue);

      // Verify removed from active products
      expect(
          DemoDataService.instance.rawProducts.any((p) => p['id'] == mealId),
          isFalse);
    });

    test(
        '4. PRESERVE HISTORICAL ORDERS: Deleting a meal preserves historical order snapshot',
        () async {
      final service = container.read(vendorProductServiceProvider);

      final mealId = await service.addMeal({
        'name': 'صينية بطاطس بالفراخ البلدي',
        'price': 150.0,
        'category_id': 'cat-1',
        'vendor_id': 'vendor-test-001',
      });

      // Simulate a customer order created with this meal
      final order = OrderModel(
        id: 'ord-hist-999',
        status: 'delivered',
        totalAmount: 150.0,
        paymentMethod: 'cash',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        vendorName: 'مطبخ أم أحمد',
        deliveryAddress: 'الدقي - الجيزة',
        items: [
          {
            'product_id': mealId,
            'product_name_snapshot': 'صينية بطاطس بالفراخ البلدي',
            'unit_price': 150.0,
            'quantity': 1,
            'subtotal': 150.0,
          }
        ],
      );

      DemoDataService.instance.addCustomerOrder(order);

      // Has historical orders check
      final hasHistory = await service.hasHistoricalOrders(mealId);
      expect(hasHistory, isTrue);

      // Delete the meal
      await service.deleteMeal(mealId);

      // 1. Historical order items MUST remain 100% intact
      final customerOrders = DemoDataService.instance.customerOrders;
      final savedOrder = customerOrders.firstWhere((o) => o.id == 'ord-hist-999');
      expect(savedOrder.items.length, 1);
      expect(savedOrder.items.first['product_id'], mealId);
      expect(savedOrder.items.first['product_name_snapshot'],
          'صينية بطاطس بالفراخ البلدي');

      // 2. Active catalog MUST NOT show the deleted meal
      expect(
          DemoDataService.instance.products.any((p) => p.id == mealId), isFalse);
    });

    test(
        '5. CART INTEGRATION: Deleted or unavailable meals cannot be added to cart',
        () {
      final cartNotifier = container.read(cartProvider.notifier);

      final deletedMeal = Product(
        id: 'del-prod-101',
        vendorId: 'vendor-1',
        categoryId: 'cat-1',
        name: 'وجبة محذوفة',
        price: 90.0,
        isAvailable: true,
        isFeatured: false,
        isVegetarian: false,
        isSpicy: false,
        isDeleted: true, // Marked deleted
        additionalImages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Attempt adding deleted meal
      final added = cartNotifier.addItem(deletedMeal);
      expect(added, isFalse);

      final cartState = container.read(cartProvider);
      expect(cartState.items.containsKey('del-prod-101'), isFalse);
    });

    testWidgets('6. UI: VendorProductsScreen displays Edit and Delete buttons',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myProductsProvider.overrideWith((ref) => [
                  {
                    'id': 'test-prod-1',
                    'name': 'كشري مصري بالدقة والشطة',
                    'price': 45.0,
                    'is_available': true,
                    'is_deleted': false,
                  }
                ]),
          ],
          child: const MaterialApp(
            home: VendorProductsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify product tile info
      expect(find.text('كشري مصري بالدقة والشطة'), findsOneWidget);
      expect(find.text('45 ج.م'), findsOneWidget);

      // Verify Edit icon button exists
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Verify Delete icon button exists
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap Delete icon button to trigger confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('حذف الأكلة من المنيو'), findsOneWidget);
      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    test(
        '7. SECURITY: Unauthorized vendor cannot edit another vendor meal',
        () async {
      final service = container.read(vendorProductServiceProvider);

      // Create meal owned by 'vendor-kitchen-alpha'
      final mealId = await service.addMeal({
        'name': 'طاجن لحمة بالبصل قاورما',
        'price': 190.0,
        'category_id': 'cat-1',
        'vendor_id': 'vendor-kitchen-alpha',
      });

      // Override container with an authenticated user 'vendor-kitchen-beta' (not admin, not owner)
      final unauthorizedContainer = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWithValue(UserProfile(
            id: 'vendor-kitchen-beta',
            name: 'مطبخ بيتا',
            role: UserRole.vendor,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )),
        ],
      );

      final unauthorizedService =
          unauthorizedContainer.read(vendorProductServiceProvider);

      await expectLater(
        unauthorizedService.editMeal(
          productId: mealId,
          updates: {'name': 'محاولة تعديل غير مصرح بها'},
        ),
        throwsA(predicate((e) =>
            e.toString().contains('غير مصرح لك بتعديل هذه الأكلة'))),
      );

      unauthorizedContainer.dispose();
    });

    test(
        '8. SECURITY: Unauthorized vendor cannot delete another vendor meal',
        () async {
      final service = container.read(vendorProductServiceProvider);

      final mealId = await service.addMeal({
        'name': 'صينية جلاش باللحمة المفرومة',
        'price': 130.0,
        'category_id': 'cat-1',
        'vendor_id': 'vendor-kitchen-alpha',
      });

      // Override container with an authenticated user 'vendor-kitchen-beta'
      final unauthorizedContainer = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWithValue(UserProfile(
            id: 'vendor-kitchen-beta',
            name: 'مطبخ بيتا',
            role: UserRole.vendor,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )),
        ],
      );

      final unauthorizedService =
          unauthorizedContainer.read(vendorProductServiceProvider);

      await expectLater(
        unauthorizedService.deleteMeal(mealId),
        throwsA(predicate((e) =>
            e.toString().contains('غير مصرح لك بحذف هذه الأكلة'))),
      );

      unauthorizedContainer.dispose();
    });
  });
}
