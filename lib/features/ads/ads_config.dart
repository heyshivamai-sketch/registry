import 'package:flutter/foundation.dart';
import 'package:the_registry/app/launch_config.dart';

enum AdsMode { off, test, live }

/// Why an ads-on build was turned back to no ads.
enum AdsConfigProblem {
  unknownMode,
  testIdsInRelease,
  missingBannerUnitId,
  invalidBannerUnitId,
  sampleIdInLive,
  unsupportedPlatform,
}

/// Google's published sample IDs. They serve test ads only.
///
/// Used only when `ADS_MODE=test` in a debug or profile build. A release
/// build refuses them in Dart and in the native build scripts.
abstract final class GoogleSampleAdIds {
  static const publisher = 'ca-app-pub-3940256099942544';
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const androidAdaptiveBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const iosAdaptiveBanner = 'ca-app-pub-3940256099942544/2435281174';
}

/// The resolved ads configuration for this build and platform.
class AdsConfig {
  const AdsConfig._({required this.mode, this.bannerUnitId, this.problem});

  static const off = AdsConfig._(mode: AdsMode.off);

  factory AdsConfig.resolve({
    required bool adsEnabled,
    required String mode,
    required String androidBannerUnitId,
    required String iosBannerUnitId,
    required TargetPlatform platform,
    required bool releaseMode,
  }) {
    if (!adsEnabled) {
      return off;
    }
    final isAndroid = platform == TargetPlatform.android;
    final isIos = platform == TargetPlatform.iOS;
    if (!isAndroid && !isIos) {
      return _refused(AdsConfigProblem.unsupportedPlatform);
    }
    switch (mode) {
      case 'test':
        if (releaseMode) {
          return _refused(AdsConfigProblem.testIdsInRelease);
        }
        return AdsConfig._(
          mode: AdsMode.test,
          bannerUnitId: isAndroid
              ? GoogleSampleAdIds.androidAdaptiveBanner
              : GoogleSampleAdIds.iosAdaptiveBanner,
        );
      case 'live':
        final unitId = (isAndroid ? androidBannerUnitId : iosBannerUnitId)
            .trim();
        if (unitId.isEmpty) {
          return _refused(AdsConfigProblem.missingBannerUnitId);
        }
        if (unitId.startsWith(GoogleSampleAdIds.publisher)) {
          return _refused(AdsConfigProblem.sampleIdInLive);
        }
        if (!isBannerUnitId(unitId)) {
          return _refused(AdsConfigProblem.invalidBannerUnitId);
        }
        return AdsConfig._(mode: AdsMode.live, bannerUnitId: unitId);
      default:
        return _refused(AdsConfigProblem.unknownMode);
    }
  }

  factory AdsConfig.fromEnvironment() {
    return AdsConfig.resolve(
      adsEnabled: LaunchConfig.adsEnabled,
      mode: LaunchConfig.adsMode,
      androidBannerUnitId: LaunchConfig.androidBannerUnitId,
      iosBannerUnitId: LaunchConfig.iosBannerUnitId,
      platform: defaultTargetPlatform,
      releaseMode: kReleaseMode,
    );
  }

  static AdsConfig _refused(AdsConfigProblem problem) {
    return AdsConfig._(mode: AdsMode.off, problem: problem);
  }

  /// An AdMob ad unit ID, `ca-app-pub-<16 digits>/<10 digits>`. An App ID
  /// uses `~` instead of `/` and is not accepted here.
  static bool isBannerUnitId(String value) {
    return RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(value);
  }

  final AdsMode mode;
  final String? bannerUnitId;
  final AdsConfigProblem? problem;

  bool get enabled => mode != AdsMode.off && bannerUnitId != null;
}
