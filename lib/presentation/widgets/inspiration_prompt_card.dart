import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';

class InspirationPromptCard extends StatefulWidget {
  const InspirationPromptCard({super.key});

  @override
  State<InspirationPromptCard> createState() => _InspirationPromptCardState();
}

class _InspirationPromptCardState extends State<InspirationPromptCard> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<_InspirationPrompt> _prompts;
  int _currentIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _prompts = _generatePrompts();
    _currentIndex = _random.nextInt(_prompts.length);
    _pageController = PageController(initialPage: _currentIndex);
  }

  List<_InspirationPrompt> _generatePrompts() {
    return [
      _InspirationPrompt(
        emoji: '🌅',
        title: '感恩时刻',
        question: '今天最让你感恩的一件事是？',
        color: AppColors.accentContainer,
        accentColor: AppColors.accent,
      ),
      _InspirationPrompt(
        emoji: '💭',
        title: '内心独白',
        question: '此刻你最想对自己说什么？',
        color: AppColors.primaryContainer,
        accentColor: AppColors.primary,
      ),
      _InspirationPrompt(
        emoji: '🎯',
        title: '目标探索',
        question: '最近最想实现的一件事是？',
        color: AppColors.secondaryContainer,
        accentColor: AppColors.secondary,
      ),
      _InspirationPrompt(
        emoji: '🌈',
        title: '幸福瞬间',
        question: '最近让你感到开心的瞬间是？',
        color: AppColors.successContainer,
        accentColor: AppColors.success,
      ),
      _InspirationPrompt(
        emoji: '📚',
        title: '知识分享',
        question: '最近学到的有趣知识是？',
        color: AppColors.purpleSoftContainer,
        accentColor: AppColors.purpleSoft,
      ),
      _InspirationPrompt(
        emoji: '🎭',
        title: '想象力的翅膀',
        question: '如果可以拥有超能力，你想要？',
        color: AppColors.accentContainer,
        accentColor: AppColors.accent,
      ),
      _InspirationPrompt(
        emoji: '💡',
        title: '灵感火花',
        question: '最近在思考的问题是？',
        color: AppColors.primaryContainer,
        accentColor: AppColors.primary,
      ),
      _InspirationPrompt(
        emoji: '🌸',
        title: '美好回忆',
        question: '回想起最温暖的记忆是什么？',
        color: AppColors.primaryContainer,
        accentColor: AppColors.primary,
      ),
      _InspirationPrompt(
        emoji: '☁️',
        title: '放空时刻',
        question: '如果可以放空一天，你想做什么？',
        color: AppColors.secondaryContainer,
        accentColor: AppColors.secondary,
      ),
      _InspirationPrompt(
        emoji: '🌙',
        title: '未来期许',
        question: '对明天有什么期待？',
        color: AppColors.purpleSoftContainer,
        accentColor: AppColors.purpleSoft,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('💭', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            Text(
              '创意提示',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '滑动换一条',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: _prompts.length,
            itemBuilder: (context, index) {
              final prompt = _prompts[index];
              final isActive = index == _currentIndex;
              
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 300),
                  child: _buildPromptCard(prompt),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _prompts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == _currentIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == _currentIndex 
                    ? AppColors.primary 
                    : AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(_InspirationPrompt prompt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: prompt.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: prompt.accentColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(prompt.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: prompt.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prompt.title,
                  style: AppTypography.caption.copyWith(
                    color: prompt.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            prompt.question,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '点击下方按钮记录想法',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspirationPrompt {
  final String emoji;
  final String title;
  final String question;
  final Color color;
  final Color accentColor;

  _InspirationPrompt({
    required this.emoji,
    required this.title,
    required this.question,
    required this.color,
    required this.accentColor,
  });
}
