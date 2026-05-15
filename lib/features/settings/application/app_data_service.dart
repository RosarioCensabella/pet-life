import '../domain/app_data_export_result.dart';

abstract class AppDataService {
  Future<AppDataExportResult> exportLocalData();

  Future<void> clearLocalData();
}