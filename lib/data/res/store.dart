import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:server_box/core/utils/data_recovery.dart';
import 'package:server_box/data/store/agent_conversation.dart';
import 'package:server_box/data/store/connection_stats.dart';
import 'package:server_box/data/store/container.dart';
import 'package:server_box/data/store/history.dart';
import 'package:server_box/data/store/port_forward.dart';
import 'package:server_box/data/store/private_key.dart';
import 'package:server_box/data/store/server.dart';
import 'package:server_box/data/store/setting.dart';
import 'package:server_box/data/store/snippet.dart';

final GetIt getIt = GetIt.instance;

abstract final class Stores {
  static SettingStore get setting => getIt<SettingStore>();
  static ServerStore get server => getIt<ServerStore>();
  static ContainerStore get container => getIt<ContainerStore>();
  static PrivateKeyStore get key => getIt<PrivateKeyStore>();
  static SnippetStore get snippet => getIt<SnippetStore>();
  static HistoryStore get history => getIt<HistoryStore>();
  static AgentConversationStore get agentConversation =>
      getIt<AgentConversationStore>();
  // Keep the legacy box registered so existing connection stats DB files remain intact.
  static ConnectionStatsStore get connectionStats =>
      getIt<ConnectionStatsStore>();
  static PortForwardStore get portForward => getIt<PortForwardStore>();

  /// All stores that need backup
  static List<HiveStore> get _allBackup => [
    setting,
    server,
    container,
    key,
    snippet,
    history,
    connectionStats,
    portForward,
  ];

  /// Stores initialized locally. Agent conversations intentionally stay out of
  /// backup and sync because they may contain terminal output and reasoning.
  static List<HiveStore> get _allStores => [..._allBackup, agentConversation];

  static Future<void> init() async {
    getIt.registerLazySingleton<SettingStore>(() => SettingStore.instance);
    getIt.registerLazySingleton<ServerStore>(() => ServerStore.instance);
    getIt.registerLazySingleton<ContainerStore>(() => ContainerStore.instance);
    getIt.registerLazySingleton<PrivateKeyStore>(
      () => PrivateKeyStore.instance,
    );
    getIt.registerLazySingleton<SnippetStore>(() => SnippetStore.instance);
    getIt.registerLazySingleton<HistoryStore>(() => HistoryStore.instance);
    getIt.registerLazySingleton<AgentConversationStore>(
      () => AgentConversationStore.instance,
    );
    getIt.registerLazySingleton<ConnectionStatsStore>(
      () => ConnectionStatsStore.instance,
    );
    getIt.registerLazySingleton<PortForwardStore>(
      () => PortForwardStore.instance,
    );

    for (final store in _allStores) {
      try {
        await store.init();
      } catch (e, s) {
        // A box that cannot be opened — a file cut off by a kill mid-write,
        // or an encryption key the keychain no longer holds — would take the
        // whole app down at launch. Quarantine the files and start the store
        // empty: losing the data is recoverable, losing the app is not.
        Loggers.app.warning('Failed to open ${store.boxName}', e, s);
        await _recoverStore(store);
      }
    }

    await setting.removeRetiredKeys();

    // Migrate sshConnectionMode from old int values to bool
    setting.migrateSshConnectionMode();
    await setting.migrateHomeTabsAgent();

    if (connectionStats.indexDbKeys.isEmpty) {
      await connectionStats.rebuildIndexAndCompact();
    }
  }

  /// Quarantine a store whose box failed to open, then retry it.
  ///
  /// The file is moved aside (renamed, not deleted) so a later build or a
  /// manual look can still reach it; the retry opens a fresh empty box.
  static Future<void> _recoverStore(HiveStore store) async {
    DataRecovery.recovered = true;
    await _quarantineFiles(store.boxName);
    await store.init();
  }

  /// Quarantine every store's box files. The net for a failure the
  /// per-store recovery above could not fix: close everything, move all box
  /// files aside, and let a fresh [init] start the app empty.
  static Future<void> quarantineAll() async {
    DataRecovery.recovered = true;
    for (final store in _allStores) {
      await _quarantineFiles(store.boxName);
    }
  }

  static Future<void> _quarantineFiles(String boxName) async {
    final path = await _boxDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (final name in [boxName, '${boxName}_enc']) {
      for (final ext in ['hive', 'lock']) {
        final file = File('$path/$name.$ext');
        try {
          if (await file.exists()) {
            await file.rename('$path/$name.corrupt-$ts.$ext');
          }
        } catch (e, s) {
          Loggers.app.warning('Failed to quarantine $name.$ext', e, s);
          try {
            await file.delete();
          } catch (_) {
            // Best effort; the fresh open will fail again and be retried.
          }
        }
      }
    }
  }

  static Future<String> _boxDir() async {
    return switch (Pfs.type) {
      Pfs.linux || Pfs.windows => Paths.doc,
      Pfs.macos when !Pfs.isMacSandboxed => Paths.doc,
      _ => (await getApplicationDocumentsDirectory()).path,
    };
  }

  static int get lastModTime {
    var lastModTime = 0;
    for (final store in _allBackup) {
      final last = store.lastUpdateTs;
      if (last == null) {
        continue;
      }
      var lastModTimeTs = 0;
      for (final item in last.entries) {
        final ts = item.value;
        if (ts > lastModTimeTs) {
          lastModTimeTs = ts;
        }
      }
      if (lastModTimeTs > lastModTime) {
        lastModTime = lastModTimeTs;
      }
    }
    return lastModTime;
  }
}
