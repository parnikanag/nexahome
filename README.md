# NexaHome — Smart Home Control App

**App-only source ZIP.** Contains the mobile + desktop Flutter application, Firebase/cloud integration, model/unit tests, setup scripts and IoT data protocol. No web dashboard is included in this app-only ZIP.

## Included features

- Dark responsive material dashboard for Windows, macOS and Android.
- Interactive home layout: **3 bedrooms, 1 washroom, 1 kitchen, 1 utility space, plus living room**. Switches work **directly inside each room** without navigating away.
- Local simulation works without hardware, Wi-Fi or cloud. It persists device switches, door state, routine, threshold, temperature, humidity and electricity tariff on the device.
- Per-device power estimates, recent power chart, daily kWh, monthly ₹ estimate, ECO/Morning/Evening/Night profile, what-if device runtime, and demo overload/high-temperature conditions. Calculations are **illustrative**, not measured or a trained AI prediction model.
- **Bedroom 1** has a compact expandable panel for the physical ESP32 model (lamp, exclusive LOW/MEDIUM/HIGH AC LEDs, geyser, automatic fridge reed/light, SG90 main-door servo, DHT22 and MQ-2). It shares Firebase command and reported state with the separate **Real IoT Sensors** page. All other room controls remain simulation-only.
- Hardware control shows commands separately from ESP32-reported states and requires fresh ESP32 telemetry for an ONLINE status. Temperature, humidity and raw gas sensor data are unavailable when live ESP32 telemetry is unavailable; mock reports are not presented as physical readings.
- Bedroom 1 energy figures are **estimated**, based on confirmed operating states, elapsed monitoring time, configurable power ratings and tariff. The demo hardware has no power meter; MQ-2 ADC is not calibrated gas concentration or a safety alarm.
- REST-based Firebase authentication and Realtime Database (RTDB); remote app usage works if Firebase and ESP32 are both configured and online. Tokens and passwords are not stored on disk; users sign in after restarting.

## Step-by-step: Windows laptop (HP / Dell, Windows 11)

1. Install Flutter stable and add `flutter/bin` to the **PATH**. Install Visual Studio **Desktop development with C++** workload. Open a **new PowerShell** window and verify:

   ```powershell
   flutter doctor
   flutter --version
   ```

2. Extract this ZIP to a folder such as `E:\Smart_Home_Twin_App_2026`. Open **PowerShell in that extracted folder**, the one containing `pubspec.yaml`.
3. EITHER use the one-command script:

   ```powershell
   .\RUN_WINDOWS.ps1
   ```

   If PowerShell blocks local scripts, follow the manual commands below instead (no system policy changes required).

4. OR run these commands, **in the same extracted folder**, one by one:

   ```powershell
   flutter create --project-name smart_home_twin --platforms=windows,android .
   dart tool/prepare_platforms.dart
   flutter pub get
   flutter analyze
   flutter test
   flutter run -d windows
   ```

5. The program opens with working **offline simulation**. Open **Home Layout** to toggle a lamp, fan, AC, or geyser directly inside the rooms. Open **Simulation** to adjust estimates. The **Real IoT Sensors** page needs Firebase and ESP32 setup (below).

Note: the ZIP includes authored Flutter source, not platform binaries. `flutter create` generates the correct `windows/` and `android/` wrapper folders for **your installed Flutter version**; it preserves the supplied Dart app code.

## Step-by-step: macOS / MacBook Air

1. Install Flutter and Xcode, accept the Xcode license, confirm `flutter doctor` is okay for macOS.
2. Extract the ZIP and open Terminal at its root (the folder containing `pubspec.yaml`).
3. Run:

   ```bash
   bash RUN_MACOS.sh
   ```

   Or manually:

   ```bash
   flutter create --project-name smart_home_twin --platforms=macos,android .
   dart tool/prepare_platforms.dart
   flutter pub get
   flutter analyze
   flutter test
   flutter run -d macos
   ```

4. On macOS the preparation script automatically grants the generated macOS app outgoing network entitlement for Firebase. This entitlement is required for real cloud calls.

## Step-by-step: Android phone (Samsung A15)

1. On the **Windows or macOS computer**, install Android Studio and its Android SDK/Command-line Tools; verify `flutter doctor` shows a working Android toolchain.
2. In the **same project directory** run `flutter create --platforms=android .` if an `android/` folder was not generated already, then `dart tool/prepare_platforms.dart`.
3. On your own phone, enable Developer options and USB debugging, connect by USB, and approve the computer on the phone. Run `flutter devices` and find the phone ID.
4. Run `flutter pub get`, then `flutter run -d <phone-device-id>`. If only one Android device is detected, `flutter run` also lets you choose it.
5. To produce an installable APK after setting up Android, run `flutter build apk --release`. Flutter prints the path (commonly `build/app/outputs/flutter-apk/app-release.apk`). Install only on a device you control.

## Connect Firebase cloud (REQUIRED for hardware controls)

1. Create a **Firebase** project. Enable **Realtime Database** (not Firestore) and copy the exact **Database URL** from its console (usually ending in `firebasedatabase.app` or `firebaseio.com`).
2. In Firebase **Authentication → Sign-in method**, enable **Email/Password**. Under **Users**, create a user for the Flutter app. For firmware, create a separate user for the ESP32 with separate credentials.
3. Note the **UID** of the app and device users. Open the Database **Rules** page and adapt `hardware/firebase_rules.json`, replacing both `REPLACE_..._UID` values with those exact UIDs, and `demo-home` with your intended Home ID if different. Publish those rules; never use public read/write rules.
4. In Firebase project settings, copy the **Web API Key**. It's used by the client for Firebase Authentication; it is **not** a server private key.
5. In the Flutter app: **Settings** → enter Web API Key, RTDB URL (HTTPS), Home ID (`demo-home`), tap **Save configuration**. Then sign in with the **app** user email and password.
6. In **Real IoT Sensors**, press **Refresh now**. Successful sign-in and database polling will show cloud status. Missing readings and warnings are **expected until a real ESP32 is running compatible firmware**. Signing in does not prove hardware is present.
7. Flash ESP32 firmware that follows `hardware/DATA_PROTOCOL.md`. The firmware uses its own device account and writes `reported` and `telemetry` as it works. The desktop `hardware/mock_device.py` can help test the cloud command flow **without hardware**, clearly marking its reports as fake. Do not use an admin service-account JSON key on either device.

## Notes about the physical miniature model

- Exact pin assignments and required firmware behavior are documented in [`hardware/DATA_PROTOCOL.md`](hardware/DATA_PROTOCOL.md): GPIO5 lamp; GPIO19/21/22 AC LOW/MEDIUM/HIGH; GPIO23 geyser; GPIO14 fridge light; GPIO13 reed (`INPUT_PULLUP`); GPIO18 SG90; GPIO4 DHT22; GPIO34 MQ-2 analog.
- The protocol also documents the demonstration-model wiring: separate 220 Ω LED resistors, reed module pin usage and polarity, DHT22 pull-up for bare sensors, SG90 regulated 5 V/common ground, and the MQ-2 10 kΩ/15 kΩ divider. Confirm sensor polarity and GPIO34 voltage on the actual hardware before operation.
- `ac_mode` Firebase command is `OFF`, `LOW`, `MEDIUM` or `HIGH`; firmware must ensure no more than one AC indicator LED is on. Fridge light is read-only and follows the reed sensor.
- Firebase `commands` is requested state; `reported` is ESP32-applied state. The app keeps these separate and highlights pending commands. ESP32 heartbeat telemetry must be fresh for the device to show ONLINE.
- Only safe low-voltage prototype components are in scope. **Never wire a real mains-powered AC, geyser or appliance directly to the ESP32.** GPIO34 analog input must remain at or below 3.3 V. MQ-2 readings are not calibrated safety measurements.

## Verify

Run these commands from the project root after generating platform wrappers:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d windows  # Windows only
# OR: flutter run -d macos  # macOS only
```

**Known environment limitation:** This ZIP was generated without a local Flutter SDK available in the generation environment, so `flutter analyze`, `flutter test` and device execution could **not** be run here. The project includes tests and scripts to validate on your machine; no false claim of runtime verification is made.

If the Android SDK is missing, Windows desktop can still be tested first. A Windows app cannot be built for macOS on Windows: use the same **source folder/ZIP on each OS** and run the matching commands there.

## Folder guide

```text
Smart_Home_Twin_App_2026/
  lib/
    main.dart             # Flutter app entry point + dark theme
    models.dart           # home rooms, devices and telemetry models
    energy.dart           # energy forecasting formulae
    cloud_client.dart     # Firebase authentication + RTDB REST calls
    app_controller.dart   # app state, storage, simulation, cloud polling
    floor_plan.dart      # floor plan and Bedroom 1 physical controls
    pages.dart.dart            # dashboard, room layout, simulation, real IoT, settings
  hardware/
    DATA_PROTOCOL.md      # ESP32 ↔ RTDB JSON contract and pin mapping
    firebase_rules.json  # locked-down two-user sample Firebase rules
    mock_device.py       # optional clearly simulated Firebase test device
  tool/prepare_platforms.dart # Android Internet and macOS network entitlements
  test/energy_test.dart
  pubspec.yaml
  RUN_WINDOWS.ps1
  RUN_MACOS.sh
  README.md
```

## What is not supplied

ESP32 firmware depends on your specific board, installed Arduino libraries, network configuration, wiring checks and sensor power levels. This **app-only** archive contains the complete Flutter cloud client and the protocol the firmware must follow, but does **not** include a verified flashed ESP32 binary or a production IoT backend. A separate physical-device test is necessary to prove LEDs and servo movement.
