import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/idea.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/file_helper.dart';
import 'drawing_board.dart';

class EnhancedQuickCaptureSheet extends StatefulWidget {
  final Function(Idea) onIdeaCreated;

  const EnhancedQuickCaptureSheet({super.key, required this.onIdeaCreated});

  @override
  State<EnhancedQuickCaptureSheet> createState() => _EnhancedQuickCaptureSheetState();
}

class _EnhancedQuickCaptureSheetState extends State<EnhancedQuickCaptureSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();
  final Uuid _uuid = const Uuid();

  IdeaType _selectedType = IdeaType.thought;
  bool _isListening = false;
  String _recognizedText = '';
  List<String> _imagePaths = [];
  String? _audioPath;
  String? _videoPath;
  String? _drawingPath;
  bool _isRecording = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (error) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      _speechAvailable = false;
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音识别不可用，请检查权限设置')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          if (result.finalResult && _contentController.text.isEmpty) {
            _contentController.text = _recognizedText;
          } else if (result.finalResult) {
            _contentController.text += '\n$_recognizedText';
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'zh_CN',
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final image in images) {
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            final base64 = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString();
            _imagePaths.add(base64);
          } else {
            final savedPath = await FileHelper.saveImage(image.path, _uuid.v4());
            _imagePaths.add(savedPath);
          }
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          final base64 = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString();
          _imagePaths.add(base64);
        } else {
          final savedPath = await FileHelper.saveImage(photo.path, _uuid.v4());
          _imagePaths.add(savedPath);
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失败: $e')),
      );
    }
  }

  Future<void> _recordVideo() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web端暂不支持视频录制，请在手机应用中使用')),
      );
      return;
    }
    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        final savedPath = await FileHelper.saveVideo(video.path, _uuid.v4());
        setState(() => _videoPath = savedPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('录制视频失败: $e')),
      );
    }
  }

  void _showDrawingBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingBoard(
          onDrawingSaved: (path) {
            setState(() => _drawingPath = path);
          },
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _createIdea() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty && _imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    final now = DateTime.now();
    final idea = Idea(
      id: _uuid.v4(),
      title: _titleController.text.isEmpty ? '想法 ${now.hour}:${now.minute}' : _titleController.text,
      content: _contentController.text,
      type: _selectedType,
      createdAt: now,
      updatedAt: now,
      tags: [],
      linkedIdeaIds: [],
      audioPath: _audioPath,
      imagePaths: _imagePaths,
      videoPath: _videoPath,
      drawingPath: _drawingPath,
    );

    widget.onIdeaCreated(idea);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('记录想法', style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '标题（可选）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '写下你的想法...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _recognizedText.isEmpty ? '正在聆听...' : _recognizedText,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildMultimediaSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildAttachmentsPreview(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _createIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('保存想法', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: IdeaType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _getTypeColor(type).withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _getTypeColor(type) : AppColors.textTertiary.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getTypeIcon(type), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      _getTypeName(type),
                      style: TextStyle(
                        color: isSelected ? _getTypeColor(type) : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultimediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('多媒体输入', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildInputButton(
                icon: Icons.mic,
                label: _isListening ? '停止' : '语音输入',
                color: _isListening ? Colors.red : AppColors.primary,
                onTap: _isListening ? _stopListening : _startListening,
              ),
              const SizedBox(width: 8),
              _buildInputButton(
                icon: Icons.image,
                label: '图片',
                color: Colors.orange,
                onTap: _pickImages,
              ),
              const SizedBox(width: 8),
              _buildInputButton(
                icon: Icons.camera_alt,
                label: '拍照',
                color: Colors.purple,
                onTap: _takePhoto,
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                _buildInputButton(
                  icon: Icons.videocam,
                  label: '视频',
                  color: Colors.red,
                  onTap: _recordVideo,
                ),
              ],
              const SizedBox(width: 8),
              _buildInputButton(
                icon: Icons.brush,
                label: '画图',
                color: Colors.blue,
                onTap: _showDrawingBoard,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsPreview() {
    if (_imagePaths.isEmpty && _videoPath == null && _drawingPath == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('附件预览', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._imagePaths.asMap().entries.map((entry) => _buildImagePreview(entry.value, entry.key)),
            if (_videoPath != null) _buildVideoPreview(),
            if (_drawingPath != null) _buildDrawingPreview(),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(String path, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(path, width: 80, height: 80, fit: BoxFit.cover)
              : Image.file(FileHelper.getFile(path), width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam, color: Colors.red, size: 40),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
            child: const Text('视频', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingPreview() {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.brush, color: Colors.blue, size: 40),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
            child: const Text('图画', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought:
        return AppColors.thoughtColor;
      case IdeaType.project:
        return AppColors.projectColor;
      case IdeaType.question:
        return AppColors.questionColor;
      case IdeaType.inspiration:
        return AppColors.inspirationColor;
    }
  }

  String _getTypeIcon(IdeaType type) {
    switch (type) {
      case IdeaType.thought:
        return '💡';
      case IdeaType.project:
        return '🚀';
      case IdeaType.question:
        return '❓';
      case IdeaType.inspiration:
        return '✨';
    }
  }

  String _getTypeName(IdeaType type) {
    switch (type) {
      case IdeaType.thought:
        return '想法';
      case IdeaType.project:
        return '项目';
      case IdeaType.question:
        return '问题';
      case IdeaType.inspiration:
        return '灵感';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _speechToText.stop();
    super.dispose();
  }
}
