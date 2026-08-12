import 'file_saver.dart';

class FileSaverImpl implements FileSaver {
  @override
  Future<void> saveFile(String filename, String content, String mimeType) async {
    throw UnimplementedError('FileSaver is not implemented on this platform.');
  }
}
