/// Build-time switches for store purchases and ads.
///
/// Every value comes from `--dart-define` and is compiled into the build.
/// Changing a value changes the next build only. It does not change an app
/// that is already installed.
///
/// The default build sells nothing and shows no ads:
/// `PURCHASES_ENABLED=false`, `ADS_ENABLED=false`.
///
/// The AdMob App IDs (`ADMOB_ANDROID_APP_ID`, `ADMOB_IOS_APP_ID`) are read by
/// the native builds (`android/app/build.gradle.kts` and
/// `ios/scripts/configure_admob.sh`), not by Dart. Banner ad unit IDs are
/// separate values and are read here.
abstract final class LaunchConfig {
  /// Store purchases of [localProProductId]. Off until the Play and App Store
  /// products exist and a sandbox purchase, restore, and refund have passed.
  static const purchasesEnabled = bool.fromEnvironment('PURCHASES_ENABLED');

  /// One-time, non-consumable product on both stores.
  static const localProProductId = 'local_pro';

  static const adsEnabled = bool.fromEnvironment('ADS_ENABLED');

  /// `test` or `live`. Read only when [adsEnabled] is true.
  static const adsMode = String.fromEnvironment('ADS_MODE');

  static const androidBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_UNIT_ID',
  );

  static const iosBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_UNIT_ID',
  );
}
