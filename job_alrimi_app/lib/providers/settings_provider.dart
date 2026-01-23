import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 사용자 설정 상태 관리
class SettingsProvider extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 키워드 구독 설정
  bool _subscribeJobs = true;
  bool _subscribeHouses = true;

  // 알림 설정
  bool _notificationsEnabled = true;

  bool get subscribeJobs => _subscribeJobs;
  bool get subscribeHouses => _subscribeHouses;
  bool get notificationsEnabled => _notificationsEnabled;

  /// 초기화 시 토픽 구독 상태 설정
  Future<void> initializeTopics() async {
    // 저장된 설정 로드 후 토픽 구독 상태 설정
    await loadSettings();
    await _syncTopicSubscriptions();
  }

  void toggleSubscribeJobs() {
    _subscribeJobs = !_subscribeJobs;
    notifyListeners();
    _saveSettings();
    _updateJobsTopicSubscription();
  }

  void toggleSubscribeHouses() {
    _subscribeHouses = !_subscribeHouses;
    notifyListeners();
    _saveSettings();
    _updateHousesTopicSubscription();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    _saveSettings();
    _syncTopicSubscriptions();
  }

  /// jobs 토픽 구독/해제
  Future<void> _updateJobsTopicSubscription() async {
    if (_subscribeJobs && _notificationsEnabled) {
      await _messaging.subscribeToTopic('jobs');
      if (kDebugMode) {
        print('FCM: jobs 토픽 구독');
      }
    } else {
      await _messaging.unsubscribeFromTopic('jobs');
      if (kDebugMode) {
        print('FCM: jobs 토픽 해제');
      }
    }
  }

  /// houses 토픽 구독/해제
  Future<void> _updateHousesTopicSubscription() async {
    if (_subscribeHouses && _notificationsEnabled) {
      await _messaging.subscribeToTopic('houses');
      if (kDebugMode) {
        print('FCM: houses 토픽 구독');
      }
    } else {
      await _messaging.unsubscribeFromTopic('houses');
      if (kDebugMode) {
        print('FCM: houses 토픽 해제');
      }
    }
  }

  /// 모든 토픽 구독 상태 동기화
  Future<void> _syncTopicSubscriptions() async {
    await _updateJobsTopicSubscription();
    await _updateHousesTopicSubscription();
  }

  Future<void> _saveSettings() async {
    // TODO: SharedPreferences에 저장 (US011에서 구현)
  }

  Future<void> loadSettings() async {
    // TODO: 저장된 설정 불러오기 (US011에서 구현)
  }
}
