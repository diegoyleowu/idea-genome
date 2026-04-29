import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<String> saveImage(String tempPath, String uuid) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = '$uuid.jpg';
    final savedPath = '${imagesDir.path}/$fileName';
    await File(tempPath).copy(savedPath);
    return savedPath;
  }

  static Future<String> saveVideo(String tempPath, String uuid) async {
    final directory = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${directory.path}/videos');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    final fileName = '$uuid.mp4';
    final savedPath = '${videosDir.path}/$fileName';
    await File(tempPath).copy(savedPath);
    return savedPath;
  }

  static File getFile(String path) => File(path);
}
