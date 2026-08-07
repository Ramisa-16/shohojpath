/// Formats a [Duration] as the study screens want it: `m:ss` for the
/// in-session timers (Quiz's "Reading time recorded"), matching the design's
/// `4:12`.
String formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// The longer `m min s s` form used on Feedback and Thank You, matching the
/// design's `4 min 12 s`.
String formatDurationLong(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes min ${seconds.toString().padLeft(2, '0')} s';
}
