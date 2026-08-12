import 'file_saver.dart';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaverUtil {
  static final FileSaver _saver = FileSaverImpl();

  /// Saves a file with the given name and content.
  static Future<void> save(String filename, String content, {String mimeType = 'text/csv'}) async {
    await _saver.saveFile(filename, content, mimeType);
  }
}
