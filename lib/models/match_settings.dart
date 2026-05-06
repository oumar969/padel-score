class MatchSettings {
  final bool warmup;
  final bool serveIndicator;
  final bool timeout;
  final bool ballReminder;
  final bool sideSwitch;
  final bool liveComments;

  const MatchSettings({
    this.warmup = false,
    this.serveIndicator = false,
    this.timeout = false,
    this.ballReminder = false,
    this.sideSwitch = false,
    this.liveComments = false,
  });

  MatchSettings copyWith({
    bool? warmup,
    bool? serveIndicator,
    bool? timeout,
    bool? ballReminder,
    bool? sideSwitch,
    bool? liveComments,
  }) =>
      MatchSettings(
        warmup: warmup ?? this.warmup,
        serveIndicator: serveIndicator ?? this.serveIndicator,
        timeout: timeout ?? this.timeout,
        ballReminder: ballReminder ?? this.ballReminder,
        sideSwitch: sideSwitch ?? this.sideSwitch,
        liveComments: liveComments ?? this.liveComments,
      );

  Map<String, dynamic> toMap() => {
        'warmup': warmup,
        'serveIndicator': serveIndicator,
        'timeout': timeout,
        'ballReminder': ballReminder,
        'sideSwitch': sideSwitch,
        'liveComments': liveComments,
      };

  factory MatchSettings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const MatchSettings();
    return MatchSettings(
      warmup: m['warmup'] as bool? ?? false,
      serveIndicator: m['serveIndicator'] as bool? ?? false,
      timeout: m['timeout'] as bool? ?? false,
      ballReminder: m['ballReminder'] as bool? ?? false,
      sideSwitch: m['sideSwitch'] as bool? ?? false,
      liveComments: m['liveComments'] as bool? ?? false,
    );
  }
}
