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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 출처 라벨
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.sourceLabel,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // 제목
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 날짜
            Text(
              _formatDate(item.date),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 본문
            if (item.description != null) ...[
              Text(
                item.description!,
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
              const SizedBox(height: 32),
            ],

            // 키워드 태그
            if (item.keywords.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.keywords
                    .map((keyword) => Chip(label: Text(keyword)))
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
