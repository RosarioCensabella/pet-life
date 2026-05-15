class AppDataExportResult {
  const AppDataExportResult({
    required this.filePath,
    required this.jsonContent,
    required this.exportedAt,
  });

  final String filePath;
  final String jsonContent;
  final DateTime exportedAt;
}