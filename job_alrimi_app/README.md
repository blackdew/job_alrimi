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
├── main.dart              # 앱 진입점
├── models/                # 데이터 모델
│   └── job_item.dart
├── providers/             # 상태 관리 (Provider)
│   ├── job_provider.dart
│   └── settings_provider.dart
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

1. **메인 리스트**: 일자리/빈집 정보 목록
2. **상세 화면**: Push to Call UI (대형 전화 버튼)
3. **설정**: 키워드 구독 및 알림 설정

## Firebase 설정

1. Firebase 콘솔에서 프로젝트 생성
2. `flutterfire configure` 실행
3. `firebase_options.dart` 생성됨
