import '../models/job_item.dart';

/// 일자리/빈집 데이터 Repository
/// UI - Repository - Data Source 패턴
class JobRepository {
  // TODO: Firestore 연동
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 모든 항목 조회
  Future<List<JobItem>> fetchAll() async {
    // TODO: Firestore에서 데이터 가져오기
    // final snapshot = await _firestore
    //     .collection('items')
    //     .orderBy('crawledAt', descending: true)
    //     .limit(50)
    //     .get();
    // return snapshot.docs
    //     .map((doc) => JobItem.fromFirestore(doc.data(), doc.id))
    //     .toList();

    // 임시 더미 데이터
    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyData();
  }

  /// 일자리만 조회
  Future<List<JobItem>> fetchJobs() async {
    final all = await fetchAll();
    return all.where((item) => item.type == 'job').toList();
  }

  /// 빈집만 조회
  Future<List<JobItem>> fetchHouses() async {
    final all = await fetchAll();
    return all.where((item) => item.type == 'house').toList();
  }

  /// 테스트용 더미 데이터
  List<JobItem> _dummyData() {
    return [
      JobItem(
        id: '1',
        title: '남해군 공공근로 참여자 모집',
        source: 'saeol',
        type: 'job',
        description: '남해군에서 공공근로 참여자를 모집합니다.',
        phoneNumber: '055-860-3000',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        crawledAt: DateTime.now(),
        keywords: ['공공근로', '모집'],
      ),
      JobItem(
        id: '2',
        title: '남해읍 농가주택 매매',
        source: 'refarm',
        type: 'house',
        description: '남해읍 소재 농가주택 매매합니다. 토지 300평, 건물 30평',
        phoneNumber: '010-1234-5678',
        date: DateTime.now().subtract(const Duration(days: 1)),
        crawledAt: DateTime.now(),
        keywords: ['농가주택', '매매'],
      ),
      JobItem(
        id: '3',
        title: '수산물 가공공장 직원 채용',
        source: 'board',
        type: 'job',
        description: '미조면 수산물 가공공장에서 직원을 채용합니다.',
        phoneNumber: '055-867-1234',
        date: DateTime.now().subtract(const Duration(days: 2)),
        crawledAt: DateTime.now(),
        keywords: ['수산', '채용'],
      ),
    ];
  }
}
