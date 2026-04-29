import 'package:flutter/material.dart';
import '../../../domain/entities/idea.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const IdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withOpacity(0.3) : AppColors.cardBackground,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardShadow,
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: AppSpacing.cardPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeChip(),
            const SizedBox(height: AppSpacing.sm),
            Text(idea.displayTitle, style: AppTypography.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Text(idea.summary, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
            if (idea.hasTags) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildTagsRow(),
            ],
            const SizedBox(height: AppSpacing.sm),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getTypeIcon(), size: 12, color: _getTypeColor()),
              const SizedBox(width: AppSpacing.xs),
              Text(_getTypeName(), style: AppTypography.caption.copyWith(color: _getTypeColor(), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Text(_getTimeAgo(idea.updatedAt), style: AppTypography.caption),
      ],
    );
  }

  Widget _buildTagsRow() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: idea.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: AppColors.tagBackground, borderRadius: AppSpacing.borderRadiusSm),
          child: Text('#$tag', style: AppTypography.caption.copyWith(color: AppColors.tagText)),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (idea.hasLinks) ...[
          const Icon(Icons.link, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text('${idea.linkedIdeaIds.length}', style: AppTypography.caption),
        ],
        const Spacer(),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
      ],
    );
  }

  Color _getTypeColor() {
    switch (idea.type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }

  IconData _getTypeIcon() {
    switch (idea.type) {
      case IdeaType.thought: return Icons.lightbulb_outline;
      case IdeaType.project: return Icons.rocket_launch_outlined;
      case IdeaType.question: return Icons.help_outline;
      case IdeaType.inspiration: return Icons.auto_awesome;
    }
  }

  String _getTypeName() {
    switch (idea.type) {
      case IdeaType.thought: return '想法';
      case IdeaType.project: return '项目';
      case IdeaType.question: return '问题';
      case IdeaType.inspiration: return '灵感';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}年前';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}月前';
    if (difference.inDays > 0) return '${difference.inDays}天前';
    if (difference.inHours > 0) return '${difference.inHours}小时前';
    if (difference.inMinutes > 0) return '${difference.inMinutes}分钟前';
    return '刚刚';
  }
}
