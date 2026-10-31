import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsConsentState {
  const AdsConsentState({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  static const denied = AdsConsentState(
    canRequestAds: false,
    privacyOptionsRequired: false,
  );

  /// The UMP SDK says ads may be requested.
  final bool canRequestAds;

  /// The UMP SDK requires a privacy options entry point in the app.
  final bool privacyOptionsRequired;
}

/// A banner that finished loading. Dispose it when it leaves the screen.
abstract class LoadedBanner {
  Size get size;

  Widget build();

  void dispose();
}

/// Google Mobile Ads and the User Messaging Platform behind one boundary.
abstract class AdsPlatform {
  /// Updates consent information and shows the consent form if required.
  Future<AdsConsentState> gatherConsent();

  Future<void> initialize();

  Future<AdsConsentState> showPrivacyOptions();

  /// Returns null when no ad could be loaded.
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int width,
  });
}

class GoogleMobileAdsPlatform implements AdsPlatform {
  const GoogleMobileAdsPlatform();

  @override
  Future<AdsConsentState> gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } finally {
          if (!done.isCompleted) {
            done.complete();
          }
        }
      },
      (_) {
        if (!done.isCompleted) {
          done.complete();
        }
      },
    );
    await done.future;
    // Consent from an earlier session still counts after an update failure.
    return _state();
  }

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<AdsConsentState> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) {
        done.complete();
      }
    });
    await done.future;
    return _state();
  }

  Future<AdsConsentState> _state() async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    final privacy = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return AdsConsentState(
      canRequestAds: canRequest,
      privacyOptionsRequired:
          privacy == PrivacyOptionsRequirementStatus.required,
    );
  }

  @override
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int width,
  }) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null) {
      return null;
    }
    final loaded = Completer<LoadedBanner?>();
    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!loaded.isCompleted) {
            loaded.complete(_GoogleBanner(ad as BannerAd, size));
          }
        },
        onAdFailedToLoad: (ad, _) {
          unawaited(ad.dispose());
          if (!loaded.isCompleted) {
            loaded.complete(null);
          }
        },
      ),
    );
    await ad.load();
    return loaded.future;
  }
}

class _GoogleBanner implements LoadedBanner {
  _GoogleBanner(this._ad, AdSize size)
    : size = Size(size.width.toDouble(), size.height.toDouble());

  final BannerAd _ad;

  @override
  final Size size;

  @override
  Widget build() => AdWidget(ad: _ad);

  @override
  void dispose() {
    unawaited(_ad.dispose());
  }
}
