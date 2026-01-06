import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// 설정 화면 - 키워드 구독
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '알림 받을 정보 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 일자리 구독
              SwitchListTile(
                title: const Text('💼 일자리 정보', style: TextStyle(fontSize: 18)),
                subtitle: const Text('구인, 채용, 모집 공고'),
                value: settings.subscribeJobs,
                onChanged: (_) => settings.toggleSubscribeJobs(),
              ),

              // 빈집 구독
              SwitchListTile(
                title: const Text('🏠 빈집 정보', style: TextStyle(fontSize: 18)),
                subtitle: const Text('매매, 임대, 월세 정보'),
                value: settings.subscribeHouses,
                onChanged: (_) => settings.toggleSubscribeHouses(),
              ),

              const Divider(height: 32),

              // 알림 설정
              SwitchListTile(
                title: const Text('🔔 푸시 알림', style: TextStyle(fontSize: 18)),
                subtitle: const Text('새 정보 알림 받기'),
                value: settings.notificationsEnabled,
                onChanged: (_) => settings.toggleNotifications(),
              ),

              const SizedBox(height: 32),

              // 앱 정보
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '남해 알리미',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('버전 1.0.0'),
                    SizedBox(height: 8),
                    Text(
                      '남해군 일자리·빈집 정보를\n실시간으로 알려드립니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
