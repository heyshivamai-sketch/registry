class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Test and session clock that can move forward without reading the device.
class MutableClock extends Clock {
  MutableClock(DateTime now) : _now = now;

  DateTime _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  @override
  DateTime now() => _now;
}
