class CsvExporter {
  /// Converts a list of headers and rows of dynamic values to a valid CSV string.
  static String convertToCsv(List<String> headers, List<List<dynamic>> rows) {
    final List<String> csvLines = [];

    // Format headers and escape quotes
    csvLines.add(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    // Format data rows
    for (final row in rows) {
      csvLines.add(row.map((val) {
        if (val == null) return '';
        
        // Handle DateTime formatting directly
        if (val is DateTime) {
          return '"${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}"';
        }
        
        final String strVal = val.toString();
        return '"${strVal.replaceAll('"', '""')}"';
      }).join(','));
    }

    return csvLines.join('\n');
  }
}
