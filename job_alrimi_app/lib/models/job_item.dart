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
      source: data['sourceName'] ?? data['source'] ?? '',
      type: data['type'] ?? 'job',
      description: data['description'],
      phoneNumber: _extractPhone(data['phones']),
      link: data['link'],
      date: _parseDate(data['date']),
      crawledAt: _parseDate(data['crawledAt']),
      keywords: List<String>.from(data['keywords'] ?? []),
      isRead: data['isRead'] ?? false,
    );
  }

  /// 날짜 파싱 (Timestamp, String, null 모두 처리)
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    // Firestore Timestamp (try-catch로 안전하게 처리)
    try {
      final date = value.toDate();
      if (date is DateTime) return date;
    } catch (_) {
      // toDate() 메서드가 없는 경우 무시
    }
    return DateTime.now();
  }

  /// phones 배열에서 첫 번째 전화번호 추출
  static String? _extractPhone(dynamic phones) {
    if (phones == null) return null;
    if (phones is List && phones.isNotEmpty) {
      return phones.first.toString();
    }
    if (phones is String) return phones;
    return null;
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
