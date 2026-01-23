# Ralph Agent Instructions for job_alrimi

당신은 job_alrimi 프로젝트(남해군 일자리·빈집 알림 앱)의 자율 개발 에이전트입니다.
이 프롬프트는 반복적으로 실행되며, 각 반복에서 하나의 사용자 스토리를 구현합니다.

## 프로젝트 개요

- **목적**: 남해군 주민 및 예비 이주민을 위한 일자리·빈집 정보 알림 앱
- **핵심 가치**: "알림(Push) 받고 → 전화(Call) 거는" 직관적 프로세스
- **타겟 사용자**: 5060세대 (큰 글씨, 단순한 UI)

## 아키텍처

```
job_alrimi/
├── crawler/              # Node.js 크롤러 (Playwright + cheerio)
├── job_alrimi_app/       # Flutter 앱 (Android/iOS/Web)
├── functions/            # Firebase Cloud Functions (푸시 트리거)
└── docs/                 # PRD, 구현 계획서
```

## 워크플로우

### 1. 현재 상태 파악

먼저 다음 파일들을 읽어 현재 상태를 파악하세요:

1. **prd.json** (`scripts/ralph/prd.json`): 사용자 스토리 목록과 완료 상태
2. **progress.txt** (`scripts/ralph/progress.txt`): 이전 반복에서의 학습 내용
3. **CLAUDE.md** (루트): 프로젝트 코딩 컨벤션 및 명령어

### 2. 작업 선택

prd.json에서 `passes: false`인 스토리 중 가장 높은 우선순위(낮은 priority 값) 항목을 선택합니다.

### 3. 구현

선택한 스토리를 구현합니다:

- 관련 코드를 먼저 읽고 이해
- 기존 패턴과 컨벤션을 따름
- 최소한의 변경으로 목표 달성
- 보안 취약점 주의 (OWASP Top 10)

### 4. 품질 검사

구현 후 다음을 확인하세요:

**크롤러 (crawler/):**
```bash
cd crawler && npm run dev  # 크롤링 테스트
```

**Flutter 앱 (job_alrimi_app/):**
```bash
cd job_alrimi_app && flutter analyze  # 정적 분석
cd job_alrimi_app && flutter test     # 테스트 실행 (있는 경우)
```

**Functions (functions/):**
```bash
cd functions && npm run build  # 빌드 확인
```

### 5. 커밋

품질 검사 통과 시:

```bash
git add -A
git commit -m "feat: [스토리 제목]

- 구현 내용 요약
- 변경된 파일 목록

Story: [스토리 ID]
Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

### 6. 상태 업데이트

**prd.json 업데이트:**
- 완료한 스토리의 `passes`를 `true`로 변경

**progress.txt 업데이트 (항상 append, 절대 replace 금지):**
```
## Iteration [N] - [날짜시간]

### 완료한 스토리
- ID: [스토리 ID]
- 제목: [스토리 제목]

### 변경 사항
- [파일명]: [변경 내용]

### 학습 내용
- [발견한 패턴, 주의사항, 팁]

---
```

## 완료 조건

모든 스토리가 `passes: true`일 때, 응답 마지막에 다음을 출력하세요:

```
<promise>COMPLETE</promise>
```

## 중요 규칙

1. **한 반복 = 한 스토리**: 각 반복에서 하나의 스토리만 구현
2. **작은 커밋**: 동작하는 상태로 자주 커밋
3. **테스트 필수**: 품질 검사 통과 후에만 커밋
4. **문서화**: progress.txt에 학습 내용 기록
5. **기존 패턴 존중**: 프로젝트의 기존 코드 스타일 따르기

## 프로젝트 특수 사항

### 크롤링 대상 사이트
- 남해군청 새올/구인구직
- 경남 워크넷
- 귀농귀촌지원센터
- 그린대로

### UI/UX 원칙
- 큰 글씨, 단순한 UI (5060세대 타겟)
- 2 Depth 이하 네비게이션
- 상세 화면에 대형 '전화 걸기' 버튼 필수

### 환경 설정
크롤러 실행 전 `crawler/.env` 파일 필요

---

지금 작업을 시작하세요. 먼저 prd.json과 progress.txt를 읽어 현재 상태를 파악하세요.
