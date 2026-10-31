import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:the_registry/features/ads/ads_config.dart';
import 'package:the_registry/features/ads/ads_platform.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';

/// Decides whether a banner may be requested.
///
/// With ads off, nothing here touches the Mobile Ads SDK or the consent SDK.
/// With ads on, consent is gathered only for a Free user, the SDK is
/// initialized only after consent allows ad requests, and a Local Pro user
/// never reaches either step.
class AdsController extends ChangeNotifier {
  AdsController({required this.config, required this.plan, this.platform})
    : assert(!config.enabled || platform != null);

  final AdsConfig config;
  final RegistryPlanSource plan;
  final AdsPlatform? platform;

  var _started = false;
  var _consentRequested = false;
  var _canRequestAds = false;
  var _privacyOptionsRequired = false;
  var _initialized = false;
  var _disposed = false;

  bool get enabled => config.enabled;

  /// A banner may be requested and shown now.
  bool get showBanners =>
      config.enabled &&
      _initialized &&
      _canRequestAds &&
      plan.plan == RegistryPlan.free &&
      plan.adsMayBeRequested;

  /// Profile shows the privacy options entry point.
  bool get privacyOptionsRequired => config.enabled && _privacyOptionsRequired;

  String? get bannerUnitId => config.bannerUnitId;

  void start() {
    if (_started || !config.enabled) {
      return;
    }
    _started = true;
    plan.addListener(_onPlanChanged);
    _onPlanChanged();
  }

  void _onPlanChanged() {
    if (_disposed) {
      return;
    }
    if (!_consentRequested &&
        plan.plan == RegistryPlan.free &&
        plan.adsMayBeRequested) {
      _consentRequested = true;
      unawaited(_gatherConsent());
    }
    notifyListeners();
  }

  Future<void> _gatherConsent() async {
    AdsConsentState state;
    try {
      state = await platform!.gatherConsent();
    } catch (_) {
      state = AdsConsentState.denied;
    }
    await _applyConsent(state);
  }

  Future<void> showPrivacyOptions() async {
    if (!config.enabled) {
      return;
    }
    AdsConsentState state;
    try {
      state = await platform!.showPrivacyOptions();
    } catch (_) {
      return;
    }
    await _applyConsent(state);
  }

  Future<void> _applyConsent(AdsConsentState state) async {
    if (_disposed) {
      return;
    }
    _canRequestAds = state.canRequestAds;
    _privacyOptionsRequired = state.privacyOptionsRequired;
    if (_canRequestAds && !_initialized && plan.plan == RegistryPlan.free) {
      try {
        await platform!.initialize();
        _initialized = true;
      } catch (_) {
        _initialized = false;
      }
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) {
      plan.removeListener(_onPlanChanged);
    }
    super.dispose();
  }
}
