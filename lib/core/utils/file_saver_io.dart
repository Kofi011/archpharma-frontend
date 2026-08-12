import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_saver.dart';

class FileSaverImpl implements FileSaver {
  @override
  Future<void> saveFile(String filename, String content, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
  }
}
