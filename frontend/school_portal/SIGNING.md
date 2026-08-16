# Release signing

Bundle IDs are already registered with Firebase — **do not change them**:

- Android `applicationId`: `com.ahkstudios.taleem_hub`
- iOS bundle id: `com.schoolingsystem.schoolPortal`

## Android

Hi, I'm Ali Hamza, a professional Flutter developer.
Need a mobile app for both Android and iOS without paying for two separate apps? I can help.
I build fast, scalable, production-ready Flutter applications with clean UI, Firebase or REST API integration, 
secure authentication, push notifications, payments, and complete App Store and Google Play deployment.

Whether you're launching a startup MVP or growing an existing business, you'll get clean code, regular progress updates, 
and direct communication with the developer building your app.
Send me your app idea today, and I'll provide a free consultation with the best solution for your budget. Let's build something amazing together!

The Gradle wiring is done. `android/app/build.gradle.kts` reads
`android/key.properties` for the release signing key, and falls back to the
debug key when that file is absent (so CI and fresh checkouts still build).

One-time setup on the machine that ships releases:

1. Generate an upload keystore (pick your own passwords):

   ```sh
   keytool -genkey -v \
     -keystore ~/taleem-hub-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Copy the template and fill it in:

   ```sh
   cp android/key.properties.example android/key.properties
   ```

   Set `storeFile` to the keystore's path and enter the two passwords + alias.
   `key.properties` and `*.jks` are gitignored — never commit them.

3. Build:

   ```sh
   flutter build appbundle --release   # Play Store
   flutter build apk --release          # direct install
   ```

**Back up the keystore.** Lose it and you can never update the published app.

Code shrinking (`isMinifyEnabled`) is off on purpose — R8 needs keep-rules for
Firebase and reflection-based plugins. Enable it only with a tested
`proguard-rules.pro`.

## iOS

The signing team (`YK9VUFZJ83`) is already set in the Xcode project, and
`ios/ExportOptions.plist` is ready for `flutter build ipa`.

Two capabilities must be enabled in Xcode once (they also register the App ID
in the Apple Developer portal — this can't be done from the CLI):

1. Open `ios/Runner.xcworkspace` → **Runner** target → **Signing &
   Capabilities**.
2. **+ Capability → Push Notifications.** This wires
   `ios/Runner/Runner.entitlements` (already created, with `aps-environment`)
   via `CODE_SIGN_ENTITLEMENTS`.
3. Confirm **Automatically manage signing** is on and the team is selected.

Then:

```sh
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

Push also requires an **APNs key** uploaded to the Firebase console
(Project Settings → Cloud Messaging → Apple app configuration) for FCM to reach
iOS devices.

## Permissions declared

- **Android** (`AndroidManifest.xml`): internet, camera, `POST_NOTIFICATIONS`,
  `USE_BIOMETRIC`.
- **iOS** (`Info.plist`): camera, photo library, Face ID usage strings, plus the
  `remote-notification` background mode.

These cover image_picker, firebase_messaging (push) and local_auth (biometric
sign-in).
