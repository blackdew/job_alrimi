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

/// 웹 푸시용 VAPID 키 (Firebase Console > 프로젝트 설정 > 클라우드 메시징 > 웹 구성)
const String _webVapidKey = 'BCrWHUg9PGYeQtlspWHhZ1aIvatOK-raZjkvz-ZxPz2Tm9qDHHZGzosLqH6ysmncom7-cunqosu0soaEpeqH0h4';

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

  // FCM 토큰 가져오기
  // 웹에서는 VAPID 키가 필요
  String? token;
  if (kIsWeb) {
    // 웹: VAPID 키로 토큰 요청
    if (_webVapidKey != 'YOUR_VAPID_KEY_HERE') {
      token = await messaging.getToken(vapidKey: _webVapidKey);
      // 웹 토큰을 Firestore에 저장 (서버 측 토픽 구독용)
      if (token != null) {
        await _saveWebTokenToFirestore(token);
      }
    } else {
      if (kDebugMode) {
        print('⚠️ VAPID 키가 설정되지 않았습니다. Firebase Console에서 발급받으세요.');
      }
    }
  } else {
    // 모바일: VAPID 키 불필요
    token = await messaging.getToken();
  }

  if (kDebugMode && token != null) {
    print('FCM Token: $token');
  }
}

/// 웹 FCM 토큰을 Firestore에 저장 (서버 측 토픽 구독용)
Future<void> _saveWebTokenToFirestore(String token) async {
  try {
    await FirebaseFirestore.instance
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'platform': 'web',
      'topics': ['jobs', 'houses'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (kDebugMode) {
      print('웹 FCM 토큰 저장 완료');
    }
  } catch (e) {
    if (kDebugMode) {
      print('웹 FCM 토큰 저장 실패: $e');
    }
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
          // 5060세대 고려: 전체 글씨 크기 확대 및 가독성 강화
          textTheme: const TextTheme(
            // 큰 제목 (상세 화면 제목)
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            // 중간 제목 (리스트 제목)
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            // 본문 (상세 내용)
            bodyLarge: TextStyle(fontSize: 20, height: 1.6),
            // 기본 텍스트
            bodyMedium: TextStyle(fontSize: 18),
            // 보조 텍스트 (날짜, 출처)
            bodySmall: TextStyle(fontSize: 16, color: Color(0xFF616161)),
            // 버튼/칩 라벨
            labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          // AppBar 테마
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
