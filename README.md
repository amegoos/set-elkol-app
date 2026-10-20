# ست الكل — Set El Kol (Android Mobile App)

> **أكل بيتي من إيد ستات مصر**
> Authentic Homemade Egyptian Food Marketplace for Android

Set El Kol (ست الكل) is a production-ready Android mobile application built with Flutter/Dart and Supabase. It empowers Egyptian women cooks to sell homemade authentic dishes and enables customers to order fresh home-cooked meals with live tracking and flexible payment options.

---

## 🌟 Core Features

- 🎬 **Cinematic Intro Screen**: Hero food presentation featuring authentic Egyptian Molokhia (`molokhia_hero.jpg`), natural steam particle motion, and the headline **"أكل الست المصرية مختلف"**.
- 🔐 **Authentication & Sessions**: Supabase Auth (Email/Password & Google Sign-In) with persistent sessions, password reset, and field validation.
- 👥 **Dual Role System**: Single account support for both Customer (أريد شراء الأكل) and Vendor (أريد بيع الأكل) modes without needing separate user registrations.
- 🍲 **Customer Experience**: Real photography dishes (Molokhia, Koshary, Mahshi, Hawawshi, Mombar, Feteer Meshaltet, Roz Bel Laban), category browsing, search, favorites, cart management, address selection, checkout, live order tracking, notifications, and reviews.
- 👩‍🍳 **Vendor Management**: Product management, real image uploading, availability toggling, pricing, order status pipeline, earnings dashboard, and store settings.
- 🔄 **Real Order Flow**: Live status updates via Supabase Realtime (`Pending` → `Accepted` → `Preparing` → `Ready` → `Out for Delivery` → `Completed`/`Cancelled`).
- 💳 **Real Payment Gateway Architecture**:
  - Online Card / Visa payment processing
  - Cash on delivery
  - InstaPay bank transfer
  - Vodafone Cash mobile wallet
  - Payment details logged to Supabase `payments` table.

---

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart) — Android APK/AAB target
- **State Management**: Riverpod (`flutter_riverpod`, `hooks_riverpod`)
- **Routing**: `go_router`
- **Backend & Database**: Supabase (PostgreSQL, Auth, Storage, Realtime, Row-Level Security)
- **Local Storage**: `shared_preferences` & `hive_flutter`
- **Typography**: Cairo (Google Fonts)

---

## 📁 Repository Structure

```
set_elkol_app/
├── android/               # Android Platform Configuration
├── assets/
│   ├── fonts/             # Cairo Variable Font
│   └── images/            # Licensed Food & Vendor Photography
│       ├── molokhia_hero.jpg
│       ├── koshary.jpg
│       ├── mahshi.jpg
│       ├── hawawshi.jpg
│       ├── mombar.jpg
│       ├── feteer.jpg
│       ├── roz_bel_laban.jpg
│       ├── vendor_om_mohamed.jpg
│       └── vendor_om_ahmed.jpg
├── lib/
│   ├── core/              # Theme, Routing, Network, Services, Widgets
│   └── features/
│       ├── auth/          # Splash, Login, Register, Role Select
│       ├── customer/      # Home, Search, Cart, Checkout, Tracking, Favorites
│       ├── vendor/        # Dashboard, Products, Add/Edit, Orders, Earnings
│       └── notifications/ # User notifications
├── supabase/
│   ├── schema.sql         # Full PostgreSQL Schema & RLS Policies
│   └── seed.sql           # Authentic Egyptian Food & Vendor Seed Data
├── test/
│   └── unit/              # Automated Unit & Model Tests
└── pubspec.yaml
```

---

## 🚀 Setup & Execution Instructions

### 1. Requirements
- Flutter SDK >= 3.29.0
- Android SDK (API 34) & JDK 17+
- Supabase Project

### 2. Environment Setup
Copy `.env.example` to `.env` and fill in your Supabase credentials:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key-here
```

### 3. Supabase Database Configuration
Execute `supabase/schema.sql` followed by `supabase/seed.sql` in your Supabase SQL Editor.

### 4. Running Unit Tests
```bash
flutter test
```

### 5. Building Android APK
```bash
flutter build apk --release
```

---

## 📄 License & Asset Attribution
All photography assets utilized in Set El Kol (`molokhia_hero.jpg`, `koshary.jpg`, `mahshi.jpg`, etc.) are open-licensed high-resolution food assets from Unsplash & Wikimedia Commons (CC BY-SA).
