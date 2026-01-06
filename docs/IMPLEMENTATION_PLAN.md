# 크롤링 및 POC 구축 계획 (Implementation Plan)

> [!NOTE]
> 본 문서는 '남해군 일자리·빈집 정보 알림 앱'의 핵심 가치인 **"빠른 정보 확인(Push)"**과 **"즉시 연결(Call)"**을 검증하기 위한 기술적 실행 계획입니다.

## 1. 크롤링 전략 (Data Acquisition Strategy)

### 1.1 대상 사이트
*   **남해군청 구인/구직 게시판**:
    1.  `https://www.namhae.go.kr/modules/saeol/gosi.do?&pageCd=SM010110000&siteGubun=socialm`
    2.  `https://www.namhae.go.kr/portal/board/List.do?gcode=1617&&pageCd=WW0201022000&siteGubun=portal`
    3.  `https://gyeongnam.work.go.kr/namhae/main.do`
    *   일자리 정보 (제목, 작성일, 연락처, 본문 등)
*   **남해군 빈집 정보 (귀농귀촌지원센터)**: `http://refarm.namhae.go.kr` 및 `https://greendaero.go.kr` (남해군 필터)
    *   빈집 매매/임대 정보 (구체적인 게시판 URL은 크롤러 개발 단계에서 `refarm.namhae.go.kr` 내부 탐색 확정)

### 1.2 기술 스택 (Tech Stack)
*   **Env**: **Node.js** (비동기 처리 특화)
*   **Libraries**: **Playwright** (Headless Browser), `cheerio` (HTML 파싱 보조).
    *   *선정이유*: 대상 사이트가 API를 제공하지 않고, 동적 렌더링(JS) 가능성이 있어 브라우저 자동화 도구 필수.
*   **Data Storage**: **Firebase Firestore**
    *   NoSQL 구조로 유연한 데이터 저장.
    *   모바일 앱(Client)과의 실시간 동기화 용이.

### 1.3 데이터 처리 프로세스
1.  **수집 (Collect)**: 주기적(예: 30분 간격)으로 게시판 1페이지 스캔.
2.  **필터링 (Dedup)**: 기존 저장된 게시물 ID와 비교하여 **신규 게시물**만 식별.
3.  **가공 (Parse)**: 제목, 상세 내용에서 **전화번호** 추출(RegEx), 키워드(사무직, 밭일, 촌집 등) 태깅.
4.  **저장 (Store)**: Firestore에 문서 생성.
5.  **트리거 (Trigger)**: 신규 문서 생성 시 Firebase Cloud Functions가 푸시 알림 로직 실행.

---

## 2. POC 프로토타입 개발 (Prototype Development)

### 2.1 목표 (Goal)
*   MVP 단계 전, **"크롤링 → 푸시 알림 → 앱 확인 → 전화 걸기"**의 핵심 루프(Loop)가 기술적으로 매끄러운지 검증.
*   최소한의 UI로 기능 구현에 집중.

### 2.2 기술 스택
*   **Framework**: **Flutter** (Android/iOS **+ Web** 동시 대응)
    *   단일 코드베이스로 앱과 웹(PWA) 배포 가능.
*   **Backend**: **Firebase** (Auth, Firestore, Messaging/FCM, Functions)

### 2.3 핵심 기능 범위 (Scope)
1.  **사용자 설정 (Preferences)**
    *   단순 키워드 구독 (예: 체크박스 - [ ] 일자리, [ ] 빈집).
2.  **메인 리스트 (Feed)**
    *   크롤링된 최신 정보 리스트 형태 노출.
    *   읽음/안읽음 구분.
3.  **상세 화면 (Detail)**
    *   제목, 본문, 날짜 표시.
    *   **Floating Action Button (FAB)** 또는 하단 고정 바에 거대한 **"전화 걸기"** 버튼. 클릭 시 다이얼러로 이동.
4.  **백그라운드 알림**
    *   앱 종료 상태에서도 FCM(Firebase Cloud Messaging) 수신 확인.
    *   *Web 참고*: 상세 페이지 URL 공유 및 PC/모바일 웹 뷰어 기능 제공 (전화 걸기는 모바일 웹에서만 동작).

---

## 3. 검증 시나리오 (Verification Plan)

### 3.1 크롤링 정확성
*   [ ] 남해군청 사이트에 새 글 등록 시 10분 이내에 Firestore에 저장되는가?
*   [ ] 본문 내 전화번호가 없을 경우 예외 처리가 적절한가? (대표 번호 안내 등)

### 3.2 알림 속도 및 연결
*   [ ] 데이터 저장 후 사용자 기기에 푸시 알림이 5초 이내 도착하는가?
*   [ ] 알림 클릭 시 해당 상세 페이지로 딥링크(Deep Link) 연결되는가?
*   [ ] 상세 페이지에서 전화 버튼 클릭 시 다이얼 화면에 번호가 자동 입력되는가?

---

## 4. 실행 일정 (Action Items)
1.  **[Backend]** Node.js + Playwright 크롤러 작성 및 로컬 테스트 (남해군청 사이트 구조 분석).
2.  **[DB]** Firestore 스키마 설계 및 크롤러 연동.
3.  **[App]** Flutter 프로젝트 생성 및 Firebase 설정.
4.  **[App]** UI 구현 (리스트/상세) 및 FCM 연동.

---

## 5. 프로젝트 구조 (Project Structure)
**Monorepo** 방식을 채택하여 프로젝트를 통합 관리합니다.
```
/job_alrimi
├── /crawler             # Node.js + Playwright 크롤러
│   ├── .env             # 환경 변수 (Git 제외)
│   ├── src/             # 크롤링 로직 (.ts/.js)
│   └── package.json
├── /job_alrimi_app      # Flutter 모바일/웹 앱
│   ├── lib/             # Dart 소스 코드
│   └── pubspec.yaml
├── firebase.json        # Firebase 설정
└── .gitignore
```
