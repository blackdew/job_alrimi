# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

남해군 주민 및 예비 이주민을 위한 일자리·빈집 정보 알림 앱. 핵심 가치는 **"알림(Push) 받고 → 전화(Call) 거는"** 직관적 프로세스.

## 아키텍처

```
job_alrimi/
├── crawler/          # Node.js 크롤러 (Playwright + cheerio)
├── app/              # Flutter 앱 (Android/iOS/Web)
├── functions/        # Firebase Cloud Functions (푸시 알림 트리거)
└── docs/             # PRD, 구현 계획서
```

### 데이터 흐름
```
크롤링(30분 주기) → Firestore 저장 → Cloud Functions 트리거 → FCM 푸시 알림 → 앱에서 확인 → 전화 걸기
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| 크롤러 | Node.js, Playwright, cheerio |
| 데이터베이스 | Firebase Firestore |
| 앱 | Flutter |
| 푸시 | Firebase Cloud Messaging (FCM) |
| 서버리스 | Firebase Cloud Functions |

## 크롤링 대상 사이트

### 일자리
- 남해군청 새올: `https://www.namhae.go.kr/modules/saeol/gosi.do`
- 남해군청 구인구직: `https://www.namhae.go.kr/portal/board/List.do`
- 경남 워크넷: `https://gyeongnam.work.go.kr/namhae/main.do`

### 빈집
- 귀농귀촌지원센터: `http://refarm.namhae.go.kr`
- 그린대로: `https://greendaero.go.kr`

## UI/UX 원칙

- **타겟 사용자**: 5060세대 고려하여 큰 글씨, 단순한 UI
- **2 Depth 이하**: 앱 실행 → 리스트 → 상세(전화걸기)
- **Push to Call**: 상세 화면에 대형 '전화 걸기' 버튼 필수

## 개발 명령어 (예정)

```bash
# 크롤러
cd crawler && npm install
npm run dev          # 로컬 테스트
npm run crawl        # 수동 크롤링 실행

# Flutter 앱
cd app && flutter pub get
flutter run          # 개발 실행
flutter build apk    # Android 빌드
flutter build ios    # iOS 빌드

# Firebase Functions
cd functions && npm install
firebase emulators:start   # 로컬 에뮬레이터
firebase deploy --only functions
```
