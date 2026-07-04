# Kapai Flutter App — Setup Guide

## Step 1: Install Flutter

1. Go to https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK and extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your PATH
4. Run `flutter doctor` — fix any issues it shows (Android Studio / Xcode)

## Step 2: Create the Flutter project scaffold

Open PowerShell in `C:\Users\sarth\Documents\KAPAI\` and run:

```powershell
flutter create kapai_flutter --org com.kapai --platforms android,ios,web
```

This generates the native platform folders (android/, ios/, web/) and a default lib/main.dart.
Our source files in lib/ will override the generated ones — that's fine.

## Step 3: Install dependencies

```powershell
cd kapai_flutter
flutter pub get
```

## Step 4: Set up Firebase

### 4a. Create a Firebase project
1. Go to https://console.firebase.google.com
2. Create project: **kapai-app**
3. Enable these services:
   - **Authentication** → Sign-in methods → Enable **Phone** and **Email/Password**
   - **Firestore Database** → Start in production mode
   - **Storage** (for menu images later)

### 4b. Connect Firebase to Flutter
Install the FlutterFire CLI:
```powershell
dart pub global activate flutterfire_cli
```

Then configure (run from inside kapai_flutter/):
```powershell
flutterfire configure --project=kapai-app
```
This generates `lib/firebase_options.dart` automatically.

### 4c. Deploy Firestore security rules
Install Firebase CLI if not already installed:
```powershell
npm install -g firebase-tools
firebase login
```

From the `firebase/` folder:
```powershell
cd firebase
firebase init firestore   # point to your kapai-app project
# Copy firestore.rules content is already in firebase/firestore.rules
firebase deploy --only firestore:rules
```

## Step 5: Seed inventory data

From `firebase/functions/`:
```powershell
npm init -y
npm install firebase-admin typescript ts-node @types/node
npx ts-node src/seed_inventory.ts
```
This writes all ~200 items to Firestore.

## Step 6: Create the first Super Admin account

In the Firebase Console:
1. Go to **Authentication** → Add user manually with your email + password
2. Copy the UID shown
3. Go to **Firestore** → Create collection `staff` → Document ID = that UID:
```json
{
  "name": "Your Name",
  "email": "your@email.com",
  "role": "super_admin",
  "assignedCategories": [],
  "permissions": {
    "canManageOrders": true,
    "canManageTakeaway": true,
    "canManageInventory": true,
    "canViewReports": true,
    "canManageMenu": true,
    "canManageStaff": true,
    "canManageVendors": true,
    "canApproveProcurement": true
  },
  "isActive": true,
  "createdAt": [use server timestamp]
}
```

## Step 7: Run the app

```powershell
# Mobile (with emulator or device connected)
flutter run

# Web (admin panel)
flutter run -d chrome
```

## Architecture summary

```
lib/
├── main.dart                   Entry point, Firebase init
├── app.dart                    MaterialApp + GoRouter
├── core/
│   ├── theme/                  Brand colors, typography, Material theme
│   ├── models/                 All Firestore data models
│   ├── services/               Auth + Firestore service classes
│   ├── providers/              Riverpod providers (auth state)
│   └── router/                 go_router config with role-based redirect
├── admin/
│   └── screens/
│       ├── login/              Staff email login
│       ├── shell/              Sidebar nav (responsive: wide/narrow)
│       ├── overview/           Dashboard with live stats
│       ├── orders/             Order board with status updates
│       ├── inventory/          Category-grouped, daily stock checks
│       ├── procurement/        Raise → Approve → Order → Receive flow
│       ├── vendors/            Vendor management, category assignment
│       ├── staff/              IAM — create staff, assign permissions
│       ├── menu_management/    Menu CRUD with availability toggle
│       └── reports/            Revenue and order summaries
└── customer/
    └── screens/
        ├── landing/            App entry point
        ├── auth/               Phone OTP login
        ├── shell/              Bottom nav bar
        ├── home/               Greeting, loyalty card, active orders
        ├── menu/               Category filter, veg toggle, add-to-cart
        ├── cart/               Order summary, dine-in/takeaway, place order
        ├── orders/             Live order history and status
        ├── rewards/            Beans, tiers, how to earn
        └── profile/            Account, history, sign out
```
