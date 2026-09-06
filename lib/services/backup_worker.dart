import 'backup_service.dart';

/// Jednoduchý plánovač automatické zálohy bez WorkManageru.
/// Záloha se spustí při otevření appky, pokud uplynul dostatečný čas.
class BackupWorkerScheduler {
  static Future<void> initialize() async {
    // Nic není potřeba inicializovat
  }

  static Future<void> scheduleAutoBackup({required String frequency}) async {
    // Záloha se kontroluje při spuštění appky — viz checkAndRunAutoBackup()
  }

  static Future<void> cancelAutoBackup() async {
    // Nic není potřeba rušit
  }

  /// Zkontroluje jestli je čas na automatickou zálohu a případně ji spustí.
  /// Volá se při každém spuštění nebo obnovení appky z pozadí.
  static Future<bool> checkAndRunAutoBackup() async {
    final service = BackupService();
    final enabled = await service.isAutoBackupEnabled();
    if (!enabled) return false;

    final frequency = await service.getAutoBackupFrequency();
    final lastBackup = await service.getLastAutoBackupTime();
    final now = DateTime.now();

    bool shouldRun = false;
    if (lastBackup == null) {
      shouldRun = true;
    } else {
      final diff = now.difference(lastBackup);
      if (frequency == 'weekly') {
        shouldRun = diff.inDays >= 7;
      } else {
        shouldRun = diff.inDays >= 1;
      }
    }

    if (shouldRun) {
      return await service.runAutoBackup();
    }
    return false;
  }
}
