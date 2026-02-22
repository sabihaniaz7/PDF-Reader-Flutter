# PDF Reader

A modern, dark-themed PDF reader app built with Flutter.
Browse, organise, and read all PDF files stored on your device.

![Flutter](https://img.shields.io/badge/Flutter-3.38.6-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightpink)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

| Feature | Description |
| --- | --- |
| 📁 **Auto PDF Discovery** | Scans your entire device storage for PDF files on first launch |
| ⚡ **Instant Reopen** | After first scan, loads instantly from local cache — no rescan on every open |
| ⭐ **Favourites** | Star any PDF; persists across app restarts |
| 🕐 **Recent Files** | Tracks last-opened time; survives app close |
| 🌙 **Night / Day Mode** | Toggle inside the PDF viewer per document |
| 📊 **Sort Options** | Sort by Name, Date, or File Size (ascending/descending) |
| 🔍 **Search** | Filter PDFs by filename instantly |
| 🗑️ **Delete** | Remove PDFs from device with confirmation |
| 📤 **Share** | Share any PDF via the OS share sheet |
| ℹ️ **File Info** | View path, size, and dates |
| 📖 **Vertical Scroll** | Pages scroll naturally top-to-bottom with snap |
| 🔢 **Page Indicator** | Floating overlay showing current/total pages; tap to jump |
| 📂 **Open With** | Appears in Android "Open With" when tapping any `.pdf` file |
| 🔄 **Manual Refresh** | Rescan device for newly added PDFs via refresh button |

---

## 📸 Screenshots

> Add your screenshots here after building the app.

---

## 🗂️ Project Structure

```text
lib/
├── core/
│   └── app_theme.dart               # All colours, text styles, dimensions
├── data/
│   ├── models/
│   │   ├── pdf_file_model.dart      # Data model with JSON serialisation
│   │   └── sort_option.dart         # Sort enum + display labels
│   └── repositories/
│       ├── pdf_repository.dart      # Device file scanning & deletion
│       └── pdf_storage_service.dart # SharedPreferences persistence layer
├── logic/
│   └── controllers/
│       └── pdf_library_controller.dart  # All business logic + PdfViewerController
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart         # 3-tab main screen with sort & search
│   │   └── pdf_viewer_screen.dart   # Full-screen reader with night mode
│   └── widgets/
│       ├── pdf_card.dart            # Custom card (no ListTile)
│       ├── pdf_list_tab.dart        # Reusable tab body + dialogs
│       └── pdf_options_modal.dart   # Bottom sheet with actions
└── main.dart                        # App entry + "Open With" intent handling
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android SDK (minSdkVersion 21) or Xcode for iOS

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/pdf_library.git
cd pdf_library

# 2. Install dependencies
flutter pub get

# 3. Run on your device
flutter run
```

---

## ⚙️ Android Setup

### 1. AndroidManifest.xml

Replace `android/app/src/main/AndroidManifest.xml` with the content
from `docs/AndroidManifest.xml` in this repo.

Key permissions added:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

Intent filters for "Open With":

```xml
<!-- file:// scheme (MIUI File Manager) -->
<intent-filter android:priority="1">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:scheme="file" android:mimeType="application/pdf"/>
</intent-filter>

<!-- content:// scheme (Android 7+, Downloads, Gmail, WhatsApp) -->
<intent-filter android:priority="1">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:scheme="content" android:mimeType="application/pdf"/>
</intent-filter>
```

### 2. file_paths.xml

Create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <files-path name="files" path="."/>
    <cache-path name="cache" path="."/>
</paths>
```

### 3. build.gradle

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## 🍎 iOS Setup

Add to `ios/Runner/Info.plist` inside the main `<dict>`:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>PDF Document</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.adobe.pdf</string>
        </array>
    </dict>
</array>
<key>NSDocumentsFolderUsageDescription</key>
<string>PDF Library needs access to your documents to find PDF files.</string>
```

---

## 📦 Dependencies

| Package | Purpose |
| --- | --- |
| `flutter_pdfview` | Render PDF files natively |
| `provider` | State management |
| `shared_preferences` | Local persistence (favourites, recents, file cache) |
| `permission_handler` | Runtime storage permissions |
| `external_path` | Get external storage path on Android |
| `share_plus` | OS share sheet |
| `receive_sharing_intent` | Handle "Open With" from file manager |
| `path_provider` | Documents directory on iOS |
| `path` | File path utilities |

---

## 🏗️ Architecture

Clean separation of concerns across three layers:

```text

Data Layer          →  Models + Repositories
Logic Layer         →  Controllers (ChangeNotifier / Provider)
UI Layer            →  Screens + Widgets
```

**No business logic in UI files.**
**No hardcoded colours or strings in widgets** — everything references `app_theme.dart`.

### Local Storage Strategy

```text
First launch   →  Scan device  →  Save to SharedPreferences
Every reopen   →  Load from SharedPreferences  (instant, no scan)
New PDFs added →  Tap ↻ Refresh  →  Rescan + merge saved state
Star a PDF     →  Update SharedPreferences immediately
Open a PDF     →  Save lastOpened timestamp immediately
```

---

## 🤝 Contributing

Pull requests are welcome. For major changes, open an issue first.

---
