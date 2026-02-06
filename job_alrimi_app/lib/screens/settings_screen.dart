import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

/// 개인정보처리방침 URL
const String _privacyPolicyUrl = 'https://job-alrimi-namhae.web.app/privacy.html';

/// 개인정보처리방침 페이지 열기
Future<void> _launchPrivacyPolicy() async {
  final uri = Uri.parse(_privacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

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
                title: Row(
                  children: [
                    Icon(Icons.work_rounded, color: AppColors.jobColor, size: 24),
                    const SizedBox(width: 8),
                    const Text('일자리 정보', style: TextStyle(fontSize: 18)),
                  ],
                ),
                subtitle: const Text('구인, 채용, 모집 공고'),
                activeTrackColor: AppColors.primaryContainer,
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppColors.primary : null),
                value: settings.subscribeJobs,
                onChanged: (_) => settings.toggleSubscribeJobs(),
              ),

              // 빈집 구독
              SwitchListTile(
                title: Row(
                  children: [
                    Icon(Icons.home_rounded, color: AppColors.houseColor, size: 24),
                    const SizedBox(width: 8),
                    const Text('빈집 정보', style: TextStyle(fontSize: 18)),
                  ],
                ),
                subtitle: const Text('매매, 임대, 월세 정보'),
                activeTrackColor: AppColors.primaryContainer,
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppColors.primary : null),
                value: settings.subscribeHouses,
                onChanged: (_) => settings.toggleSubscribeHouses(),
              ),

              const Divider(height: 32),

              // 알림 설정
              SwitchListTile(
                title: const Row(
                  children: [
                    Icon(Icons.notifications_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text('푸시 알림', style: TextStyle(fontSize: 18)),
                  ],
                ),
                subtitle: const Text('새 정보 알림 받기'),
                activeTrackColor: AppColors.primaryContainer,
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppColors.primary : null),
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
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 개인정보처리방침
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, size: 28),
                title: const Text('개인정보처리방침', style: TextStyle(fontSize: 18)),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchPrivacyPolicy(),
              ),
            ],
          );
        },
      ),
    );
  }
}
