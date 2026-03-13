import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/job_item.dart';

/// 일자리/빈집 데이터 Repository
/// UI - Repository - Data Source 패턴
class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _pageSize = 30;

  /// 초기 로드: jobs + houses 컬렉션 병합
  Future<FetchResult> fetchAll() async {
    final results = await Future.wait([
      _firestore
          .collection('jobs')
          .orderBy('crawledAt', descending: true)
          .limit(_pageSize)
          .get(),
      _firestore
          .collection('houses')
          .orderBy('crawledAt', descending: true)
          .limit(_pageSize)
          .get(),
    ]);

    final jobsSnapshot = results[0];
    final housesSnapshot = results[1];

    final items = <JobItem>[];
    for (final doc in jobsSnapshot.docs) {
      try {
        items.add(JobItem.fromFirestore(doc.data(), doc.id));
      } catch (e) {
        if (kDebugMode) print('Job parse error: $e');
      }
    }
    for (final doc in housesSnapshot.docs) {
      try {
        items.add(JobItem.fromFirestore(doc.data(), doc.id));
      } catch (e) {
        if (kDebugMode) print('House parse error: $e');
      }
    }

    items.sort((a, b) => b.crawledAt.compareTo(a.crawledAt));

    return FetchResult(
      items: items,
      lastJobDoc: jobsSnapshot.docs.isNotEmpty ? jobsSnapshot.docs.last : null,
      lastHouseDoc:
          housesSnapshot.docs.isNotEmpty ? housesSnapshot.docs.last : null,
      hasMoreJobs: jobsSnapshot.docs.length >= _pageSize,
      hasMoreHouses: housesSnapshot.docs.length >= _pageSize,
    );
  }

  /// 추가 로드 (cursor-based pagination)
  Future<FetchResult> fetchMore({
    DocumentSnapshot? lastJobDoc,
    DocumentSnapshot? lastHouseDoc,
    bool loadJobs = true,
    bool loadHouses = true,
  }) async {
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    if (loadJobs && lastJobDoc != null) {
      futures.add(_firestore
          .collection('jobs')
          .orderBy('crawledAt', descending: true)
          .startAfterDocument(lastJobDoc)
          .limit(_pageSize)
          .get());
    }
    if (loadHouses && lastHouseDoc != null) {
      futures.add(_firestore
          .collection('houses')
          .orderBy('crawledAt', descending: true)
          .startAfterDocument(lastHouseDoc)
          .limit(_pageSize)
          .get());
    }

    if (futures.isEmpty) {
      return FetchResult(
          items: [],
          hasMoreJobs: false,
          hasMoreHouses: false);
    }

    final results = await Future.wait(futures);

    final items = <JobItem>[];
    DocumentSnapshot? newLastJobDoc = lastJobDoc;
    DocumentSnapshot? newLastHouseDoc = lastHouseDoc;
    bool hasMoreJobs = false;
    bool hasMoreHouses = false;

    int resultIndex = 0;
    if (loadJobs && lastJobDoc != null) {
      final snapshot = results[resultIndex++];
      for (final doc in snapshot.docs) {
        try {
          items.add(JobItem.fromFirestore(doc.data(), doc.id));
        } catch (e) {
          if (kDebugMode) print('Job parse error: $e');
        }
      }
      if (snapshot.docs.isNotEmpty) newLastJobDoc = snapshot.docs.last;
      hasMoreJobs = snapshot.docs.length >= _pageSize;
    }
    if (loadHouses && lastHouseDoc != null && resultIndex < results.length) {
      final snapshot = results[resultIndex];
      for (final doc in snapshot.docs) {
        try {
          items.add(JobItem.fromFirestore(doc.data(), doc.id));
        } catch (e) {
          if (kDebugMode) print('House parse error: $e');
        }
      }
      if (snapshot.docs.isNotEmpty) newLastHouseDoc = snapshot.docs.last;
      hasMoreHouses = snapshot.docs.length >= _pageSize;
    }

    items.sort((a, b) => b.crawledAt.compareTo(a.crawledAt));

    return FetchResult(
      items: items,
      lastJobDoc: newLastJobDoc,
      lastHouseDoc: newLastHouseDoc,
      hasMoreJobs: hasMoreJobs,
      hasMoreHouses: hasMoreHouses,
    );
  }
}

/// 페이지네이션 커서를 포함한 조회 결과
class FetchResult {
  final List<JobItem> items;
  final DocumentSnapshot? lastJobDoc;
  final DocumentSnapshot? lastHouseDoc;
  final bool hasMoreJobs;
  final bool hasMoreHouses;

  bool get hasMore => hasMoreJobs || hasMoreHouses;

  FetchResult({
    required this.items,
    this.lastJobDoc,
    this.lastHouseDoc,
    this.hasMoreJobs = false,
    this.hasMoreHouses = false,
  });
}
