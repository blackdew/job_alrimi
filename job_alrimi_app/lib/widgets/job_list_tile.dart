import 'package:flutter/material.dart';
import '../models/job_item.dart';

/// 목록 아이템 위젯
class JobListTile extends StatelessWidget {
  final JobItem item;
  final VoidCallback onTap;

  const JobListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // 안읽은 항목: 왼쪽 빨간 테두리로 강조
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isRead
            ? BorderSide.none
            : const BorderSide(color: Colors.red, width: 3),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // 5060세대: 터치 영역 및 여백 확대
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 타입 아이콘 - 56x56px (최소 터치 타겟)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.type == 'job'
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    item.typeEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 출처 - 색상 대비 강화
                    Text(
                      item.sourceLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 제목 - 글씨 크기 확대
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 날짜 - 색상 대비 강화
                    Text(
                      _formatRelativeDate(item.date),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // 읽지 않음: NEW 뱃지로 변경 (빨간 점보다 명확함)
              if (!item.isRead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}
