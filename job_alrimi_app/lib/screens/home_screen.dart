import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
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
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().refresh();
    });
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _filterChip('전체', 'all', provider),
              const SizedBox(width: 8),
              _filterChip('💼 일자리', 'job', provider),
              const SizedBox(width: 8),
              _filterChip('🏠 빈집', 'house', provider),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value, JobProvider provider) {
    final isSelected = provider.filter == value;
    return FilterChip(
      // 5060세대: 글씨 크기 및 터치 영역 확대
      label: Text(label, style: const TextStyle(fontSize: 18)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(value),
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
                Text(
                  '정보를 불러오는 중...',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
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
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text(
                    '새로운 정보가 없습니다',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '새 정보가 등록되면\n알림으로 알려드릴게요',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
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
