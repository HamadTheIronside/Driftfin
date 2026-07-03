import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  Debouncer(this.duration);
  final Duration duration;
  Timer? _timer;
  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(duration, action);
  }

  /// Cancels any pending action. Call when the owner is disposed so a queued
  /// callback can't fire against torn-down state.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
