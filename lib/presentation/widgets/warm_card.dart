import 'package:flutter/material.dart';
import '../../domain/entities/idea.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';

class WarmIdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onTap;

  const WarmIdeaCard({
    super.key,
    required this.idea,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowWarm,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIndicator(),
                const SizedBox(width: 8),
                Text(
                  _getTypeName(),
                  style: AppTypography.caption.copyWith(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildTimeIndicator(),
              ],
            ),
            if (idea.title.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                idea.title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (idea.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                idea.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_hasAttachments()) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildAttachmentsPreview(),
            ],
            if (idea.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildTags(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getTypeColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTimeIndicator() {
    final now = DateTime.now();
    final diff = now.difference(idea.createdAt);
    
    String timeText;
    if (diff.inMinutes < 1) {
      timeText = '刚刚';
    } else if (diff.inMinutes < 60) {
      timeText = '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      timeText = '${diff.inHours}小时前';
    } else {
      timeText = '${idea.createdAt.month}/${idea.createdAt.day}';
    }

    return Text(
      timeText,
      style: AppTypography.caption.copyWith(
        color: AppColors.textTertiary,
      ),
    );
  }

  bool _hasAttachments() {
    return idea.hasImages || idea.hasAudio || idea.hasVideo || idea.hasDrawing;
  }

  Widget _buildAttachmentsPreview() {
    return Row(
      children: [
        if (idea.hasImages) ...[
          Icon(Icons.image_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 2),
          Text(
            '${idea.imagePaths.length}',
            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
        ],
        if (idea.hasAudio) ...[
          Icon(Icons.mic_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          const SizedBox(width: 8),
        ],
        if (idea.hasVideo) ...[
          Icon(Icons.videocam_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          const SizedBox(width: 8),
        ],
        if (idea.hasDrawing) ...[
          Icon(Icons.brush_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: idea.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.tagBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '#$tag',
            style: AppTypography.caption.copyWith(
              color: AppColors.tagText,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTypeColor() {
    switch (idea.type) {
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

  String _getTypeName() {
    switch (idea.type) {
      case IdeaType.thought:
        return '💡 想法';
      case IdeaType.project:
        return '🚀 项目';
      case IdeaType.question:
        return '❓ 问题';
      case IdeaType.inspiration:
        return '✨ 灵感';
    }
  }
}
