import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether this version of the app is still allowed to run.
///
/// Asked once at launch, before anybody signs in. A version with a bug in how it
/// declares a payment, or one that calls endpoints that have moved, otherwise
/// keeps running until its owner happens to update — and the people least
/// likely to update are the ones whose app works badly enough to be left
/// alone on the home screen.
sealed class AppVersionCheck {
  const AppVersionCheck();
}

/// The answer has not come back yet. The splash holds until it does.
class AppVersionChecking extends AppVersionCheck {
  const AppVersionChecking();
}

/// Carry on. Also what a failed check means: see [AppVersionGate.check].
class AppVersionAllowed extends AppVersionCheck {
  const AppVersionAllowed();
}

/// Too old to be used. [link] is where this platform goes for a newer one,
/// and is null when nobody has set one.
class AppTooOld extends AppVersionCheck {
  const AppTooOld(this.link);

  final String? link;
}

/// The version name of the running app -- "1.1.1", not the build number.
///
/// The name because that is what the console's minimum is written in, and the
/// console is written in it because that is what an operator has in front of
/// them: the store listing, the about screen, what somebody reads off a phone
/// over the telephone.
///
/// A function behind a provider so tests can say what is installed without the
/// platform channel, which does not exist under `flutter test`.
final installedVersionProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  },
);

/// Orders two version names: negative when [a] is older than [b].
///
/// Part by part, so 1.2.0 beats 1.1.9 -- the comparison a string would get
/// wrong. A missing part counts as zero, so 1.1 and 1.1.0 are one version.
///
/// Null when either side is not digits and dots. The caller opens the app on
/// null, like everything else that can go wrong here: a version nobody can
/// read is not grounds for locking somebody out of their own tenancy.
int? compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  if (left == null || right == null) return null;

  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final one = i < left.length ? left[i] : 0;
    final other = i < right.length ? right[i] : 0;
    if (one != other) return one < other ? -1 : 1;
  }
  return 0;
}

List<int>? _parts(String version) {
  final text = version.trim();
  if (text.isEmpty) return null;

  final parts = <int>[];
  for (final part in text.split('.')) {
    final number = int.tryParse(part);
    if (number == null || number < 0) return null;
    parts.add(number);
  }
  return parts;
}

/// Opens a link outside the app.
///
/// Also behind a provider, so a test can assert where the button sends people
/// without a browser opening on the machine running it.
final openLinkProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// The public endpoint, read without a session: an app too old to be allowed
/// in cannot first be made to log in.
final appVersionApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);

class AppVersionGate extends Notifier<AppVersionCheck> {
  /// Long enough for a slow connection, short enough that nobody sits on the
  /// splash wondering. Past it the app opens: see [check].
  static const timeout = Duration(seconds: 5);

  @override
  AppVersionCheck build() {
    Future.microtask(check);
    return const AppVersionChecking();
  }

  /// Asks what the oldest allowed version is, and compares.
  ///
  /// Anything that goes wrong -- no network, a 500, an old server that has no
  /// such endpoint, a platform channel that is not there, a version neither
  /// side can parse -- opens the app. Being locked out of your own tenancy
  /// because a request timed out is a worse failure than running a version we
  /// would rather you had replaced.
  Future<void> check() async {
    state = const AppVersionChecking();
    try {
      final installed = await ref.read(installedVersionProvider)();
      final allowed = await ref
          .read(appVersionApiProvider)
          .getAppVersion()
          .timeout(timeout);

      // The minimum for *this* platform. The other one's is nothing to do
      // with this phone: the two releases ship apart.
      final minimum = _forThisPlatform(
          allowed?.minimumAndroidVersion, allowed?.minimumIosVersion);
      if (minimum == null) {
        state = const AppVersionAllowed();
        return;
      }

      final order = compareVersions(installed, minimum);
      if (order == null || order >= 0) {
        state = const AppVersionAllowed();
        return;
      }
      state = AppTooOld(
          _forThisPlatform(allowed?.androidUpdateUrl, allowed?.iosUpdateUrl));
    } on Object {
      state = const AppVersionAllowed();
    }
  }

  /// Whichever of the two belongs to the phone this is running on.
  ///
  /// Blank counts as unset, for both the minimum and the link: the console
  /// clears either by emptying its box.
  String? _forThisPlatform(String? android, String? ios) {
    final value = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      _ => android,
    };
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }
}

final appVersionProvider =
    NotifierProvider<AppVersionGate, AppVersionCheck>(AppVersionGate.new);

/// Tells the router to look again when the answer lands.
///
/// The router reads [appVersionProvider] inside its redirect rather than
/// watching it: watching rebuilds the provider, and a redirect running against
/// a router whose own provider is mid-rebuild trips Riverpod's assertion the
/// first time anything taps a tab. This is the same shape as
/// `AuthRefreshNotifier`, for the same reason.
class VersionRefreshNotifier extends ChangeNotifier {
  VersionRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AppVersionCheck>(
      appVersionProvider,
      (previous, next) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AppVersionCheck> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
