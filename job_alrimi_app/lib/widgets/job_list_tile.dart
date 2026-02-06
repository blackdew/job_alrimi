import 'package:flutter/material.dart';
import '../models/job_item.dart';
import '../theme/app_colors.dart';

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
    final typeColor = AppColors.typeColor(item.type);
    final typeColorLight = AppColors.typeColorLight(item.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: item.isRead ? AppColors.readCardBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: item.isRead ? 0 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // 안읽은 항목: 왼쪽 초록 바로 표시 (빨간 테두리 대체)
              border: Border(
                left: BorderSide(
                  color: item.isRead
                      ? Colors.transparent
                      : AppColors.unreadIndicator,
                  width: 4,
                ),
              ),
            ),
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
                      color: typeColorLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.type == 'job' ? Icons.work_rounded : Icons.home_rounded,
                      color: typeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 내용
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 출처 + NEW 뱃지 (한 줄)
                        Row(
                          children: [
                            Text(
                              item.sourceLabel,
                              style: TextStyle(
                                fontSize: 16,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.newBadge,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 제목 - 글씨 크기 확대
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // 날짜
                        Text(
                          _formatRelativeDate(item.date),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
