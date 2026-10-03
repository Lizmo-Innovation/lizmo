import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether this build of the app is still allowed to run.
///
/// Asked once at launch, before anybody signs in. A build with a bug in how it
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

/// The build number of the running app.
///
/// A function behind a provider so tests can say what is installed without the
/// platform channel, which does not exist under `flutter test`.
final installedBuildProvider = Provider<Future<int> Function()>(
  (ref) => () async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  },
);

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

  /// Asks what the oldest allowed build is, and compares.
  ///
  /// Anything that goes wrong — no network, a 500, an old server that has no
  /// such endpoint, a platform channel that is not there — opens the app.
  /// Being locked out of your own tenancy because a request timed out is a
  /// worse failure than running a build we would rather you had replaced.
  Future<void> check() async {
    state = const AppVersionChecking();
    try {
      final installed = await ref.read(installedBuildProvider)();
      final allowed = await ref
          .read(appVersionApiProvider)
          .getAppVersion()
          .timeout(timeout);

      final minimum = allowed?.minimumBuild ?? 0;
      if (minimum <= 0 || installed >= minimum) {
        state = const AppVersionAllowed();
        return;
      }
      state = AppTooOld(_linkFor(allowed));
    } on Object {
      state = const AppVersionAllowed();
    }
  }

  /// The store this phone would go to, or null if nobody has set one.
  ///
  /// Blank counts as unset: the console clears a link by emptying the box.
  String? _linkFor(AppVersion? allowed) {
    final link = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => allowed?.iosUpdateUrl,
      _ => allowed?.androidUpdateUrl,
    };
    return (link == null || link.trim().isEmpty) ? null : link.trim();
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
