class DrawingBoardHelper {
  static Future<String> saveDrawing(List<int> bytes) async {
    return 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
  }
}
