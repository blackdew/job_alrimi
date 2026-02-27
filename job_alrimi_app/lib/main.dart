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
import 'theme/app_colors.dart';

/// 딥링크 네비게이션을 위한 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
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
    debugPrint('FCM 권한 상태: ${settings.authorizationStatus}');
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
        debugPrint('⚠️ VAPID 키가 설정되지 않았습니다. Firebase Console에서 발급받으세요.');
      }
    }
  } else {
    // 모바일: VAPID 키 불필요
    token = await messaging.getToken();
  }

  if (kDebugMode && token != null) {
    debugPrint('FCM Token: $token');
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
      debugPrint('웹 FCM 토큰 저장 완료');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('웹 FCM 토큰 저장 실패: $e');
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
    // Foreground 메시지 처리 - 인앱 알림 표시
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Foreground message received: ${message.notification?.title}');
      }

      final messenger = navigatorKey.currentContext != null
          ? ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
          : null;
      if (messenger == null) return;

      final title = message.notification?.title ?? '새 알림';
      final body = message.notification?.body ?? '';
      final itemId = message.data['itemId'];
      final type = message.data['type'];

      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 14)),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: (itemId != null && type != null)
              ? SnackBarAction(
                  label: '보기',
                  onPressed: () => _navigateToDetail(itemId, type),
                )
              : null,
        ),
      );
    });

    // Background 상태에서 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Message opened app: ${message.notification?.title}');
      }
      _handleMessage(message);
    });
  }

  /// FCM 메시지 데이터에서 딥링크 처리
  Future<void> _handleMessage(RemoteMessage message) async {
    final itemId = message.data['itemId'];
    final type = message.data['type'];

    if (kDebugMode) {
      debugPrint('Handle message - itemId: $itemId, type: $type');
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
          debugPrint('Document not found: $collection/$itemId');
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
        debugPrint('Error navigating to detail: $e');
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
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.primaryContainer,
            secondary: AppColors.jobColor,
            tertiary: AppColors.houseColor,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            outline: AppColors.divider,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          // 5060세대 고려: 전체 글씨 크기 확대 및 가독성 강화
          textTheme: const TextTheme(
            // 큰 제목 (상세 화면 제목)
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            // 중간 제목 (리스트 제목)
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            // 본문 (상세 내용)
            bodyLarge: TextStyle(fontSize: 20, height: 1.6, color: AppColors.textPrimary),
            // 기본 텍스트
            bodyMedium: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            // 보조 텍스트 (날짜, 출처)
            bodySmall: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            // 버튼/칩 라벨
            labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          // AppBar 테마
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
          // 칩 테마
          chipTheme: ChipThemeData(
            selectedColor: AppColors.primary,
            labelStyle: const TextStyle(fontSize: 18),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          dividerTheme: const DividerThemeData(color: AppColors.divider),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
