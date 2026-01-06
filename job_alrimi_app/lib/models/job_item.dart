/// 일자리/빈집 정보 모델
class JobItem {
  final String id;
  final String title;
  final String source;
  final String type; // 'job' or 'house'
  final String? description;
  final String? phoneNumber;
  final String? link;
  final DateTime date;
  final DateTime crawledAt;
  final List<String> keywords;
  bool isRead;

  JobItem({
    required this.id,
    required this.title,
    required this.source,
    required this.type,
    this.description,
    this.phoneNumber,
    this.link,
    required this.date,
    required this.crawledAt,
    this.keywords = const [],
    this.isRead = false,
  });

  factory JobItem.fromFirestore(Map<String, dynamic> data, String id) {
    return JobItem(
      id: id,
      title: data['title'] ?? '',
      source: data['source'] ?? '',
      type: data['type'] ?? 'job',
      description: data['description'],
      phoneNumber: data['phoneNumber'],
      link: data['link'],
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      crawledAt: (data['crawledAt'] as dynamic)?.toDate() ?? DateTime.now(),
      keywords: List<String>.from(data['keywords'] ?? []),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'source': source,
      'type': type,
      'description': description,
      'phoneNumber': phoneNumber,
      'link': link,
      'date': date,
      'crawledAt': crawledAt,
      'keywords': keywords,
      'isRead': isRead,
    };
  }

  /// 출처 표시 텍스트
  String get sourceLabel {
    switch (source) {
      case 'saeol':
        return '새올';
      case 'board':
        return '구인구직';
      case 'worknet':
        return '워크넷';
      case 'refarm':
        return '귀농귀촌';
      case 'greendaero':
        return '그린대로';
      default:
        return source;
    }
  }

  /// 타입 아이콘
  String get typeEmoji => type == 'job' ? '💼' : '🏠';
}
