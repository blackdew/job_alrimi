import 'package:flutter/foundation.dart';
import '../models/job_item.dart';
import '../repositories/job_repository.dart';

/// 일자리/빈집 목록 상태 관리
class JobProvider extends ChangeNotifier {
  final JobRepository _repository = JobRepository();

  List<JobItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // 'all', 'job', 'house'

  List<JobItem> get items {
    if (_filter == 'all') return _items;
    return _items.where((item) => item.type == _filter).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  int get unreadCount => _items.where((item) => !item.isRead).length;

  /// 목록 새로고침
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchAll();
      _error = null;
    } catch (e) {
      _error = '데이터를 불러오는데 실패했습니다.';
      debugPrint('JobProvider.refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 필터 변경
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  /// 읽음 처리
  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isRead = true;
      notifyListeners();
      // TODO: Firestore 업데이트
    }
  }
}
