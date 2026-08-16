/// Asset keys for bundled images.
///
/// These are **asset keys, not file paths**: Flutter resolves them relative to
/// the package root (the directory holding `pubspec.yaml`, i.e.
/// `frontend/school_portal/`), so a key always starts at `assets/`. A key that
/// includes repository directories above the package root resolves to nothing
/// and the image silently fails to load.
///
/// Every key here must also be covered by the `flutter: assets:` section of
/// `pubspec.yaml` — `assets/images/` already declares this whole folder.
abstract class ImageConstant {
  static const String appIcon = 'assets/images/app_icon.png';
}
