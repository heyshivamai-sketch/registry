import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';

/// IANA zone reported by the device, so a civil date keeps the offset that
/// applies on that date, including daylight saving.
class DeviceTimeZoneSource implements TimeZoneSource {
  const DeviceTimeZoneSource();

  @override
  Future<tz.Location> current() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } catch (_) {
      return tz.UTC;
    }
  }
}
