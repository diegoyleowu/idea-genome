import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DrawingBoardHelper {
  static Future<String> saveDrawing(List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final drawingsDir = Directory('${directory.path}/drawings');
    if (!await drawingsDir.exists()) {
      await drawingsDir.create(recursive: true);
    }
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${drawingsDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }
}
