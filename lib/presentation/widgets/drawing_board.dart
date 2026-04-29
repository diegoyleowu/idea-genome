import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'drawing_board_stub.dart' if (dart.library.io) 'drawing_board_io.dart';
import '../../core/constants/app_colors.dart';

class DrawingBoard extends StatefulWidget {
  final Function(String) onDrawingSaved;

  const DrawingBoard({super.key, required this.onDrawingSaved});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  final List<List<Offset>> _strokes = [];
  final List<Offset> _currentStroke = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSaving = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke.clear();
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<void> _saveDrawing() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isSaving = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _isSaving = false);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      String savedPath;

      if (kIsWeb) {
        savedPath = 'data:image/png;base64,${Uri.encodeComponent(String.fromCharCodes(pngBytes))}';
      } else {
        savedPath = await DrawingBoardHelper.saveDrawing(pngBytes);
      }

      widget.onDrawingSaved(savedPath);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('画图'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo, tooltip: '撤销'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: '清空'),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check), 
            onPressed: _isSaving ? null : _saveDrawing, 
            tooltip: '保存',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._colors.map((color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: AppColors.primary, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 20,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => _strokeWidth = value),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Container(
                        width: _strokeWidth,
                        height: _strokeWidth,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_strokeWidth.toInt()}px', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    selectedColor: _selectedColor,
                    strokeWidth: _strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color selectedColor;
  final double strokeWidth;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.selectedColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = selectedColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentStroke.length >= 2) {
      final currentPath = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        currentPath.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(currentPath, paint);
    } else if (currentStroke.length == 1) {
      canvas.drawCircle(currentStroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return strokes != oldDelegate.strokes || currentStroke != oldDelegate.currentStroke;
  }
}
