# Job Alrimi App

남해군 일자리·빈집 정보 알림 Flutter 앱

## 설치

Flutter SDK 설치 후:

```bash
flutter pub get
flutter run
```

## 아키텍처

```
lib/
├── main.dart              # 앱 진입점, FCM 초기화 및 딥링크 처리
├── firebase_options.dart  # Firebase 설정 (자동 생성)
├── models/                # 데이터 모델
│   └── job_item.dart
├── providers/             # 상태 관리 (Provider)
│   ├── job_provider.dart       # 일자리/빈집 데이터 관리
│   └── settings_provider.dart  # 설정 상태 관리 (FCM 토픽, SharedPreferences)
├── repositories/          # 데이터 접근 계층
│   └── job_repository.dart
├── screens/               # 화면
│   ├── home_screen.dart
│   ├── detail_screen.dart
│   └── settings_screen.dart
└── widgets/               # 재사용 위젯
    └── job_list_tile.dart
```

## 주요 기능

1. **메인 리스트**: 일자리/빈집 정보 목록 (Firestore 실시간 연동)
2. **상세 화면**: Push to Call UI (대형 전화 버튼)
3. **설정**: 키워드 구독 및 알림 설정 (SharedPreferences 영속화)
4. **FCM 푸시 알림**: 백그라운드/종료 상태에서도 알림 수신
5. **딥링크**: 알림 클릭 시 해당 아이템 상세 화면으로 이동

## Firebase 설정

1. Firebase 콘솔에서 프로젝트 생성
2. `flutterfire configure` 실행
3. `firebase_options.dart` 생성됨

## 사용 라이브러리

- **provider**: 상태 관리
- **firebase_core**: Firebase 초기화
- **firebase_messaging**: FCM 푸시 알림
- **cloud_firestore**: Firestore 데이터베이스 연동
- **url_launcher**: 전화 걸기 기능
- **shared_preferences**: 설정 영속화
- **intl**: 날짜 포맷팅
