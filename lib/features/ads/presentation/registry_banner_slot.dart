import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/ads/ads_controller.dart';
import 'package:the_registry/features/ads/ads_platform.dart';

/// An inline adaptive banner inside a scrolling list.
///
/// Takes no space until a banner has loaded, and none at all when ads are
/// off, consent does not allow ads, or the user has Local Pro.
class RegistryBannerSlot extends StatefulWidget {
  const RegistryBannerSlot({super.key});

  static const retryAfter = Duration(minutes: 1);

  @override
  State<RegistryBannerSlot> createState() => _RegistryBannerSlotState();
}

class _RegistryBannerSlotState extends State<RegistryBannerSlot> {
  LoadedBanner? _banner;
  int? _width;
  var _loading = false;
  DateTime? _failedAt;

  @override
  void dispose() {
    _banner?.dispose();
    _banner = null;
    super.dispose();
  }

  void _release() {
    final banner = _banner;
    if (banner == null) {
      return;
    }
    _banner = null;
    _width = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => banner.dispose());
  }

  void _load(AdsController ads, Clock clock, int width) {
    if (_loading || (_banner != null && _width == width)) {
      return;
    }
    final failedAt = _failedAt;
    if (failedAt != null &&
        clock.now().difference(failedAt) < RegistryBannerSlot.retryAfter) {
      return;
    }
    final unitId = ads.bannerUnitId;
    final platform = ads.platform;
    if (unitId == null || platform == null) {
      return;
    }
    _loading = true;
    unawaited(() async {
      LoadedBanner? banner;
      try {
        banner = await platform.loadBanner(unitId: unitId, width: width);
      } catch (_) {
        banner = null;
      }
      _loading = false;
      if (!mounted || !ads.showBanners) {
        banner?.dispose();
        return;
      }
      if (banner == null) {
        _failedAt = clock.now();
        return;
      }
      final previous = _banner;
      setState(() {
        _banner = banner;
        _width = width;
        _failedAt = null;
      });
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final deps = RegistryDependencies.of(context);
    final ads = deps.ads;
    return ListenableBuilder(
      listenable: ads,
      builder: (context, _) {
        if (!ads.showBanners) {
          _release();
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.truncate();
            if (width > 0) {
              _load(ads, deps.clock, width);
            }
            final banner = _banner;
            if (banner == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              key: const ValueKey<String>('registry-banner'),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: banner.size.width,
                  height: banner.size.height,
                  child: banner.build(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
