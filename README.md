# Cleversync Parking — Flutter App

## How to Build the APK

### Prerequisites (install on your computer)
1. **Flutter SDK** → https://flutter.dev/docs/get-started/install
   - Choose Windows installer
   - Add flutter/bin to your PATH
2. **Android Studio** → https://developer.android.com/studio
   - Install Android SDK during setup
   - Accept all licenses: `flutter doctor --android-licenses`
3. **Java JDK 17** → Installed automatically with Android Studio

### Quick Check
Open Command Prompt and run:
```
flutter doctor
```
All items should show green ✓

---

### Build Steps

1. **Copy this project folder** to your computer (e.g. `C:\projects\cleversync_parking`)

2. **Open Command Prompt** in the project folder:
   ```
   cd C:\projects\cleversync_parking
   ```

3. **Get dependencies:**
   ```
   flutter pub get
   ```

4. **Build the APK:**
   ```
   flutter build apk --release
   ```

5. **Find your APK at:**
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

6. **Transfer to your Android phone** via USB or WhatsApp and install!

---

### First-Time Phone Setup
- Enable "Install from Unknown Sources" on your Android phone
  - Settings → Security → Unknown Sources → ON
  - (Or Settings → Apps → Special Access → Install Unknown Apps)

---

## App Features

### Entry
- Vehicle number, owner name, phone, model
- Payment status (due/paid/partial)
- Auto token generation (0001-9999 daily)
- Bluetooth thermal printer support
- Duplicate vehicle detection

### Exit (Checkout)
- Search by token number OR vehicle number
- **Security checklist** (mandatory before release):
  - ✅ Bike number verified
  - ✅ Key demonstrated (bike started)
  - ✅ Identity verified
- Auto fee calculation based on duration

### Members / Pass System
- Monthly/Quarterly/Half-Yearly/Annual passes
- Payment method: Cash/UPI/Card/Other
- Expiry tracking with alerts

### Reports
- Filter by Today/Yesterday/This Week/This Month
- Filter by status: All/Parked/Exited
- Search by registration number
- Total records + amount summary

### Dashboard & Analytics
- Currently parked count
- Revenue tracking
- Vehicle-wise breakdown

### Settings
- Business name, address, phone
- UPI ID printed on exit receipt
- Footer messages (e.g. "Key at owner's risk")
- GST setup

### Bluetooth Printer
- Connect any Bluetooth thermal printer
- Prints Entry slip + Exit receipt with UPI ID

---

## Default Login
- Username: `admin`
- Password: `admin123`
(Change in Register screen)

---

## Making Changes Later
All source code is organized as:
```
lib/
  main.dart              ← App entry point
  providers/
    app_provider.dart    ← All data/state logic
  screens/
    login_screen.dart    ← Login
    home_screen.dart     ← Main menu
    entry_screen.dart    ← Vehicle entry
    exit_screen.dart     ← Vehicle checkout
    members_screen.dart  ← Pass members
    reports_screens.dart ← All reports
    setup_screens.dart   ← Settings, rates, printer
  utils/
    database_helper.dart ← SQLite database
    app_theme.dart       ← Colors, fonts
    printer_helper.dart  ← Bluetooth printing
```

To change fees: Edit `rates` table default in `database_helper.dart`
To change colors: Edit `app_theme.dart`
To change app name: Edit `pubspec.yaml` and `AndroidManifest.xml`
