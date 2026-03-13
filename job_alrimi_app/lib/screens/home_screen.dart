import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/job_list_tile.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

/// 메인 홈 화면 - 알림 리스트
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().refresh();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<JobProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('남해 알리미'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 버튼
          _buildFilterButtons(),
          // 목록
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip('전체', 'all', Icons.list_rounded, null, provider),
              const SizedBox(width: 8),
              _filterChip('일자리', 'job', Icons.work_rounded, AppColors.jobColor, provider),
              const SizedBox(width: 8),
              _filterChip('빈집', 'house', Icons.home_rounded, AppColors.houseColor, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value, IconData icon, Color? activeColor, JobProvider provider) {
    final isSelected = provider.filter == value;
    final chipColor = activeColor ?? AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: chipColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        // 로딩 상태 - 친근한 메시지 추가
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
                const SizedBox(height: 24),
                const Text(
                  '정보를 불러오는 중...',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        // 에러 상태 - 큰 버튼으로 개선
        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: provider.refresh,
                      icon: const Icon(Icons.refresh, size: 24),
                      label: const Text('다시 시도', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 빈 상태 - 친근한 메시지와 아이콘
        if (provider.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 80, color: AppColors.divider),
                  const SizedBox(height: 24),
                  const Text(
                    '새로운 정보가 없습니다',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '새 정보가 등록되면\n알림으로 알려드릴게요',
                    style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final itemCount = provider.items.length + (provider.hasMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // 마지막 항목: 로딩 인디케이터
              if (index >= provider.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                );
              }

              final item = provider.items[index];
              return JobListTile(
                item: item,
                onTap: () {
                  provider.markAsRead(item.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(item: item),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
