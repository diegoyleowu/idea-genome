import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/idea.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../blocs/idea/idea_bloc.dart';
import '../blocs/idea/idea_event.dart';

class IdeaDetailPage extends StatefulWidget {
  final Idea idea;

  const IdeaDetailPage({super.key, required this.idea});

  @override
  State<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends State<IdeaDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late IdeaType _selectedType;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea.title);
    _contentController = TextEditingController(text: widget.idea.content);
    _selectedType = widget.idea.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedIdea = widget.idea.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      type: _selectedType,
    );
    context.read<IdeaBloc>().add(UpdateIdea(updatedIdea));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑想法' : '想法详情', style: AppTypography.titleMedium),
        actions: [
          if (_isEditing)
            TextButton(onPressed: _saveChanges, child: Text('保存', style: TextStyle(color: AppColors.primary)))
          else
            IconButton(onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit)),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('删除后无法恢复，确定要删除吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                    TextButton(
                      onPressed: () {
                        context.read<IdeaBloc>().add(DeleteIdea(widget.idea.id));
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),
            if (_isEditing) ...[
              TextField(controller: _titleController, style: AppTypography.titleLarge, decoration: const InputDecoration(hintText: '标题')),
            ] else ...[
              Text(widget.idea.displayTitle, style: AppTypography.titleLarge),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_isEditing) ...[
              TextField(controller: _contentController, maxLines: null, minLines: 10, style: AppTypography.bodyLarge),
            ] else ...[
              Text(widget.idea.content.isEmpty ? '暂无内容' : widget.idea.content, style: AppTypography.bodyLarge.copyWith(color: widget.idea.content.isEmpty ? AppColors.textTertiary : null)),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildMediaSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final idea = widget.idea;
    if (!idea.hasImages && !idea.hasVideo && !idea.hasAudio && !idea.hasDrawing) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('附件', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (idea.hasImages) _buildImageGallery(idea.imagePaths),
        if (idea.hasVideo) _buildVideoPlayer(idea.videoPath!),
        if (idea.hasAudio) _buildAudioPlayer(idea.audioPath!),
        if (idea.hasDrawing) _buildDrawingPreview(idea.drawingPath!),
      ],
    );
  }

  Widget _buildImageGallery(List<String> imagePaths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图片 (${imagePaths.length})', style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(imagePaths, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(imagePaths[index], width: 120, height: 120, fit: BoxFit.cover)
                      : Image.file(File(imagePaths[index]), width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  void _showFullScreenImage(List<String> imagePaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imagePaths: imagePaths, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('视频', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.videocam, color: Colors.white, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String audioPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.audiotrack, color: AppColors.primary, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('语音备注', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingPreview(String drawingPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('图画', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
            ),
            child: const Center(
              child: Icon(Icons.brush, color: Colors.blue, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      children: IdeaType.values.map((type) {
        final isSelected = type == _selectedType;
        return ChoiceChip(
          label: Text(_getTypeName(type)),
          selected: isSelected,
          onSelected: _isEditing ? (selected) { if (selected) setState(() => _selectedType = type); } : null,
          selectedColor: _getTypeColor(type).withOpacity(0.2),
          labelStyle: TextStyle(color: isSelected ? _getTypeColor(type) : AppColors.textSecondary),
        );
      }).toList(),
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创建时间: ${_formatDateTime(widget.idea.createdAt)}', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        Text('更新时间: ${_formatDateTime(widget.idea.updatedAt)}', style: AppTypography.caption),
        if (widget.idea.hasTags) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: widget.idea.tags.map((tag) => Chip(label: Text('#$tag'), backgroundColor: AppColors.tagBackground)).toList(),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _getTypeName(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '💡 想法';
      case IdeaType.project: return '🚀 项目';
      case IdeaType.question: return '❓ 问题';
      case IdeaType.inspiration: return '✨ 灵感';
    }
  }

  Color _getTypeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _FullScreenImageViewer({required this.imagePaths, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: kIsWeb
                  ? Image.network(widget.imagePaths[index])
                  : Image.file(File(widget.imagePaths[index])),
            ),
          );
        },
      ),
    );
  }
}
