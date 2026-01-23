import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/job_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'models/job_item.dart';

/// 딥링크 네비게이션을 위한 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM Background 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM 초기화
  await _initializeFCM();

  runApp(const MyApp());
}

/// FCM 초기화 및 권한 요청
Future<void> _initializeFCM() async {
  final messaging = FirebaseMessaging.instance;

  // 알림 권한 요청
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (kDebugMode) {
    print('FCM 권한 상태: ${settings.authorizationStatus}');
  }

  // FCM 토큰 가져오기 (디버그용)
  final token = await messaging.getToken();
  if (kDebugMode) {
    print('FCM Token: $token');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsProvider _settingsProvider = SettingsProvider();
  final JobProvider _jobProvider = JobProvider();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupFCMListeners();
  }

  Future<void> _initializeApp() async {
    // 설정 로드 및 토픽 구독 초기화
    await _settingsProvider.initializeTopics();

    // 앱이 종료된 상태에서 알림으로 실행된 경우 처리
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  /// FCM 메시지 리스너 설정
  void _setupFCMListeners() {
    // Foreground 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.notification?.title}');
      }
      // Foreground에서는 시스템 알림이 표시되지 않으므로
      // 필요시 로컬 알림이나 인앱 알림을 표시할 수 있음
      // 현재는 로그만 출력
    });

    // Background 상태에서 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message opened app: ${message.notification?.title}');
      }
      _handleMessage(message);
    });
  }

  /// FCM 메시지 데이터에서 딥링크 처리
  Future<void> _handleMessage(RemoteMessage message) async {
    final itemId = message.data['itemId'];
    final type = message.data['type'];

    if (kDebugMode) {
      print('Handle message - itemId: $itemId, type: $type');
    }

    if (itemId == null || type == null) return;

    await _navigateToDetail(itemId, type);
  }

  /// Firestore에서 아이템 조회 후 상세 화면으로 이동
  Future<void> _navigateToDetail(String itemId, String type) async {
    try {
      final collection = type == 'job' ? 'jobs' : 'houses';
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(itemId)
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('Document not found: $collection/$itemId');
        }
        return;
      }

      final item = JobItem.fromFirestore(doc.data()!, doc.id);

      // GlobalKey를 통해 네비게이션
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to detail: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _jobProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
      ],
      child: MaterialApp(
        title: '남해 알리미',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // 5060세대 고려: 기본 글씨 크기 확대
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
