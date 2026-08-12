import 'dart:convert';
import 'dart:html' as html;
import 'file_saver.dart';

class FileSaverImpl implements FileSaver {
  @override
  Future<void> saveFile(String filename, String content, String mimeType) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
