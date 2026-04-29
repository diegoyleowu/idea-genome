import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../blocs/idea/idea_bloc.dart';
import '../blocs/idea/idea_state.dart';
import '../blocs/idea/idea_event.dart';
import '../widgets/idea_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('搜索', style: AppTypography.titleLarge)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索想法...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<IdeaBloc>().add(const SearchIdeas(''));
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<IdeaBloc>().add(SearchIdeas(value));
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<IdeaBloc, IdeaState>(
              builder: (context, state) {
                if (state.searchQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('输入关键词搜索想法', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }
                if (state.filteredIdeas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('没有找到匹配的想法', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: state.filteredIdeas.length,
                  itemBuilder: (context, index) {
                    final idea = state.filteredIdeas[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: IdeaCard(idea: idea),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
