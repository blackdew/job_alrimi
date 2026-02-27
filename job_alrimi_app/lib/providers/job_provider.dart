import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_item.dart';
import '../repositories/job_repository.dart';

/// 일자리/빈집 목록 상태 관리
class JobProvider extends ChangeNotifier {
  final JobRepository _repository = JobRepository();

  static const String _readIdsKey = 'readItemIds';

  List<JobItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // 'all', 'job', 'house'
  Set<String> _readIds = {};

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
      await _loadReadIds();
      _items = await _repository.fetchAll();
      _applyReadStatus();
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
      _readIds.add(id);
      notifyListeners();
      await _saveReadIds();
    }
  }

  /// 저장된 읽음 ID를 아이템에 적용
  void _applyReadStatus() {
    for (final item in _items) {
      if (_readIds.contains(item.id)) {
        item.isRead = true;
      }
    }
  }

  /// SharedPreferences에서 읽음 ID 로드
  Future<void> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    _readIds = (prefs.getStringList(_readIdsKey) ?? []).toSet();
  }

  /// SharedPreferences에 읽음 ID 저장 (최근 500개만 유지)
  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _readIds.toList();
    if (ids.length > 500) {
      ids.removeRange(0, ids.length - 500);
      _readIds = ids.toSet();
    }
    await prefs.setStringList(_readIdsKey, ids);
  }
}
