/// Whether the app had to reset part of its local data at launch.
///
/// Set during startup when a Hive box could not be opened — a file cut off by
/// a kill mid-write, or an encryption key the keychain no longer holds — and
/// the store was started empty instead. The home page reads this to tell the
/// user why their settings or servers are gone.
abstract final class DataRecovery {
  static bool recovered = false;
}
