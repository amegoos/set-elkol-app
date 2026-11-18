import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/category.dart';
import '../domain/entities/product.dart';
import '../domain/entities/vendor.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/order_model.dart';
import '../../features/vendor/presentation/providers/vendor_providers.dart';

/// Predefined authentic Egyptian homemade dish photo presets for instant selection
class DishPhotoPreset {
  const DishPhotoPreset({
    required this.title,
    required this.imageUrl,
    required this.categoryName,
    required this.suggestedPrice,
    required this.suggestedPrepTime,
    required this.suggestedQuantity,
    required this.suggestedDescription,
  });

  final String title;
  final String imageUrl;
  final String categoryName;
  final double suggestedPrice;
  final int suggestedPrepTime;
  final int suggestedQuantity;
  final String suggestedDescription;
}

class DemoDataService extends ChangeNotifier {
  DemoDataService._internal() {
    _initData();
  }

  static final DemoDataService instance = DemoDataService._internal();

  // Curated high quality authentic food image presets for Egyptian home dishes
  static const List<DishPhotoPreset> dishPresets = [
    DishPhotoPreset(
      title: 'محشي مشكل مصري (كرنب وورق عنب وكوسة)',
      imageUrl: 'assets/images/mahshi.jpg',
      categoryName: 'محاشي',
      suggestedPrice: 110.0,
      suggestedPrepTime: 45,
      suggestedQuantity: 15,
      suggestedDescription:
          'تشكيلة محاشي مشكلة (كرنب دايت بالسمنة الفلاحي، ورق عنب بدبس الرمان، وكوسة وبتنجان) بخلطة الأرز المصرية بالكزبرة والشبت.',
    ),
    DishPhotoPreset(
      title: 'ملوخية خضراء بالطشة والفراخ البلدي',
      imageUrl: 'assets/images/molokhia_hero.jpg',
      categoryName: 'أكل مصري',
      suggestedPrice: 135.0,
      suggestedPrepTime: 35,
      suggestedQuantity: 12,
      suggestedDescription:
          'ملوخية خضراء مفرومة طازة مطبوخة بشوربة الفراخ البلدي الدسمة مع طشة الثوم والكزبرة المقرمشة، تقدم مع طبق أرز وشوربة.',
    ),
    DishPhotoPreset(
      title: 'كشري مصري بيتي بالدقة والصلصة الحارة',
      imageUrl: 'assets/images/koshary.jpg',
      categoryName: 'أكل مصري',
      suggestedPrice: 65.0,
      suggestedPrepTime: 25,
      suggestedQuantity: 20,
      suggestedDescription:
          'كشري مصري أصيل بالعدس البني والمكرونة والحمص مع تقلية بصل مقرمشة وصلصة طماطم بلدي ودقة بالخل والثوم.',
    ),
    DishPhotoPreset(
      title: 'حواوشي بلدي مقرمش باللحمة المفرومة',
      imageUrl: 'assets/images/hawawshi.jpg',
      categoryName: 'لحوم',
      suggestedPrice: 75.0,
      suggestedPrepTime: 30,
      suggestedQuantity: 16,
      suggestedDescription:
          'رغيف حواوشي بلدي طازة محشو بلحم بلدي متبل بالبصل والفلفل الأخضر وبهارات الحواوشي ومشوي في الفرن بالسمن البلدي.',
    ),
    DishPhotoPreset(
      title: 'فطير مشلتت فلاحي مورق بالسمن البلدي',
      imageUrl: 'assets/images/feteer.jpg',
      categoryName: 'مخبوزات',
      suggestedPrice: 120.0,
      suggestedPrepTime: 40,
      suggestedQuantity: 8,
      suggestedDescription:
          'فطير مشلتت فلاحي على أصوله مورق بالسمنة البلدي الصافية، يقدم مع عسل أسود وجبنة قديمة وقشطة.',
    ),
    DishPhotoPreset(
      title: 'ممبار بلدي محشي ومحمر مقرمش',
      imageUrl: 'assets/images/mombar.jpg',
      categoryName: 'أكل مصري',
      suggestedPrice: 145.0,
      suggestedPrepTime: 50,
      suggestedQuantity: 10,
      suggestedDescription:
          'كيلو ممبار بلدي طازة محشو بخلطة الأرز بالخضرة والبهارات ومسلوق ثم محمر في السمن البلدي حتى القرمشة.',
    ),
    DishPhotoPreset(
      title: 'أرز باللبن وقشطة بلدي في الفرن',
      imageUrl: 'assets/images/roz_bel_laban.jpg',
      categoryName: 'حلويات',
      suggestedPrice: 45.0,
      suggestedPrepTime: 20,
      suggestedQuantity: 25,
      suggestedDescription:
          'طاجن أرز بلبن كريمي غني بالحليب الطبيعي والقشطة الفلاحي ومحمر الوجه في الفرن ومزين بالمكسرات.',
    ),
    DishPhotoPreset(
      title: 'صينية مكرونة بشاميل باللحمة المفرومة',
      imageUrl:
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=800&q=80',
      categoryName: 'مكرونة',
      suggestedPrice: 125.0,
      suggestedPrepTime: 50,
      suggestedQuantity: 10,
      suggestedDescription:
          'مكرونة قلم بصوص البشاميل الكريمي الغني مع لحمة مفرومة بلدي معصجة بالبهارات والجبنة الموتزاريلا الذهبية.',
    ),
    DishPhotoPreset(
      title: 'وجبة نصف فرخة بلدي محمرة مع أرز وخضار',
      imageUrl:
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=800&q=80',
      categoryName: 'فراخ',
      suggestedPrice: 140.0,
      suggestedPrepTime: 40,
      suggestedQuantity: 18,
      suggestedDescription:
          'نصف فرخة بلدي محمرة في السمنة البلدي حتى القرمشة، مع أرز بالشعرية وطاجن خضار مشكل وشوربة لسان عصفور.',
    ),
    DishPhotoPreset(
      title: 'فرخة بلدي كاملة مشوية بتتبيلة ست الكل',
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=800&q=80',
      categoryName: 'فراخ',
      suggestedPrice: 240.0,
      suggestedPrepTime: 60,
      suggestedQuantity: 8,
      suggestedDescription:
          'دجاجة كاملة بلدي متبلة بالزبادي والليمون والبهارات الشرقية ومشوية في الفرن حتى اللون الذهبي، تكفي 4 أفراد.',
    ),
    DishPhotoPreset(
      title: 'طاجن بامية باللحمة الضاني البلدي',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      categoryName: 'طواجن',
      suggestedPrice: 185.0,
      suggestedPrepTime: 55,
      suggestedQuantity: 7,
      suggestedDescription:
          'بامية صغيرة بلدي مطهية في صلصة الطماطم بالثوم والليمون مع قطع لحم ضاني دايبة من الفرن مباشرة.',
    ),
    DishPhotoPreset(
      title: 'صينية رقاق فلاحي مقرمش باللحمة المفرومة',
      imageUrl:
          'https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=800&q=80',
      categoryName: 'أكل مصري',
      suggestedPrice: 115.0,
      suggestedPrepTime: 40,
      suggestedQuantity: 9,
      suggestedDescription:
          'رقاق مصري مورق ومسقي بالشوربة الدسمة والسمن الفلاحي ومحشو باللحم المفروم المتبل.',
    ),
    DishPhotoPreset(
      title: 'صينية كنافة بالقشطة والشربات الخفيف',
      imageUrl:
          'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?auto=format&fit=crop&w=800&q=80',
      categoryName: 'حلويات',
      suggestedPrice: 130.0,
      suggestedPrepTime: 30,
      suggestedQuantity: 10,
      suggestedDescription:
          'كنافة ذهبية مقرمشة محشية قشطة بلدي طازة ومسقية بشربات خفيف مزينة بالمكسرات.',
    ),
  ];

  late List<Category> _categories;
  late List<Vendor> _vendors;
  late List<Map<String, dynamic>> _rawProducts;
  late List<VendorOrder> _vendorOrders;
  late List<OrderModel> _customerOrders;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Vendor> get vendors => List.unmodifiable(_vendors);
  List<Map<String, dynamic>> get rawProducts => List.unmodifiable(_rawProducts);
  List<VendorOrder> get vendorOrders => List.unmodifiable(_vendorOrders);
  List<OrderModel> get customerOrders => List.unmodifiable(_customerOrders);

  List<Product> get products {
    return _rawProducts.map((json) {
      final vendorMatch = _vendors.firstWhere(
        (v) => v.id == json['vendor_id'],
        orElse: () => _vendors.first,
      );
      final categoryMatch = _categories.firstWhere(
        (c) => c.id == json['category_id'],
        orElse: () => _categories.first,
      );

      return Product(
        id: json['id'] as String,
        vendorId: json['vendor_id'] as String,
        categoryId: json['category_id'] as String? ?? 'cat-1',
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] as String?,
        additionalImages: const [],
        availableQuantity: json['available_quantity'] as int?,
        preparationTimeMinutes: json['preparation_time_minutes'] as int? ?? 30,
        isAvailable: json['is_available'] as bool? ?? true,
        isFeatured: json['is_featured'] as bool? ?? false,
        isVegetarian: json['is_vegetarian'] as bool? ?? false,
        isSpicy: json['is_spicy'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
        vendor: vendorMatch,
        category: categoryMatch,
      );
    }).toList();
  }

  void _initData() {
    _categories = [
      const Category(
          id: 'cat-1', name: 'أكل مصري', nameEn: 'Egyptian Food', sortOrder: 1),
      const Category(
          id: 'cat-2', name: 'محاشي', nameEn: 'Mahshi', sortOrder: 2),
      const Category(
          id: 'cat-3', name: 'طواجن', nameEn: 'Tagines', sortOrder: 3),
      const Category(
          id: 'cat-4', name: 'فراخ', nameEn: 'Chicken', sortOrder: 4),
      const Category(id: 'cat-5', name: 'لحوم', nameEn: 'Meat', sortOrder: 5),
      const Category(
          id: 'cat-6', name: 'مكرونة', nameEn: 'Pasta', sortOrder: 6),
      const Category(
          id: 'cat-7', name: 'حلويات', nameEn: 'Desserts', sortOrder: 7),
      const Category(
          id: 'cat-8', name: 'مخبوزات', nameEn: 'Baked Goods', sortOrder: 8),
      const Category(
          id: 'cat-9', name: 'أكل صحي', nameEn: 'Healthy Food', sortOrder: 9),
      const Category(
          id: 'cat-10', name: 'فطار', nameEn: 'Breakfast', sortOrder: 10),
      const Category(
          id: 'cat-11',
          name: 'وجبات عائلية',
          nameEn: 'Family Meals',
          sortOrder: 11),
    ];

    _vendors = [
      Vendor(
        id: '00000000-0000-0000-0000-000000000001',
        name: 'مطبخ ست الكل (أم أحمد)',
        description:
            'أكل بيتي مصري أصيل بالسمنة البلدي والنَفَس الطيب ❤️ — خبرة ٢٠ سنة في العزومات والأكلات الشعبية.',
        logoUrl: 'assets/images/vendor_om_ahmed.jpg',
        governorate: 'القاهرة',
        area: 'مدينة نصر والتجمع',
        rating: 4.9,
        totalReviews: 148,
        deliveryFee: 20.0,
        minOrder: 80.0,
        deliveryRadiusKm: 10.0,
        isActive: true,
        offersDelivery: true,
        offersPickup: true,
        avgPrepTimeMinutes: 45,
        latitude: 30.0444,
        longitude: 31.2357,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Vendor(
        id: '00000000-0000-0000-0000-000000000010',
        name: 'طبيخ زمان (الحاجة فاطمة)',
        description:
            'طواجن فخار ومحاشي بلدي على الكانون، سمن فلاحي ومكونات طازة يومياً.',
        logoUrl: 'assets/images/vendor_om_mohamed.jpg',
        governorate: 'الجيزة',
        area: 'الدقي والمهندسين',
        rating: 4.8,
        totalReviews: 92,
        deliveryFee: 25.0,
        minOrder: 100.0,
        deliveryRadiusKm: 8.0,
        isActive: true,
        offersDelivery: true,
        offersPickup: true,
        avgPrepTimeMinutes: 50,
        latitude: 30.0333,
        longitude: 31.2167,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Vendor(
        id: '00000000-0000-0000-0000-000000000011',
        name: 'أكلات أم مريم البيتي',
        description:
            'متخصصون في المكرونات البشاميل، الكفتة المشوية، والمخبوزات والحلويات الشرقية.',
        logoUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        governorate: 'القاهرة',
        area: 'مصر الجديدة',
        rating: 4.7,
        totalReviews: 65,
        deliveryFee: 20.0,
        minOrder: 70.0,
        deliveryRadiusKm: 7.0,
        isActive: true,
        offersDelivery: true,
        offersPickup: true,
        avgPrepTimeMinutes: 40,
        latitude: 30.0626,
        longitude: 31.2856,
        isVerified: false,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    final now = DateTime.now();
    _rawProducts = [
      {
        'id': 'prod-1',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-2',
        'name': 'محشي مشكل مصري (كرنب وورق عنب وكوسة)',
        'description':
            'تشكيلة محاشي مشكلة (كرنب دايت بالسمنة الفلاحي، ورق عنب بدبس الرمان، وكوسة وبتنجان) بخلطة الأرز المصرية بالكزبرة والشبت.',
        'price': 110.0,
        'image_url': 'assets/images/mahshi.jpg',
        'available_quantity': 15,
        'preparation_time_minutes': 45,
        'is_available': true,
        'is_featured': true,
        'is_vegetarian': false,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'prod-2',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-1',
        'name': 'ملوخية خضراء بالطشة والفراخ البلدي',
        'description':
            'ملوخية خضراء مفرومة طازة مطبوخة بشوربة الفراخ البلدي الدسمة مع طشة الثوم والكزبرة المقرمشة، تقدم مع طبق أرز وشوربة.',
        'price': 135.0,
        'image_url': 'assets/images/molokhia_hero.jpg',
        'available_quantity': 12,
        'preparation_time_minutes': 35,
        'is_available': true,
        'is_featured': true,
        'is_vegetarian': false,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'id': 'prod-3',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-1',
        'name': 'كشري مصري أصيل بالدقة والتقلية',
        'description':
            'كشري مصري بيتي بالعدس البني والمكرونة والحمص مع تقلية بصل مقرمشة وصلصة طماطم بلدي ودقة بالخل والثوم.',
        'price': 65.0,
        'image_url': 'assets/images/koshary.jpg',
        'available_quantity': 20,
        'preparation_time_minutes': 25,
        'is_available': true,
        'is_featured': true,
        'is_vegetarian': true,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'prod-4',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-5',
        'name': 'حواوشي بلدي مقرمش باللحمة المفرومة',
        'description':
            'رغيف حواوشي بلدي طازة محشو بلحم بلدي متبل بالبصل والفلفل الأخضر وبهارات الحواوشي ومشوي في الفرن بالسمن البلدي.',
        'price': 75.0,
        'image_url': 'assets/images/hawawshi.jpg',
        'available_quantity': 18,
        'preparation_time_minutes': 30,
        'is_available': true,
        'is_featured': true,
        'is_vegetarian': false,
        'is_spicy': true,
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'prod-5',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-8',
        'name': 'فطير مشلتت فلاحي مورق بالسمن البلدي',
        'description':
            'فطير مشلتت فلاحي على أصوله مورق بالسمنة البلدي الصافية، يقدم مع عسل أسود وجبنة قديمة وقشطة.',
        'price': 120.0,
        'image_url': 'assets/images/feteer.jpg',
        'available_quantity': 8,
        'preparation_time_minutes': 40,
        'is_available': true,
        'is_featured': true,
        'is_vegetarian': false,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'prod-6',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-1',
        'name': 'ممبار بلدي محشي ومحمر مقرمش',
        'description':
            'كيلو ممبار بلدي طازة محشو بخلطة الأرز بالخضرة والبهارات ومسلوق ثم محمر في السمن البلدي حتى القرمشة.',
        'price': 145.0,
        'image_url': 'assets/images/mombar.jpg',
        'available_quantity': 10,
        'preparation_time_minutes': 50,
        'is_available': true,
        'is_featured': false,
        'is_vegetarian': false,
        'is_spicy': true,
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'prod-7',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-7',
        'name': 'أرز باللبن وقشطة بلدي في الفرن',
        'description':
            'طاجن أرز بلبن كريمي غني بالحليب الطبيعي والقشطة الفلاحي ومحمر الوجه في الفرن ومزين بالمكسرات.',
        'price': 45.0,
        'image_url': 'assets/images/roz_bel_laban.jpg',
        'available_quantity': 25,
        'preparation_time_minutes': 20,
        'is_available': true,
        'is_featured': false,
        'is_vegetarian': true,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(hours: 18)).toIso8601String(),
        'updated_at': now.subtract(const Duration(hours: 18)).toIso8601String(),
      },
      {
        'id': 'prod-8',
        'vendor_id': '00000000-0000-0000-0000-000000000001',
        'category_id': 'cat-7',
        'name': 'صينية كنافة بالقشطة والشربات الخفيف',
        'description':
            'كنافة ذهبية مقرمشة محشية قشطة بلدي طازة ومسقية بشربات خفيف مزينة بالمكسرات.',
        'price': 130.0,
        'image_url':
            'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?auto=format&fit=crop&w=800&q=80',
        'available_quantity': 10,
        'preparation_time_minutes': 30,
        'is_available': true,
        'is_featured': false,
        'is_vegetarian': true,
        'is_spicy': false,
        'created_at': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'updated_at': now.subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    _vendorOrders = [
      VendorOrder(
        id: 'ord-101',
        status: 'preparing',
        totalAmount: 385.0,
        paymentMethod: 'instapay',
        createdAt: now.subtract(const Duration(minutes: 35)),
        customerName: 'سارة محمود',
        deliveryAddress: 'شارع عباس العقاد، عمارة 14، الدور 4، مدينة نصر',
        items: [
          {
            'quantity': 2,
            'unit_price': 110.0,
            'products': {'name': 'محشي مشكل مصري'},
          },
          {
            'quantity': 1,
            'unit_price': 140.0,
            'products': {'name': 'وجبة نصف فرخة بلدي محمرة'},
          },
        ],
      ),
      VendorOrder(
        id: 'ord-102',
        status: 'pending',
        totalAmount: 260.0,
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(minutes: 12)),
        customerName: 'محمد طارق',
        deliveryAddress: 'شارع مصطفى النحاس، تقاطع مكرم عبيد',
        items: [
          {
            'quantity': 1,
            'unit_price': 135.0,
            'products': {'name': 'ملوخية خضراء بالطشة والفراخ'},
          },
          {
            'quantity': 1,
            'unit_price': 125.0,
            'products': {'name': 'صينية مكرونة بشاميل باللحمة'},
          },
        ],
      ),
      VendorOrder(
        id: 'ord-103',
        status: 'completed',
        totalAmount: 480.0,
        paymentMethod: 'vodafone_cash',
        createdAt: now.subtract(const Duration(hours: 3)),
        customerName: 'نورا إبراهيم',
        deliveryAddress: 'التجمع الخامس، الحي الأول، فيلا 23',
        items: [
          {
            'quantity': 2,
            'unit_price': 240.0,
            'products': {'name': 'فرخة بلدي كاملة مشوية بتتبيلة ست الكل'},
          },
        ],
      ),
      VendorOrder(
        id: 'ord-104',
        status: 'completed',
        totalAmount: 295.0,
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(hours: 5)),
        customerName: 'أحمد سعيد',
        deliveryAddress: 'مصر الجديدة، ميدان الحجاز',
        items: [
          {
            'quantity': 1,
            'unit_price': 185.0,
            'products': {'name': 'طاجن بامية باللحمة الضاني'},
          },
          {
            'quantity': 1,
            'unit_price': 110.0,
            'products': {'name': 'محشي مشكل مصري'},
          },
        ],
      ),
    ];

    _customerOrders = [
      OrderModel(
        id: 'ord-101',
        status: 'preparing',
        totalAmount: 385.0,
        paymentMethod: 'instapay',
        createdAt: now.subtract(const Duration(minutes: 35)),
        vendorName: 'مطبخ ست الكل (أم أحمد)',
        deliveryAddress: 'شارع عباس العقاد، عمارة 14، الدور 4، مدينة نصر',
        items: [
          {
            'quantity': 2,
            'unit_price': 110.0,
            'products': {'name': 'محشي مشكل مصري'},
          },
          {
            'quantity': 1,
            'unit_price': 140.0,
            'products': {'name': 'وجبة نصف فرخة بلدي محمرة'},
          },
        ],
      ),
      OrderModel(
        id: 'ord-102',
        status: 'pending',
        totalAmount: 260.0,
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(minutes: 12)),
        vendorName: 'طبيخ زمان (الحاجة فاطمة)',
        deliveryAddress: 'شارع مصطفى النحاس، تقاطع مكرم عبيد',
        items: [
          {
            'quantity': 1,
            'unit_price': 135.0,
            'products': {'name': 'ملوخية خضراء بالطشة والفراخ'},
          },
          {
            'quantity': 1,
            'unit_price': 125.0,
            'products': {'name': 'صينية مكرونة بشاميل باللحمة'},
          },
        ],
      ),
      OrderModel(
        id: 'ord-103',
        status: 'completed',
        totalAmount: 480.0,
        paymentMethod: 'vodafone_cash',
        createdAt: now.subtract(const Duration(hours: 3)),
        vendorName: 'مطبخ ست الكل (أم أحمد)',
        deliveryAddress: 'التجمع الخامس، الحي الأول، فيلا 23',
        items: [
          {
            'quantity': 2,
            'unit_price': 240.0,
            'products': {'name': 'فرخة بلدي كاملة مشوية بتتبيلة ست الكل'},
          },
        ],
      ),
    ];
  }

  OrderModel? getCustomerOrderById(String orderId) {
    try {
      return _customerOrders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  void addCustomerOrder(OrderModel order, {String? customerName}) {
    // 1. Add to customer orders at beginning
    _customerOrders.insert(0, order);

    // 2. Also add to vendor orders so vendor dashboard receives it immediately
    final vendorOrder = VendorOrder(
      id: order.id,
      status: order.status,
      totalAmount: order.totalAmount,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      customerName: customerName ?? 'عميل جديد (ست الكل)',
      deliveryAddress: order.deliveryAddress ?? 'توصيل للمنزل',
      items: order.items,
    );
    _vendorOrders.insert(0, vendorOrder);

    notifyListeners();
  }

  void addOrUpdateProduct(Map<String, dynamic> data) {
    final existingIndex = _rawProducts.indexWhere((p) => p['id'] == data['id']);
    if (existingIndex >= 0) {
      _rawProducts[existingIndex] = {
        ..._rawProducts[existingIndex],
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } else {
      final newId =
          data['id'] ?? 'prod-${DateTime.now().millisecondsSinceEpoch}';
      _rawProducts.insert(0, {
        ...data,
        'id': newId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    notifyListeners();
  }

  void deleteProduct(String productId) {
    _rawProducts.removeWhere((p) => p['id'] == productId);
    notifyListeners();
  }

  void toggleProductAvailability(String productId, bool isAvailable) {
    final index = _rawProducts.indexWhere((p) => p['id'] == productId);
    if (index >= 0) {
      _rawProducts[index]['is_available'] = isAvailable;
      _rawProducts[index]['updated_at'] = DateTime.now().toIso8601String();
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final vIndex = _vendorOrders.indexWhere((o) => o.id == orderId);
    if (vIndex >= 0) {
      _vendorOrders[vIndex].status = newStatus;
    }

    final cIndex = _customerOrders.indexWhere((o) => o.id == orderId);
    if (cIndex >= 0) {
      _customerOrders[cIndex].status = newStatus;
    }

    notifyListeners();
  }
}

final demoDataServiceProvider = ChangeNotifierProvider<DemoDataService>((ref) {
  return DemoDataService.instance;
});
