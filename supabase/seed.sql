-- ============================================================================
-- SET EL KOL (ست الكل) - Seed Data using Authentic Egyptian Homemade Food
-- ============================================================================

-- 1. SEED CATEGORIES
INSERT INTO public.categories (id, name_ar, name_en, icon, display_order) VALUES
('c1000000-0000-0000-0000-000000000001', 'أطباق رئيسية', 'Main Dishes', 'ramen_dining', 1),
('c1000000-0000-0000-0000-000000000002', 'محاشي وطواجن', 'Mahshi & Casseroles', 'soup_kitchen', 2),
('c1000000-0000-0000-0000-000000000003', 'مخبوزات وفطير', 'Bakery & Feteer', 'bakery_dining', 3),
('c1000000-0000-0000-0000-000000000004', 'مشويات وحواوشي', 'Grills & Hawawshi', 'kebab_dining', 4),
('c1000000-0000-0000-0000-000000000005', 'حلويات منزلية', 'Homemade Desserts', 'icecream', 5),
('c1000000-0000-0000-0000-000000000006', 'مشروبات ومربيات', 'Drinks & Jams', 'local_cafe', 6)
ON CONFLICT (id) DO NOTHING;

-- 2. SEED SAMPLE VENDOR PROFILES (Mock user UUIDs for initial demo/test environment)
-- Vendors: أم محمد (مطبخ الخير), أم أحمد (طشة ملخية)

INSERT INTO public.profiles (id, full_name, phone, role) VALUES
('v1000000-0000-0000-0000-000000000001', 'أم محمد المصري', '01012345678', 'both'),
('v1000000-0000-0000-0000-000000000002', 'أم أحمد الشربيني', '01198765432', 'both')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.vendor_profiles (id, business_name, description, logo_url, address, city, rating, total_reviews, total_orders) VALUES
('v1000000-0000-0000-0000-000000000001', 'مطبخ أم محمد للأكل البيتي', 'أكل بيتي مصري أصيل بالسمن البلدي وطشة الملوخية الرهيبة. بنجهز عزومات ومحاشي وشوربة كوارع وحمام محشي.', 'assets/images/vendor_om_mohamed.jpg', 'مدينة نصر - الحي السابع', 'القاهرة', 4.95, 128, 450),
('v1000000-0000-0000-0000-000000000002', 'طشت ورشة - أم أحمد', 'متخصصين في الفطير المشلتت الفلاحي بالزبادي والسمن البلدي، والحواوشي البلدي المحشي على الفحم.', 'assets/images/vendor_om_ahmed.jpg', 'المعادي - شارع 9', 'القاهرة', 4.88, 94, 320)
ON CONFLICT (id) DO NOTHING;

-- 3. SEED AUTHENTIC EGYPTIAN PRODUCTS
INSERT INTO public.products (id, vendor_id, category_id, title_ar, title_en, description_ar, description_en, price, discount_price, preparation_time_minutes, is_available) VALUES
('p1000000-0000-0000-0000-000000000001', 'v1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'طبق ملوخية مصرية بالطشة والشهقة', 'Authentic Egyptian Molokhia with Garlic Ta\'sha', 'ملوخية خضراء طازجة مخروطة بالخرطة البلدي، مطبوخة بشوربة الفراخ البلدي وطشة الثوم والكزبرة.', 'Fresh green molokhia cooked with authentic chicken broth and garlic ta\'sha.', 85.00, 75.00, 30, true),
('p1000000-0000-0000-0000-000000000002', 'v1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000002', 'كيلو مشكل محاشي (ورق عنب + كوسة + باذنجان)', 'Mixed Mahshi (Vine Leaves, Zucchini, Eggplant)', 'مشكل محاشي بيتي بخلطة الأرز بالخضرة الطازجة والطماطم، مطبوخ بالسمن البلدي.', 'Mixed homemade stuffed vegetables with seasoned rice, fresh herbs and samna baladi.', 160.00, 145.00, 60, true),
('p1000000-0000-0000-0000-000000000003', 'v1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000004', 'رغيف حواوشي بلدي بالسمنة والبهارات', 'Authentic Egyptian Hawawshi in Egyptian Bread', 'لحمة بلدي مفرومة طازجة مع البصل والفلفل الأخضر والبهارات المصرية في رغيف بلدي على الفحم.', 'Fresh minced beef with onions and herbs stuffed inside Egyptian bread baked to perfection.', 65.00, NULL, 30, true),
('p1000000-0000-0000-0000-000000000004', 'v1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000003', 'فطيرة مشلتت فلاحي كبير بالزبادي والقشطة', 'Large Feteer Meshaltet with Cream & Honey', 'فطير فلاحي مورق ومخبوز على طريقة القرية المصرية بالسمن البلدي الصافي.', 'Traditional flaky layered Egyptian pastry baked with pure ghee, served with honey or cheese.', 180.00, 160.00, 45, true),
('p1000000-0000-0000-0000-000000000005', 'v1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000002', 'كيلو ممبار بلدي محشي ومحمر', 'Crispy Egyptian Stuffed Mombar', 'ممبار بلدي طازج محشي بخلطة الأرز الطازجة ومحمر حتى القرمشة.', 'Traditional beef intestines stuffed with spiced rice filling and fried crisp.', 190.00, 175.00, 50, true),
('p1000000-0000-0000-0000-000000000006', 'v1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000005', 'طاجن أرز باللبن والمكسرات والقشطة فرن', 'Creamy Baked Roz Bel Laban with Nuts', 'أرز باللبن الجاموسي البلدي ومستكة وقشطة، مخبوز بالفرن ليتحمر الوش.', 'Egyptian rice pudding baked in clay oven with rich cream, mastic and roasted nuts.', 45.00, NULL, 20, true)
ON CONFLICT (id) DO NOTHING;

-- 4. SEED PRODUCT IMAGES
INSERT INTO public.product_images (product_id, image_url, is_primary) VALUES
('p1000000-0000-0000-0000-000000000001', 'assets/images/molokhia_hero.jpg', true),
('p1000000-0000-0000-0000-000000000002', 'assets/images/mahshi.jpg', true),
('p1000000-0000-0000-0000-000000000003', 'assets/images/hawawshi.jpg', true),
('p1000000-0000-0000-0000-000000000004', 'assets/images/feteer.jpg', true),
('p1000000-0000-0000-0000-000000000005', 'assets/images/mombar.jpg', true),
('p1000000-0000-0000-0000-000000000006', 'assets/images/roz_bel_laban.jpg', true)
ON CONFLICT (id) DO NOTHING;
