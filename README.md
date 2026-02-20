# PDF Library App

A modern, dark-themed Flutter PDF reader with tab navigation and bottom sheet actions.

## Project Structure

```text
lib/
├── core/
│   └── app_theme.dart          # All colors, text styles, dimensions
├── data/
│   ├── models/
│   │   └── pdf_file_model.dart # PDF data model
│   └── repositories/
│       └── pdf_repository.dart # File scanning & deletion logic
├── logic/
│   └── controllers/
│       └── pdf_library_controller.dart  # Business logic (ChangeNotifier)
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart        # 3-tab main screen
│   │   └── pdf_viewer_screen.dart  # Full-screen PDF viewer
│   └── widgets/
│       ├── pdf_card.dart           # Custom PDF card (no ListTile)
│       ├── pdf_list_tab.dart       # Reusable tab list + dialogs
│       └── pdf_options_modal.dart  # Bottom sheet modal
└── main.dart
```

## Setup

1. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

1. Set minimum SDK in `android/app/build.gradle`:

```gradle
minSdkVersion 21
```

1. For Android 11+ (API 30+), add in `AndroidManifest.xml` inside `<application>`:

```xml
android:requestLegacyExternalStorage="true"
```

1. Run:

```bash
flutter pub get
flutter run
```

## Features

- 📁 **3 Tabs**: On Device / Favourites / Recent
- 🔍 **Search** PDFs by name
- ⭐ **Star/Favourite** PDFs
- 📤 **Share** via OS share sheet
- 🗑️ **Delete** with confirmation dialog
- ℹ️ **View Info** (path, size, dates)
- 🌙 **Dark themed** — all colors in `app_theme.dart`
