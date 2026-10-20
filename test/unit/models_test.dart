import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/features/customer/data/models/product_model.dart';
import 'package:set_elkol_app/features/customer/data/models/category_model.dart';

void main() {
  group('Models Unit Tests', () {
    test('CategoryModel correctly parses JSON data', () {
      final json = {
        'id': 'cat-123',
        'name': 'أطباق رئيسية',
        'name_en': 'Main Dishes',
        'icon_url': 'ramen_dining',
        'sort_order': 1,
      };

      final category = CategoryModel.fromJson(json);
      expect(category.id, equals('cat-123'));
      expect(category.name, equals('أطباق رئيسية'));
      expect(category.nameEn, equals('Main Dishes'));
      expect(category.iconUrl, equals('ramen_dining'));
    });

    test('ProductModel calculates formatted price correctly', () {
      final json = {
        'id': 'p-1',
        'vendor_id': 'v-1',
        'category_id': 'cat-1',
        'name': 'ملوخية مصري',
        'price': 85.0,
        'is_available': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final product = ProductModel.fromJson(json);
      expect(product.price, equals(85.0));
      expect(product.name, equals('ملوخية مصري'));
      expect(product.isAvailable, isTrue);
    });
  });
}
