import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_item.dart';
import '../theme/app_colors.dart';

/// 상세 화면 - Push to Call UI
class DetailScreen extends StatelessWidget {
  final JobItem item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.typeColor(item.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.type == 'job' ? '일자리 정보' : '빈집 정보'),
      ),
      body: SingleChildScrollView(
        // 5060세대: 여백 확대
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 출처 라벨 - 타입별 색상
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.typeColorLight(item.type),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.type == 'job' ? Icons.work_rounded : Icons.home_rounded,
                    size: 18,
                    color: typeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.sourceLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 제목 - 크기 확대 (28px)
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // 날짜
            Text(
              _formatDate(item.date),
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // 본문 - 크기 확대 및 줄간격 개선
            if (item.description != null) ...[
              Text(
                item.description!,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 키워드 태그 - 타입별 색상
            if (item.keywords.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: item.keywords
                    .map((keyword) => Chip(
                          label: Text(keyword),
                          labelStyle: TextStyle(fontSize: 16, color: typeColor),
                          backgroundColor: AppColors.typeColorLight(item.type),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),

      // 하단 고정: 대형 전화 걸기 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 72,
            child: ElevatedButton.icon(
              onPressed: item.phoneNumber != null
                  ? () => _makePhoneCall(item.phoneNumber!)
                  : null,
              icon: const Icon(Icons.phone, size: 32),
              label: Text(
                item.phoneNumber ?? '전화번호 없음',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.callButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.divider,
                disabledForegroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
