import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/app_data_service.dart';
import '../domain/app_data_export_result.dart';

class LocalAppDataService implements AppDataService {
  LocalAppDataService({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const _petsKey = 'pet_life_pets_v1';
  static const _remindersKey = 'pet_life_reminders_v1';
  static const _documentsKey = 'pet_life_documents_v1';
  static const _weightEntriesKey = 'pet_life_weight_entries_v1';
  static const _healthEntriesKey = 'pet_life_health_entries_v1';
  static const _foodEntriesKey = 'pet_life_food_entries_v1';
  static const _medicationEntriesKey = 'pet_life_medication_entries_v1';
  static const _visitEntriesKey = 'pet_life_visit_entries_v1';
  static const _expenseEntriesKey = 'pet_life_expense_entries_v1';

  final SharedPreferences _preferences;

  @override
  Future<AppDataExportResult> exportLocalData() async {
    final exportedAt = DateTime.now();

    final exportData = <String, dynamic>{
      'schemaVersion': 1,
      'appName': 'Pet Life',
      'exportedAt': exportedAt.toIso8601String(),
      'data': {
        'pets': _decodeList(_preferences.getString(_petsKey)),
        'reminders': _decodeList(_preferences.getString(_remindersKey)),
        'documents': _decodeList(_preferences.getString(_documentsKey)),
        'weightEntries': _decodeList(
          _preferences.getString(_weightEntriesKey),
        ),
        'healthEntries': _decodeList(
          _preferences.getString(_healthEntriesKey),
        ),
        'foodEntries': _decodeList(
          _preferences.getString(_foodEntriesKey),
        ),
        'medicationEntries': _decodeList(
          _preferences.getString(_medicationEntriesKey),
        ),
        'visitEntries': _decodeList(
          _preferences.getString(_visitEntriesKey),
        ),
        'expenseEntries': _decodeList(
          _preferences.getString(_expenseEntriesKey),
        ),
      },
      'medicalDisclaimer':
          'Pet Life organizes information and reminders only. It does not provide diagnoses, treatments, prescriptions or medical advice.',
    };

    const encoder = JsonEncoder.withIndent('  ');
    final jsonContent = encoder.convert(exportData);

    final appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final exportsDirectory = Directory(
      '${appDocumentsDirectory.path}${Platform.pathSeparator}exports',
    );

    await exportsDirectory.create(recursive: true);

    final safeTimestamp = exportedAt
        .toIso8601String()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final file = File(
      '${exportsDirectory.path}${Platform.pathSeparator}pet_life_export_$safeTimestamp.json',
    );

    await file.writeAsString(jsonContent);

    return AppDataExportResult(
      filePath: file.path,
      jsonContent: jsonContent,
      exportedAt: exportedAt,
    );
  }

  @override
  Future<void> clearLocalData() async {
    await _deleteStoredDocumentFiles();

    await _preferences.remove(_petsKey);
    await _preferences.remove(_remindersKey);
    await _preferences.remove(_documentsKey);
    await _preferences.remove(_weightEntriesKey);
    await _preferences.remove(_healthEntriesKey);
    await _preferences.remove(_foodEntriesKey);
    await _preferences.remove(_medicationEntriesKey);
    await _preferences.remove(_visitEntriesKey);
    await _preferences.remove(_expenseEntriesKey);
  }

  List<dynamic> _decodeList(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is List<dynamic>) {
        return decoded;
      }

      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _deleteStoredDocumentFiles() async {
    final documents = _decodeList(_preferences.getString(_documentsKey));

    for (final item in documents) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final localPath = item['localPath'];

      if (localPath is! String || localPath.isEmpty) {
        continue;
      }

      final file = File(localPath);

      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}