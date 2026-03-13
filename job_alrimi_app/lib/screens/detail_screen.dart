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

            // 빈집 부가정보 표
            if (item.type == 'house' && _hasHouseDetails()) ...[
              _buildHouseDetails(typeColor),
              const SizedBox(height: 28),
            ],

            // 원문 보기 버튼
            if (item.link != null && item.link!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _openLink(item.link!),
                  icon: const Icon(Icons.open_in_new, size: 24),
                  label: const Text(
                    '원문 보기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: typeColor,
                    side: BorderSide(color: typeColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
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

  bool _hasHouseDetails() {
    return item.address != null ||
        item.landArea != null ||
        item.buildArea != null ||
        item.structure != null ||
        item.buildYear != null;
  }

  Widget _buildHouseDetails(Color typeColor) {
    final details = <MapEntry<String, String>>[];
    if (item.address != null) details.add(MapEntry('주소', item.address!));
    if (item.landArea != null) details.add(MapEntry('대지면적', '${item.landArea}㎡'));
    if (item.buildArea != null) details.add(MapEntry('건물면적', '${item.buildArea}㎡'));
    if (item.structure != null) details.add(MapEntry('구조', item.structure!));
    if (item.buildYear != null) details.add(MapEntry('건축년도', item.buildYear!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.houseColorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 정보',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          const SizedBox(height: 16),
          ...details.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
