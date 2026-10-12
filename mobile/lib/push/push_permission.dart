/// Whether this phone may show Lizmo's notifications.
enum PushPermission {
  /// Allowed, or a phone too old to need asking.
  granted,

  /// Never asked. The only state the app asks from by itself.
  notAsked,

  /// Said no once; Android will still ask a second time if asked.
  denied,

  /// Said no for good. Only the phone's settings can change it now.
  blocked,

  /// No push on this phone at all, so nothing to ask for or to turn on.
  unsupported;

  bool get isOff => this == denied || this == blocked;
}
