import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// When somebody last said "Not now" to being asked about notifications.
///
/// Kept so they are not asked again after every message they send. The
/// phone's own permission answer is the system's to remember; this is only
/// Lizmo's question in front of it.
abstract class PushAskMemory {
  Future<DateTime?> lastDeclined();
  Future<void> declined(DateTime at);
}

/// Secure storage, only because the app already carries it: a new plugin for
/// one date is a new thing to keep building on Android.
class StoredPushAskMemory implements PushAskMemory {
  StoredPushAskMemory([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'push-ask-declined-at';

  @override
  Future<DateTime?> lastDeclined() async {
    try {
      return DateTime.tryParse(await _storage.read(key: _key) ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> declined(DateTime at) async {
    try {
      await _storage.write(key: _key, value: at.toUtc().toIso8601String());
    } catch (_) {
      // Forgetting means being asked once more, which is no harm.
    }
  }
}

class InMemoryPushAskMemory implements PushAskMemory {
  DateTime? _at;

  @override
  Future<DateTime?> lastDeclined() async => _at;

  @override
  Future<void> declined(DateTime at) async => _at = at;
}
