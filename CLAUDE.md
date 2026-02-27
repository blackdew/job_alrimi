# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

남해군 주민 및 예비 이주민을 위한 일자리·빈집 정보 알림 앱. 핵심 가치는 **"알림(Push) 받고 → 전화(Call) 거는"** 직관적 프로세스.

### 프로젝트 목표

- 크롤러가 1시간 주기로 안정적으로 데이터를 수집
- 푸시 알림이 Android/iOS/Web 전 플랫폼에서 정상 수신
- 앱이 Google Play, App Store, Firebase Hosting에 배포
- 5060세대가 불편 없이 사용할 수 있는 접근성

## 세션 시작 시 현황 파악 방법

새 세션이나 초기화 후에는 아래 명령으로 프로젝트 현황을 파악한다.

```bash
# 1. 열린 이슈 확인 (할 일 목록)
gh issue list --state open

# 2. 최근 작업 이력
git log --oneline -10

# 3. 크롤러 CI 상태 (정상 동작 여부)
gh run list --workflow=crawler.yml --limit 5

# 4. 앱 빌드 상태
cd job_alrimi_app && flutter analyze

# 5. 브랜치 및 미커밋 변경사항
git status && git branch -a
```

열린 이슈 목록이 곧 현재 할 일 목록이다. 이슈의 라벨(`bug`, `enhancement`)과 의존 관계(이슈 본문에 명시)를 보고 작업 순서를 판단한다.

## Agent 팀 구성

`.claude/agents/`에 4개의 전문 Agent가 정의되어 있다.

| Agent | 역할 | 코드 수정 | 격리 |
|-------|------|:---------:|:----:|
| **crawler-expert** | 크롤러/CI 버그 수정 및 유지보수 | O | worktree |
| **flutter-expert** | Flutter 앱/웹 개발 및 Firebase 연동 | O | worktree |
| **qa-inspector** | 품질 점검 + 문제 발견 시 GitHub 이슈 등록 | **X** | - |
| **doc-optimizer** | 문서 동기화 (정확하되 최소화) | 문서만 | - |

이슈 도메인에 따라 적절한 Agent를 선택한다:
- `crawler/`, `.github/workflows/` 관련 → **crawler-expert**
- `job_alrimi_app/`, `functions/` 관련 → **flutter-expert**

## 워크플로우 Skill

`.claude/skills/`에 5개의 워크플로우 Skill이 정의되어 있다.

| Skill | 용도 | 호출 |
|-------|------|------|
| **work-bug** | TDD 버그 수정 (Red-Green-Refactor) | `/work-bug {이슈번호}` |
| **work-feature** | 기능 구현 (분석-계획-구현-검증) | `/work-feature {이슈번호}` |
| **qa-inspect** | 전체 품질 점검 → 이슈 등록 | `/qa-inspect` |
| **doc-optimize** | 문서 최적화 (현재 상태 동기화) | `/doc-optimize` |
| **full-cycle** | 점검→작업→문서→검증 전체 사이클 | `/full-cycle {이슈번호들}` |

### 표준 작업 사이클

```
/qa-inspect → /work-bug 또는 /work-feature → /doc-optimize → /qa-inspect
```

## 작업 규칙

1. **이슈 기반 커밋**: 모든 커밋 메시지에 `#이슈번호` 포함. 이슈가 없으면 `gh issue create`로 먼저 생성
2. **문서 최적화**: 작업 후 `/doc-optimize`로 문서 동기화. 정확하되 최소화. 작업 로그 기록 금지
3. **QA → 이슈 등록**: `/qa-inspect`로 점검 후 문제를 GitHub 이슈로 등록. qa-inspector는 코드를 수정하지 않음

## 아키텍처 (Monorepo)

```
job_alrimi/
├── .github/workflows/    # GitHub Actions CI/CD
│   └── crawler.yml       # 크롤러 자동화 (1시간 주기)
├── .claude/
│   ├── agents/           # 커스텀 Agent 정의 (4종)
│   ├── skills/           # 워크플로우 Skill 정의 (5종)
│   └── settings.json     # PostToolUse 훅 (dart analyze, node --check)
├── crawler/              # Node.js 크롤러 (Playwright + cheerio)
│   └── src/
│       ├── crawlers/     # 사이트별 크롤러 (jobs.js, houses.js)
│       └── utils/        # 파서, Firebase 유틸
├── job_alrimi_app/       # Flutter 앱 (Android/iOS/Web)
│   └── lib/
│       ├── models/       # 데이터 모델
│       ├── providers/    # 상태 관리 (Provider + SharedPreferences)
│       ├── repositories/ # 데이터 접근 계층
│       ├── screens/      # 화면
│       ├── theme/        # 색상 시스템 (AppColors)
│       └── widgets/      # 재사용 위젯
├── functions/            # Firebase Cloud Functions (푸시 트리거)
└── docs/                 # PRD, 구현 계획서
```

### 데이터 흐름
```
크롤링(1시간 주기) → Firestore 저장 → Cloud Functions 트리거 → FCM 푸시 알림 → 앱 확인 → 전화 걸기
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| 크롤러 | Node.js (ESM), Playwright, cheerio, dotenv |
| 데이터베이스 | Firebase Firestore |
| 앱 | Flutter, Provider (상태관리), SharedPreferences (설정 저장) |
| 푸시 | Firebase Cloud Messaging (FCM), VAPID (웹) |
| 서버리스 | Firebase Cloud Functions (v2) |
| CI/CD | GitHub Actions |

## 개발 명령어

```bash
# 크롤러
cd crawler && npm install
npm run dev              # 크롤링 실행
npm run crawl:jobs       # 일자리만 크롤링
npm run crawl:houses     # 빈집만 크롤링

# Flutter 앱
cd job_alrimi_app && flutter pub get
flutter analyze          # 정적 분석
flutter run              # 개발 실행
flutter build apk        # Android 빌드
flutter build web        # Web 빌드

# Firebase Functions
cd functions && npm install
npm run serve            # 로컬 에뮬레이터
npm run deploy           # 배포
```

## 크롤링 대상 사이트

### 일자리
- 남해군청 새올: `https://www.namhae.go.kr/modules/saeol/gosi.do`
- 남해군청 구인구직: `https://www.namhae.go.kr/portal/board/List.do`
- 경남 워크넷: `https://gyeongnam.work.go.kr/namhae/main.do`

### 빈집
- 남해군청 빈집정보: `https://www.namhae.go.kr/depart/Index.do?c=DE0201060000`
- 그린대로: `https://www.greendaero.go.kr` (API: `/svc/rfph/cpif/getVacantHomePagingList.do`)

## UI/UX 원칙

- **타겟 사용자**: 5060세대 고려하여 큰 글씨, 단순한 UI
- **2 Depth 이하**: 앱 실행 → 리스트 → 상세(전화걸기)
- **Push to Call**: 상세 화면에 대형 '전화 걸기' 버튼 필수
- **WCAG AA**: 색상 대비 4.5:1 이상, 최소 터치 영역 48dp

## 환경 설정

크롤러 실행 전 `crawler/.env` 파일 필요:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```
