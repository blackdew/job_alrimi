import 'package:flutter/foundation.dart';

/// 사용자 설정 상태 관리
class SettingsProvider extends ChangeNotifier {
  // 키워드 구독 설정
  bool _subscribeJobs = true;
  bool _subscribeHouses = true;

  // 알림 설정
  bool _notificationsEnabled = true;

  bool get subscribeJobs => _subscribeJobs;
  bool get subscribeHouses => _subscribeHouses;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleSubscribeJobs() {
    _subscribeJobs = !_subscribeJobs;
    notifyListeners();
    _saveSettings();
  }

  void toggleSubscribeHouses() {
    _subscribeHouses = !_subscribeHouses;
    notifyListeners();
    _saveSettings();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    // TODO: SharedPreferences 또는 Firestore에 저장
  }

  Future<void> loadSettings() async {
    // TODO: 저장된 설정 불러오기
  }
}
