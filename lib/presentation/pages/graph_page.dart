import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/idea.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../blocs/idea/idea_bloc.dart';
import '../blocs/idea/idea_state.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  late AnimationController _simulationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _focusAnimationController;
  late AnimationController _searchAnimationController;

  final List<_Particle> _particles = [];
  final Map<String, _NeuralNode> _nodes = {};
  final Map<String, List<_NeuralEdge>> _edges = {};
  final Map<String, int> _clusterHints = {};

  String? _selectedNodeId;
  String? _draggingNodeId;
  String? _focusedNodeId;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastFocalPoint;
  DateTime? _lastTapTime;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  IdeaType? _filterType;
  Set<String> _highlightedNodeIds = {};
  Offset _targetFocusOffset = Offset.zero;
  bool _isAnimatingFocus = false;

  static const int PARTICLE_COUNT = 40;
  static const double REPULSION = 5000.0;
  static const double ATTRACTION = 0.015;
  static const double DAMPING = 0.85;
  static const double CENTER_GRAVITY = 0.2;

  @override
  void initState() {
    super.initState();

    _simulationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tickSimulation);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_updateFocusAnimation);

    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initParticles();
  }

  void _initParticles() {
    final random = Random();
    for (var i = 0; i < PARTICLE_COUNT; i++) {
      _particles.add(_Particle(
        x: random.nextDouble() * 800 - 100,
        y: random.nextDouble() * 600 - 100,
        vx: (random.nextDouble() - 0.5) * 0.3,
        vy: (random.nextDouble() - 0.5) * 0.3,
        size: random.nextDouble() * 2 + 1,
        alpha: random.nextDouble() * 0.3 + 0.1,
        phase: random.nextDouble() * pi * 2,
      ));
    }
  }

  void _updateFocusAnimation() {
    if (!_isAnimatingFocus) return;
    setState(() {
      final t = Curves.easeInOut.transform(_focusAnimationController.value);
      _offset = Offset.lerp(_offset, _targetFocusOffset, t)!;
    });
  }

  void _animateToNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    final screenCenter = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    _targetFocusOffset = Offset(node.x * _scale - screenCenter.dx, node.y * _scale - screenCenter.dy);

    _isAnimatingFocus = true;
    _focusAnimationController.forward(from: 0).then((_) {
      _isAnimatingFocus = false;
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _updateHighlightedNodes();
    });
  }

  void _setFilterType(IdeaType? type) {
    setState(() {
      _filterType = type;
      _updateHighlightedNodes();
    });
  }

  void _updateHighlightedNodes() {
    _highlightedNodeIds = {};
    if (_searchQuery.isEmpty && _filterType == null) return;

    for (final entry in _nodes.entries) {
      final node = entry.value;
      bool matches = true;

      if (_filterType != null && node.idea.type != _filterType) {
        matches = false;
      }

      if (_searchQuery.isNotEmpty) {
        final titleMatch = node.idea.title.toLowerCase().contains(_searchQuery);
        final contentMatch = node.idea.content.toLowerCase().contains(_searchQuery);
        final tagMatch = node.idea.tags.any((t) => t.toLowerCase().contains(_searchQuery));
        if (!titleMatch && !contentMatch && !tagMatch) {
          matches = false;
        }
      }

      if (matches) {
        _highlightedNodeIds.add(entry.key);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = null;
      _highlightedNodeIds = {};
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _simulationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _focusAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _tickSimulation() {
    if (!mounted) return;
    if (_nodes.isEmpty) return;

    for (final node in _nodes.values) {
      if (node.id == _draggingNodeId) continue;

      double fx = 0, fy = 0;

      final centerX = 400.0;
      final centerY = 300.0;
      fx += (centerX - node.x) * CENTER_GRAVITY * 0.01;
      fy += (centerY - node.y) * CENTER_GRAVITY * 0.01;

      for (final other in _nodes.values) {
        if (other.id == node.id) continue;

        final dx = node.x - other.x;
        final dy = node.y - other.y;
        final distSq = dx * dx + dy * dy + 1;
        final dist = sqrt(distSq);

        fx += REPULSION * dx / distSq;
        fy += REPULSION * dy / distSq;
      }

      for (final edge in _edges.values.expand((e) => e)) {
        if (edge.sourceId != node.id && edge.targetId != node.id) continue;

        final otherId = edge.sourceId == node.id ? edge.targetId : edge.sourceId;
        final other = _nodes[otherId];
        if (other == null) continue;

        final dx = other.x - node.x;
        final dy = other.y - node.y;
        final dist = sqrt(dx * dx + dy * dy) + 1;

        final idealDist = 150.0 - edge.strength * 50;
        final force = (dist - idealDist) * ATTRACTION;

        fx += force * dx / dist;
        fy += force * dy / dist;
      }

      node.vx = (node.vx + fx) * DAMPING;
      node.vy = (node.vy + fy) * DAMPING;

      node.x += node.vx;
      node.y += node.vy;
    }

    for (final particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      if (particle.x < -200) particle.x = 800;
      if (particle.x > 800) particle.x = -200;
      if (particle.y < -200) particle.y = 600;
      if (particle.y > 600) particle.y = -200;
    }

    setState(() {});
  }

  void _initGraph(List<Idea> ideas) {
    if (ideas.isEmpty) return;

    _nodes.clear();
    _edges.clear();
    _clusterHints.clear();

    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;

    final typeGroups = <IdeaType, List<Idea>>{};
    for (final idea in ideas) {
      typeGroups.putIfAbsent(idea.type, () => []).add(idea);
    }

    var clusterIndex = 0;
    for (final group in typeGroups.entries) {
      final angleOffset = clusterIndex * 2 * pi / max(typeGroups.length, 1);
      final clusterRadius = min(screenWidth, screenHeight) * 0.25;

      for (final idea in group.value) {
        final angle = angleOffset + (random.nextDouble() - 0.5) * 1.5;
        final r = random.nextDouble() * clusterRadius * 0.6 + 20;

        _nodes[idea.id] = _NeuralNode(
          id: idea.id,
          x: centerX + r * cos(angle),
          y: centerY + r * sin(angle),
          vx: (random.nextDouble() - 0.5) * 2,
          vy: (random.nextDouble() - 0.5) * 2,
          idea: idea,
          cluster: clusterIndex,
          birthTime: DateTime.now(),
        );
        _clusterHints[idea.id] = clusterIndex;
      }
      clusterIndex++;
    }

    for (var i = 0; i < ideas.length; i++) {
      for (var j = i + 1; j < ideas.length; j++) {
        final similarity = _calculateSimilarity(ideas[i], ideas[j]);
        if (similarity > 0.05) {
          final edge = _NeuralEdge(
            sourceId: ideas[i].id,
            targetId: ideas[j].id,
            strength: similarity,
            particlePhase: random.nextDouble() * pi * 2,
          );
          _edges.putIfAbsent(ideas[i].id, () => []).add(edge);
          _edges.putIfAbsent(ideas[j].id, () => []).add(edge);
        }
      }
    }

    int maxConnections = 0;
    for (final node in _nodes.values) {
      node.connectionCount = _edges[node.id]?.length ?? 0;
      if (node.connectionCount > maxConnections) {
        maxConnections = node.connectionCount;
      }
    }

    for (final node in _nodes.values) {
      node.isHub = node.connectionCount > 1;
      node.maxConnections = maxConnections;
    }

    if (_edges.isEmpty && ideas.length > 1) {
      for (var i = 0; i < ideas.length - 1; i++) {
        final edge = _NeuralEdge(
          sourceId: ideas[i].id,
          targetId: ideas[i + 1].id,
          strength: 0.3,
          particlePhase: random.nextDouble() * pi * 2,
        );
        _edges.putIfAbsent(ideas[i].id, () => []).add(edge);
        _edges.putIfAbsent(ideas[i + 1].id, () => []).add(edge);
      }
    }

    _simulationController.repeat();
  }

  double _calculateSimilarity(Idea a, Idea b) {
    double score = 0.15;

    if (a.type == b.type) score += 0.25;

    if (a.title.toLowerCase() == b.title.toLowerCase()) {
      score += 0.3;
    } else if (a.title.toLowerCase().contains(b.title.toLowerCase()) ||
        b.title.toLowerCase().contains(a.title.toLowerCase())) {
      score += 0.15;
    }

    final aTags = Set<String>.from(a.tags.map((t) => t.toLowerCase()));
    final bTags = Set<String>.from(b.tags.map((t) => t.toLowerCase()));
    if (aTags.isNotEmpty && bTags.isNotEmpty) {
      final intersection = aTags.intersection(bTags);
      if (intersection.isNotEmpty) {
        score += 0.35;
      }
    }

    final aWords = _tokenize(a.content);
    final bWords = _tokenize(b.content);
    if (aWords.isNotEmpty && bWords.isNotEmpty) {
      final intersection = aWords.intersection(bWords);
      if (intersection.isNotEmpty) {
        score += intersection.length / max(aWords.length, bWords.length) * 0.4;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  Set<String> _tokenize(String text) {
    if (text.isEmpty) return {};
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet();
  }

  void _onNodeDrag(String nodeId, Offset delta) {
    final node = _nodes[nodeId];
    if (node == null) return;

    setState(() {
      _draggingNodeId = nodeId;
      node.x += delta.dx / _scale;
      node.y += delta.dy / _scale;
      node.vx = 0;
      node.vy = 0;
    });
  }

  void _onNodeDragEnd(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.vx = (Random().nextDouble() - 0.5) * 2;
    node.vy = (Random().nextDouble() - 0.5) * 2;
    _draggingNodeId = null;
  }

  void _onTapUp(TapUpDetails details, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final localPosition = (details.localPosition - _offset - Offset(centerX, centerY)) / _scale;

    String? tappedId;
    double minDistance = double.infinity;
    for (final entry in _nodes.entries) {
      final node = entry.value;
      final distance = (Offset(node.x, node.y) - localPosition).distance;
      if (distance < 40 && distance < minDistance) {
        minDistance = distance;
        tappedId = entry.key;
      }
    }

    if (tappedId != null) {
      final now = DateTime.now();
      if (_lastTapNodeId == tappedId && _lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 300) {
        setState(() {
          _focusedNodeId = tappedId;
          _selectedNodeId = tappedId;
        });
        _lastTapNodeId = null;
      } else {
        setState(() {
          _selectedNodeId = tappedId;
          _focusedNodeId = null;
        });
        _lastTapNodeId = tappedId;
        _lastTapTime = now;
      }
    } else {
      setState(() {
        _selectedNodeId = null;
        _focusedNodeId = null;
      });
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, BoxConstraints constraints) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() => _offset += const Offset(30, 0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        setState(() => _offset -= const Offset(30, 0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() => _offset += const Offset(0, 30));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setState(() => _offset -= const Offset(0, 30));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        setState(() => _scale = (_scale * 1.2).clamp(0.3, 3.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.minus:
        setState(() => _scale = (_scale / 1.2).clamp(0.3, 3.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit0:
        if (isCtrlPressed) {
          setState(() {
            _scale = 1.0;
            _offset = Offset.zero;
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.escape:
        setState(() {
          _selectedNodeId = null;
          _focusedNodeId = null;
          _searchQuery = '';
          _filterType = null;
          _highlightedNodeIds = {};
          _searchController.clear();
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        if (_selectedNodeId != null) {
          _openIdeaDetail(_nodes[_selectedNodeId]!.idea);
          return KeyEventResult.handled;
        }
        if (_highlightedNodeIds.length == 1) {
          final nodeId = _highlightedNodeIds.first;
          setState(() {
            _selectedNodeId = nodeId;
            _focusedNodeId = nodeId;
          });
          _animateToNode(nodeId);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.tab:
        if (isShiftPressed) {
          _selectPrevNode();
        } else {
          _selectNextNode();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        if (_selectedNodeId != null && isCtrlPressed) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _selectNextNode() {
    if (_nodes.isEmpty) return;

    final nodeIds = _nodes.keys.toList();
    if (_selectedNodeId == null) {
      setState(() => _selectedNodeId = nodeIds.first);
      return;
    }

    final currentIndex = nodeIds.indexOf(_selectedNodeId!);
    final nextIndex = (currentIndex + 1) % nodeIds.length;
    setState(() {
      _selectedNodeId = nodeIds[nextIndex];
      _focusedNodeId = null;
    });
    _animateToNode(nodeIds[nextIndex]);
  }

  void _selectPrevNode() {
    if (_nodes.isEmpty) return;

    final nodeIds = _nodes.keys.toList();
    if (_selectedNodeId == null) {
      setState(() => _selectedNodeId = nodeIds.last);
      return;
    }

    final currentIndex = nodeIds.indexOf(_selectedNodeId!);
    final prevIndex = (currentIndex - 1 + nodeIds.length) % nodeIds.length;
    setState(() {
      _selectedNodeId = nodeIds[prevIndex];
      _focusedNodeId = null;
    });
    _animateToNode(nodeIds[prevIndex]);
  }

  String? _lastTapNodeId;

  void _onLongPress(LongPressStartDetails details, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final localPosition = (details.localPosition - _offset - Offset(centerX, centerY)) / _scale;

    for (final entry in _nodes.entries) {
      final node = entry.value;
      final distance = (Offset(node.x, node.y) - localPosition).distance;
      if (distance < 40) {
        setState(() {
          _selectedNodeId = entry.key;
        });
        _showNodeMenu(entry.key, details.globalPosition);
        break;
      }
    }
  }

  void _showNodeMenu(String nodeId, Offset position) {
    final node = _nodes[nodeId];
    if (node == null) return;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          child: const Row(children: [Icon(Icons.link, size: 18), SizedBox(width: 8), Text('查看关联')]),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Row(children: [Icon(Icons.center_focus_strong, size: 18), SizedBox(width: 8), Text('聚焦此点')]),
          onTap: () {
            setState(() {
              _focusedNodeId = nodeId;
              _selectedNodeId = nodeId;
            });
          },
        ),
        PopupMenuItem(
          child: const Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))]),
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdeaBloc, IdeaState>(
      builder: (context, state) {
        if (state.ideas.isEmpty) {
          return _buildEmptyState();
        }

        if (_nodes.isEmpty || _nodes.length != state.ideas.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _initGraph(state.ideas));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('🌟 创意图谱', style: AppTypography.titleLarge),
            actions: [
              IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () => _initGraph(state.ideas), tooltip: '重新布局'),
              if (_focusedNodeId != null)
                IconButton(icon: const Icon(Icons.center_focus_strong), onPressed: () => setState(() => _focusedNodeId = null), tooltip: '退出聚焦'),
              IconButton(icon: const Icon(Icons.help_outline), onPressed: () => _showHelp(), tooltip: '帮助'),
            ],
          ),
          body: Column(
            children: [
              _buildSearchAndFilter(),
              _buildInsightBar(),
              Expanded(child: _buildGraphCanvas()),
              if (_selectedNodeId != null) _buildSelectedCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: Text('🌟 创意图谱', style: AppTypography.titleLarge)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(Icons.bubble_chart, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text('🎯 图谱使用指南', style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildGuideItem('📝', '记录想法', '在首页记录你的想法、灵感、项目或问题'),
              const SizedBox(height: 12),
              _buildGuideItem('🔗', '自动关联', '相似的内容会自动连接成网络'),
              const SizedBox(height: 12),
              _buildGuideItem('👆', '点击节点', '查看想法详情'),
              const SizedBox(height: 12),
              _buildGuideItem('🤏', '双指缩放', '调整视图大小'),
              const SizedBox(height: 12),
              _buildGuideItem('🤚', '滑动画布', '平移整个视图'),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '记录至少2个想法后\n图谱会自动生成',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(String emoji, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(desc, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '🔍 搜索想法...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearFilters)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
            style: AppTypography.bodyMedium,
            onChanged: _performSearch,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, '全部', Icons.grid_view),
                const SizedBox(width: 8),
                _buildFilterChip(IdeaType.thought, '💡 想法', Icons.lightbulb),
                const SizedBox(width: 8),
                _buildFilterChip(IdeaType.project, '🚀 项目', Icons.rocket),
                const SizedBox(width: 8),
                _buildFilterChip(IdeaType.question, '❓ 问题', Icons.help),
                const SizedBox(width: 8),
                _buildFilterChip(IdeaType.inspiration, '✨ 灵感', Icons.auto_awesome),
              ],
            ),
          ),
          if (_highlightedNodeIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('找到 ${_highlightedNodeIds.length} 个结果', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                  const SizedBox(width: 8),
                  if (_highlightedNodeIds.length == 1)
                    GestureDetector(
                      onTap: () {
                        final nodeId = _highlightedNodeIds.first;
                        _animateToNode(nodeId);
                        setState(() {
                          _selectedNodeId = nodeId;
                          _focusedNodeId = nodeId;
                        });
                      },
                      child: Text('定位', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(IdeaType? type, String label, IconData icon) {
    final isSelected = _filterType == type;
    final color = type != null ? _getNodeColor(type) : AppColors.primary;

    return GestureDetector(
      onTap: () => _setFilterType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption.copyWith(color: isSelected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightBar() {
    if (_nodes.isEmpty) return const SizedBox.shrink();

    final hubNodes = _nodes.values.where((n) => n.isHub).toList();
    final isolatedNodes = _nodes.values.where((n) => n.connectionCount == 0).toList();
    final totalEdges = _edges.values.expand((e) => e).length ~/ 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightChip('🧠 核心', '${hubNodes.length}', AppColors.primary),
              _buildInsightChip('🔗 关联', '$totalEdges', AppColors.secondary),
              _buildInsightChip('💤 孤立', '${isolatedNodes.length}', AppColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('━━━', '强(>60%)', AppColors.primary),
              _buildLegendItem('┅┅┅', '中(30-60%)', AppColors.primary.withOpacity(0.7)),
              _buildLegendItem('ᄀᄀᄀ', '弱(10-30%)', AppColors.textTertiary),
              _buildLegendItem('⋅⋅⋅', '极弱(<10%)', AppColors.textTertiary.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String symbol, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(symbol, style: TextStyle(color: color, fontSize: 10)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ],
    );
  }

  Widget _buildInsightChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(value, style: AppTypography.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildGraphCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleKeyEvent(event, constraints),
          child: GestureDetector(
            onScaleStart: (details) {
              _lastFocalPoint = details.focalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                if (_lastFocalPoint != null && _draggingNodeId == null) {
                  _offset += details.focalPoint - _lastFocalPoint!;
                }
                _lastFocalPoint = details.focalPoint;
                _scale = (_scale * details.scale).clamp(0.3, 3.0);
              });
            },
            onTapUp: (details) => _onTapUp(details, Size(constraints.maxWidth, constraints.maxHeight)),
            onLongPressStart: (details) => _onLongPress(details, Size(constraints.maxWidth, constraints.maxHeight)),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _particleController]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _NeuralGraphPainter(
                        nodes: _nodes,
                        edges: _edges,
                        particles: _particles,
                        offset: _offset,
                        scale: _scale,
                        selectedNodeId: _selectedNodeId,
                        focusedNodeId: _focusedNodeId,
                        pulseValue: _pulseController.value,
                        particlePhase: _particleController.value,
                        viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _buildZoomButton(Icons.add, () => setState(() => _scale = (_scale * 1.3).clamp(0.3, 3.0))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${(_scale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(height: 8),
                      _buildZoomButton(Icons.remove, () => setState(() => _scale = (_scale / 1.3).clamp(0.3, 3.0))),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: _buildMinimap(constraints.maxWidth, constraints.maxHeight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimap(double viewportWidth, double viewportHeight) {
    if (_nodes.isEmpty) return const SizedBox.shrink();

    const minimapWidth = 120.0;
    const minimapHeight = 90.0;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final node in _nodes.values) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
    }

    final padding = 50.0;
    minX -= padding;
    maxX += padding;
    minY -= padding;
    maxY += padding;

    final graphWidth = maxX - minX;
    final graphHeight = maxY - minY;

    return GestureDetector(
      onTapDown: (details) {
        final localX = details.localPosition.dx;
        final localY = details.localPosition.dy;

        final ratioX = localX / minimapWidth;
        final ratioY = localY / minimapHeight;

        final targetX = minX + ratioX * graphWidth - viewportWidth / 2 / _scale;
        final targetY = minY + ratioY * graphHeight - viewportHeight / 2 / _scale;

        setState(() {
          _offset = Offset(-targetX * _scale + viewportWidth / 2, -targetY * _scale + viewportHeight / 2);
        });
      },
      onPanUpdate: (details) {
        final localX = details.localPosition.dx;
        final localY = details.localPosition.dy;

        final ratioX = localX / minimapWidth;
        final ratioY = localY / minimapHeight;

        final targetX = minX + ratioX * graphWidth - viewportWidth / 2 / _scale;
        final targetY = minY + ratioY * graphHeight - viewportHeight / 2 / _scale;

        setState(() {
          _offset = Offset(-targetX * _scale + viewportWidth / 2, -targetY * _scale + viewportHeight / 2);
        });
      },
      child: Container(
        width: minimapWidth,
        height: minimapHeight,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: CustomPaint(
            painter: _MinimapPainter(
              nodes: _nodes,
              edges: _edges,
              minX: minX,
              minY: minY,
              graphWidth: graphWidth,
              graphHeight: graphHeight,
              viewportWidth: viewportWidth,
              viewportHeight: viewportHeight,
              offset: _offset,
              scale: _scale,
              selectedNodeId: _selectedNodeId,
              highlightedNodeIds: _highlightedNodeIds,
            ),
            size: const Size(minimapWidth, minimapHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    final node = _nodes[_selectedNodeId];
    if (node == null) return const SizedBox.shrink();

    final connectedNodes = <_NeuralNode, double>{};
    for (final edge in _edges[_selectedNodeId] ?? []) {
      final otherId = edge.sourceId == _selectedNodeId ? edge.targetId : edge.sourceId;
      final other = _nodes[otherId];
      if (other != null) {
        connectedNodes[other] = edge.strength;
      }
    }

    final sortedConnections = connectedNodes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getNodeColor(node.idea.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getTypeIcon(node.idea.type), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(_getTypeName(node.idea.type), style: AppTypography.caption.copyWith(color: _getNodeColor(node.idea.type), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (node.isHub)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🧠', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('核心节点', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _selectedNodeId = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
                const SizedBox(height: 12),
                Text(node.idea.displayTitle, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(node.idea.summary, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (node.idea.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: node.idea.tags.take(4).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('#$tag', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildConnectionBadge('🔗', '${node.connectionCount}个关联', AppColors.secondary),
                    const SizedBox(width: 8),
                    _buildConnectionBadge('📊', '连接度${((node.connectionCount / max(node.maxConnections, 1)) * 100).toInt()}%', AppColors.primary),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openIdeaDetail(node.idea),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('详情'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (sortedConnections.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关联想法 (${sortedConnections.length})', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedConnections.length.clamp(0, 5),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final entry = sortedConnections[index];
                        final connectedNode = entry.key;
                        final strength = entry.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedNodeId = connectedNode.id;
                              _focusedNodeId = connectedNode.id;
                            });
                            _animateToNode(connectedNode.id);
                          },
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getNodeColor(connectedNode.idea.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _getNodeColor(connectedNode.idea.type).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(_getTypeIcon(connectedNode.idea.type), style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(connectedNode.idea.displayTitle, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStrengthColor(strength).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('${(strength * 100).toInt()}%', style: TextStyle(fontSize: 10, color: _getStrengthColor(strength), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStrengthColor(double strength) {
    if (strength > 0.6) return AppColors.primary;
    if (strength > 0.3) return AppColors.secondary;
    return AppColors.textTertiary;
  }

  void _openIdeaDetail(Idea idea) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<IdeaBloc>(),
          child: _IdeaDetailPage(idea: idea),
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.help_outline), SizedBox(width: 8), Text('图谱使用指南')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('👆', '单击节点', '选中并查看详情'),
            _buildHelpItem('👆👆', '双击节点', '聚焦放大该节点'),
            _buildHelpItem('👆🏹', '长按节点', '弹出快捷菜单'),
            _buildHelpItem('🤚', '拖拽节点', '移动节点位置'),
            _buildHelpItem('🤏', '双指缩放', '放大或缩小视图'),
            _buildHelpItem('🖐️', '滑动画布', '平移视图'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
      ),
    );
  }

  Widget _buildHelpItem(String gesture, String action, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(gesture, style: const TextStyle(fontSize: 18))),
          SizedBox(width: 70, child: Text(action, style: AppTypography.labelMedium)),
          Expanded(child: Text(desc, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  Color _getNodeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }

  String _getTypeIcon(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '💡';
      case IdeaType.project: return '🚀';
      case IdeaType.question: return '❓';
      case IdeaType.inspiration: return '✨';
    }
  }

  String _getTypeName(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '想法';
      case IdeaType.project: return '项目';
      case IdeaType.question: return '问题';
      case IdeaType.inspiration: return '灵感';
    }
  }
}

class _Particle {
  double x, y, vx, vy, size, alpha, phase;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.size, required this.alpha, required this.phase});
}

class _NeuralNode {
  final String id;
  double x, y, vx, vy;
  final Idea idea;
  final int cluster;
  final DateTime birthTime;
  int connectionCount = 0;
  int maxConnections = 0;
  bool isHub = false;

  _NeuralNode({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.idea,
    required this.cluster,
    required this.birthTime,
  });
}

class _NeuralEdge {
  final String sourceId;
  final String targetId;
  final double strength;
  final double particlePhase;

  _NeuralEdge({
    required this.sourceId,
    required this.targetId,
    required this.strength,
    required this.particlePhase,
  });
}

class _MinimapPainter extends CustomPainter {
  final Map<String, _NeuralNode> nodes;
  final Map<String, List<_NeuralEdge>> edges;
  final double minX;
  final double minY;
  final double graphWidth;
  final double graphHeight;
  final double viewportWidth;
  final double viewportHeight;
  final Offset offset;
  final double scale;
  final String? selectedNodeId;
  final Set<String> highlightedNodeIds;

  _MinimapPainter({
    required this.nodes,
    required this.edges,
    required this.minX,
    required this.minY,
    required this.graphWidth,
    required this.graphHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.offset,
    required this.scale,
    this.selectedNodeId,
    required this.highlightedNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    for (final edgeList in edges.values) {
      for (final edge in edgeList) {
        final source = nodes[edge.sourceId];
        final target = nodes[edge.targetId];
        if (source == null || target == null) continue;

        final x1 = (source.x - minX) / graphWidth * size.width;
        final y1 = (source.y - minY) / graphHeight * size.height;
        final x2 = (target.x - minX) / graphWidth * size.width;
        final y2 = (target.y - minY) / graphHeight * size.height;

        final paint = Paint()
          ..color = AppColors.textTertiary.withOpacity(0.3)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }

    for (final entry in nodes.entries) {
      final node = entry.value;
      final x = (node.x - minX) / graphWidth * size.width;
      final y = (node.y - minY) / graphHeight * size.height;

      Color nodeColor = _getNodeColor(node.idea.type);
      if (highlightedNodeIds.contains(entry.key)) {
        nodeColor = AppColors.primary;
      }
      if (selectedNodeId == entry.key) {
        nodeColor = Colors.white;
      }

      final radius = selectedNodeId == entry.key ? 4.0 : 2.5;
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = nodeColor);
    }

    final viewportLeft = (-offset.dx / scale - minX) / graphWidth * size.width;
    final viewportTop = (-offset.dy / scale - minY) / graphHeight * size.height;
    final viewportW = (viewportWidth / scale) / graphWidth * size.width;
    final viewportH = (viewportHeight / scale) / graphHeight * size.height;

    final viewportPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(viewportLeft, viewportTop, viewportW, viewportH), viewportPaint);

    final viewportBorderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(viewportLeft, viewportTop, viewportW, viewportH), viewportBorderPaint);
  }

  Color _getNodeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}

class _NeuralGraphPainter extends CustomPainter {
  final Map<String, _NeuralNode> nodes;
  final Map<String, List<_NeuralEdge>> edges;
  final List<_Particle> particles;
  final Offset offset;
  final double scale;
  final String? selectedNodeId;
  final String? focusedNodeId;
  final double pulseValue;
  final double particlePhase;
  final Size viewportSize;

  _NeuralGraphPainter({
    required this.nodes,
    required this.edges,
    required this.particles,
    required this.offset,
    required this.scale,
    this.selectedNodeId,
    this.focusedNodeId,
    required this.pulseValue,
    required this.particlePhase,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx + size.width / 2, offset.dy + size.height / 2);
    canvas.scale(scale);

    if (focusedNodeId != null) {
      final focused = nodes[focusedNodeId];
      if (focused != null) {
        canvas.translate(-focused.x * 0.3, -focused.y * 0.3);
      }
    }

    _drawBackground(canvas, size);
    _drawEdges(canvas);
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF1a1a2e).withOpacity(0.3),
          const Color(0xFF16213e).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: 800, height: 600));
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 1000, height: 800), bgPaint);

    for (final particle in particles) {
      final breathe = sin(particlePhase * 2 * pi + particle.phase) * 0.5 + 0.5;
      final alpha = particle.alpha * (0.5 + breathe * 0.5);

      final paint = Paint()
        ..color = AppColors.primary.withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(particle.x - 400, particle.y - 300), particle.size * (1 + breathe * 0.5), paint);
    }
  }

  void _drawEdges(Canvas canvas) {
    final drawnEdges = <String>{};

    for (final edgeList in edges.values) {
      for (final edge in edgeList) {
        final key = [edge.sourceId, edge.targetId]..sort();
        final edgeKey = key.join('-');
        if (drawnEdges.contains(edgeKey)) continue;
        drawnEdges.add(edgeKey);

        final source = nodes[edge.sourceId];
        final target = nodes[edge.targetId];
        if (source == null || target == null) continue;

        final isHighlighted = selectedNodeId == edge.sourceId || selectedNodeId == edge.targetId;
        final isFocused = focusedNodeId != null;

        if (isFocused && !isHighlighted) continue;

        _drawConnection(canvas, source, target, edge, isHighlighted, isFocused);
      }
    }
  }

  void _drawConnection(Canvas canvas, _NeuralNode source, _NeuralNode target, _NeuralEdge edge, bool isHighlighted, bool isFocused) {
    final strength = edge.strength;

    Color lineColor;
    double lineWidth;
    double alpha;
    bool drawParticle = false;
    bool isDashed = false;
    bool isDotted = false;

    if (strength > 0.6) {
      lineColor = AppColors.primary;
      lineWidth = isHighlighted ? 4.0 : 3.0;
      alpha = isHighlighted ? 0.9 : 0.7;
      drawParticle = true;
    } else if (strength > 0.3) {
      lineColor = AppColors.primary.withOpacity(0.7);
      lineWidth = isHighlighted ? 2.5 : 1.8;
      alpha = isHighlighted ? 0.7 : 0.5;
    } else if (strength > 0.1) {
      lineColor = AppColors.textTertiary.withOpacity(0.5);
      lineWidth = isHighlighted ? 1.5 : 1.0;
      alpha = isHighlighted ? 0.5 : 0.3;
      isDashed = true;
    } else {
      lineColor = AppColors.textTertiary.withOpacity(0.25);
      lineWidth = isHighlighted ? 1.0 : 0.5;
      alpha = isHighlighted ? 0.4 : 0.15;
      isDotted = true;
    }

    if (isFocused) {
      alpha *= 0.6;
    }

    final path = Path();
    path.moveTo(source.x, source.y);

    final midX = (source.x + target.x) / 2;
    final midY = (source.y + target.y) / 2;
    final perpX = -(target.y - source.y) * 0.15;
    final perpY = (target.x - source.x) * 0.15;

    path.quadraticBezierTo(midX + perpX, midY + perpY, target.x, target.y);

    if (isDotted) {
      _drawDottedPath(canvas, path, lineColor.withOpacity(alpha), lineWidth);
    } else if (isDashed) {
      _drawDashedPath(canvas, path, lineColor.withOpacity(alpha), lineWidth);
    } else {
      final paint = Paint()
        ..color = lineColor.withOpacity(alpha)
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }

    if (drawParticle && (isHighlighted || strength > 0.8)) {
      final particleT = (particlePhase + edge.particlePhase) % 1.0;
      final particleX = source.x + (target.x - source.x) * particleT;
      final particleY = source.y + (target.y - source.y) * particleT;

      final glowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(particleX, particleY), 5, glowPaint);

      final innerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(particleX, particleY), 3, innerPaint);

      final particleT2 = (particlePhase + edge.particlePhase + 0.5) % 1.0;
      final particle2X = source.x + (target.x - source.x) * particleT2;
      final particle2Y = source.y + (target.y - source.y) * particleT2;
      final glowPaint2 = Paint()
        ..color = AppColors.secondary.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(particle2X, particle2Y), 3, glowPaint2);
      canvas.drawCircle(Offset(particle2X, particle2Y), 2, innerPaint..color = Colors.white.withOpacity(0.8));
    }

    if (isHighlighted && strength > 0.3) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${(strength * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: lineColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromCenter(
        center: Offset(midX + perpX * 0.5, midY + perpY * 0.5),
        width: labelPainter.width + 8,
        height: labelPainter.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = Colors.black.withOpacity(0.5),
      );
      labelPainter.paint(canvas, Offset(bgRect.left + 4, bgRect.top + 2));
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashLength = 8.0;
        final gapLength = 4.0;

        final dashPath = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(dashPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dotLength = 2.0;
        final gapLength = 6.0;

        final dotPath = metric.extractPath(distance, distance + dotLength);
        canvas.drawPath(dotPath, paint);
        distance += dotLength + gapLength;
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    _drawClusterAuras(canvas);
    for (final entry in nodes.entries) {
      final node = entry.value;
      _drawNode(canvas, node, entry.key);
    }
  }

  void _drawClusterAuras(Canvas canvas) {
    final clusterCenters = <int, List<_NeuralNode>>{};
    for (final node in nodes.values) {
      clusterCenters.putIfAbsent(node.cluster, () => []).add(node);
    }

    for (final entry in clusterCenters.entries) {
      if (entry.value.length < 2) continue;

      double centerX = 0, centerY = 0;
      for (final node in entry.value) {
        centerX += node.x;
        centerY += node.y;
      }
      centerX /= entry.value.length;
      centerY /= entry.value.length;

      final color = _getNodeColor(entry.value.first.idea.type);
      final auraRadius = 60.0 + entry.value.length * 8.0;

      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: auraRadius));

      canvas.drawCircle(Offset(centerX, centerY), auraRadius, auraPaint);
    }
  }

  void _drawNode(Canvas canvas, _NeuralNode node, String nodeId) {
    final isSelected = selectedNodeId == nodeId;
    final isFocused = focusedNodeId == nodeId;

    double connectionRatio = 0;
    if (node.maxConnections > 0) {
      connectionRatio = node.connectionCount / node.maxConnections;
    }

    final sizeBonus = connectionRatio * 12.0;
    final baseRadius = isSelected ? 32.0 : (isFocused ? 38.0 : 16.0 + sizeBonus);
    final birthAge = DateTime.now().difference(node.birthTime).inSeconds;
    final birthPulse = birthAge < 3 ? sin(birthAge * pi) * (3 - birthAge) * 5 : 0.0;
    final hubPulse = sin(pulseValue * pi * 2) * (node.isHub ? 4.0 : 2.0);
    final radius = baseRadius + hubPulse + birthPulse;

    if (node.connectionCount > 0) {
      final ringRadius = radius + 8 + connectionRatio * 6;
      final ringPaint = Paint()
        ..color = _getNodeColor(node.idea.type).withOpacity(0.3 + connectionRatio * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + connectionRatio * 2;
      canvas.drawCircle(Offset(node.x, node.y), ringRadius, ringPaint);
    }

    final glowRadius = radius + (isSelected ? 25 : (isFocused ? 35 : 15));
    final glowAlpha = isSelected ? 0.5 : (isFocused ? 0.6 : 0.25);
    final glowPaint = Paint()
      ..color = _getNodeColor(node.idea.type).withOpacity(glowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.6);
    canvas.drawCircle(Offset(node.x, node.y), glowRadius, glowPaint);

    final nodePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          _getNodeColor(node.idea.type).withOpacity(0.95),
          _getNodeColor(node.idea.type),
          _getNodeColor(node.idea.type).withOpacity(0.75),
        ],
      ).createShader(Rect.fromCircle(center: Offset(node.x, node.y), radius: radius));
    canvas.drawCircle(Offset(node.x, node.y), radius, nodePaint);

    if (isSelected || isFocused) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(node.x, node.y), radius, borderPaint);
    }

    final innerGlow = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(node.x - radius * 0.3, node.y - radius * 0.3), radius * 0.35, innerGlow);

    final icon = _getTypeIcon(node.idea.type);
    final iconPainter = TextPainter(
      text: TextSpan(text: icon, style: TextStyle(fontSize: radius * 0.65)),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(node.x - iconPainter.width / 2, node.y - iconPainter.height / 2));

    if (scale > 0.5) {
      final title = node.idea.displayTitle;
      final maxLen = isSelected ? 18 : 10;
      final displayTitle = title.length > maxLen ? '${title.substring(0, maxLen)}...' : title;

      final textBgPaint = Paint()..color = Colors.black.withOpacity(0.6);
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayTitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textRect = Rect.fromLTWH(
        node.x - textPainter.width / 2 - 4,
        node.y + radius + 6,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(textRect, const Radius.circular(4)), textBgPaint);
      textPainter.paint(canvas, Offset(node.x - textPainter.width / 2, node.y + radius + 8));
    }

    if (node.isHub && (isSelected || isFocused)) {
      final hubPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(node.x, node.y), radius + 6, hubPaint);

      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4 + pulseValue * pi * 2;
        final dotX = node.x + cos(angle) * (radius + 12);
        final dotY = node.y + sin(angle) * (radius + 12);
        canvas.drawCircle(Offset(dotX, dotY), 2, hubPaint);
      }
    }
  }

  Color _getNodeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }

  String _getTypeIcon(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '💡';
      case IdeaType.project: return '🚀';
      case IdeaType.question: return '❓';
      case IdeaType.inspiration: return '✨';
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralGraphPainter oldDelegate) => true;
}

class _IdeaDetailPage extends StatelessWidget {
  final Idea idea;
  const _IdeaDetailPage({required this.idea});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(idea.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getTypeColor(idea.type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getTypeIcon(idea.type), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_getTypeName(idea.type), style: TextStyle(color: _getTypeColor(idea.type), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(idea.displayTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('创建于 ${_formatDate(idea.createdAt)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(idea.content, style: const TextStyle(fontSize: 16, height: 1.6)),
            ),
            if (idea.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: idea.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('#$tag', style: TextStyle(color: Colors.blue[700], fontSize: 13)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return AppColors.thoughtColor;
      case IdeaType.project: return AppColors.projectColor;
      case IdeaType.question: return AppColors.questionColor;
      case IdeaType.inspiration: return AppColors.inspirationColor;
    }
  }

  String _getTypeIcon(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '💡';
      case IdeaType.project: return '🚀';
      case IdeaType.question: return '❓';
      case IdeaType.inspiration: return '✨';
    }
  }

  String _getTypeName(IdeaType type) {
    switch (type) {
      case IdeaType.thought: return '想法';
      case IdeaType.project: return '项目';
      case IdeaType.question: return '问题';
      case IdeaType.inspiration: return '灵感';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
