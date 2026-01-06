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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 타입 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.type == 'job'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.typeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 출처
                    Text(
                      item.sourceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 제목
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 날짜
                    Text(
                      _formatRelativeDate(item.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // 읽지 않음 표시
              if (!item.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
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
