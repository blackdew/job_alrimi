import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_item.dart';

/// 일자리/빈집 데이터 Repository
/// UI - Repository - Data Source 패턴
class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 모든 항목 조회 (jobs + houses 컬렉션 병합)
  Future<List<JobItem>> fetchAll() async {
    final jobsSnapshot = await _firestore
        .collection('jobs')
        .orderBy('crawledAt', descending: true)
        .limit(50)
        .get();

    final housesSnapshot = await _firestore
        .collection('houses')
        .orderBy('crawledAt', descending: true)
        .limit(50)
        .get();

    final jobs = jobsSnapshot.docs
        .map((doc) => JobItem.fromFirestore(doc.data(), doc.id))
        .toList();

    final houses = housesSnapshot.docs
        .map((doc) => JobItem.fromFirestore(doc.data(), doc.id))
        .toList();

    final all = [...jobs, ...houses];
    all.sort((a, b) => b.crawledAt.compareTo(a.crawledAt));

    return all;
  }

  /// 일자리만 조회
  Future<List<JobItem>> fetchJobs() async {
    final snapshot = await _firestore
        .collection('jobs')
        .orderBy('crawledAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => JobItem.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// 빈집만 조회
  Future<List<JobItem>> fetchHouses() async {
    final snapshot = await _firestore
        .collection('houses')
        .orderBy('crawledAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => JobItem.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
