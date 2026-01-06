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
      label: Text(label, style: const TextStyle(fontSize: 16)),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(value),
    );
  }

  Widget _buildList() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.error!, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refresh,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (provider.items.isEmpty) {
          return const Center(
            child: Text('표시할 정보가 없습니다.', style: TextStyle(fontSize: 18)),
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
