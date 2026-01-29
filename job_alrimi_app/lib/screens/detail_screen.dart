import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_item.dart';

/// 상세 화면 - Push to Call UI
class DetailScreen extends StatelessWidget {
  final JobItem item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.typeEmoji),
      ),
      body: SingleChildScrollView(
        // 5060세대: 여백 확대
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 출처 라벨 - 크기 확대
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.sourceLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // 제목 - 크기 확대 (28px)
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // 날짜 - 색상 대비 강화
            Text(
              _formatDate(item.date),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 28),

            // 본문 - 크기 확대 및 줄간격 개선
            if (item.description != null) ...[
              Text(
                item.description!,
                style: const TextStyle(fontSize: 20, height: 1.7),
              ),
              const SizedBox(height: 32),
            ],

            // 키워드 태그 - 크기 확대
            if (item.keywords.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: item.keywords
                    .map((keyword) => Chip(
                          label: Text(keyword),
                          labelStyle: const TextStyle(fontSize: 16),
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
