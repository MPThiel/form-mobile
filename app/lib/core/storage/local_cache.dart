import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local cache seam.
///
/// The Drift database arrives in Phase 3 (Home + Log). For now there are no
/// cached tables, so [clear] is a no-op — but sign-out already calls it so the
/// wipe-on-sign-out behaviour is wired and Phase 3 only has to fill in the
/// `drift` deletes here.
class LocalCache {
  const LocalCache();

  /// Drop all locally cached user data. Called on sign-out.
  Future<void> clear() async {
    // TODO(phase-3): delete Drift tables (daily logs, chat, week plan) here.
  }
}

final localCacheProvider = Provider<LocalCache>((ref) => const LocalCache());
