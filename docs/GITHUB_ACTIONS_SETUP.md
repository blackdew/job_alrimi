# GitHub Actions 크롤러 자동화 설정 가이드

이 문서는 GitHub Actions를 통해 크롤러를 자동으로 실행하기 위한 설정 방법을 안내합니다.

## 개요

- **실행 주기**: 매 30분마다 자동 실행
- **수동 실행**: GitHub Actions 탭에서 수동 트리거 가능
- **실패 알림**: 크롤러 실패 시 자동으로 GitHub Issue 생성

## 사전 준비

### 1. Firebase 서비스 계정 키 다운로드

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 → 프로젝트 설정 → 서비스 계정 탭
3. **"새 비공개 키 생성"** 클릭
4. JSON 파일 다운로드 (예: `job-alrimi-firebase-adminsdk-xxxxx.json`)

### 2. Base64 인코딩

다운로드한 JSON 파일을 Base64로 인코딩합니다.

**macOS/Linux:**
```bash
base64 -i job-alrimi-firebase-adminsdk-xxxxx.json | tr -d '\n'
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("job-alrimi-firebase-adminsdk-xxxxx.json"))
```

출력된 긴 문자열을 복사해 둡니다.

### 3. GitHub Repository Secret 설정

1. GitHub 저장소 페이지 → **Settings** 탭
2. 좌측 메뉴에서 **Secrets and variables** → **Actions**
3. **"New repository secret"** 클릭
4. 다음 정보 입력:
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Secret**: 2단계에서 복사한 Base64 인코딩 문자열
5. **"Add secret"** 클릭

## 워크플로우 구성

### 파일 위치
```
.github/workflows/crawler.yml
```

### 주요 기능

| 기능 | 설명 |
|------|------|
| 스케줄 실행 | 매 30분마다 자동 실행 (`*/30 * * * *`) |
| 수동 실행 | workflow_dispatch로 수동 트리거 |
| 크롤링 타입 선택 | all / jobs / houses 선택 가능 |
| 실패 알림 | 실패 시 자동으로 GitHub Issue 생성 |

### 실행 흐름

```
1. Checkout → 코드 가져오기
2. Node.js 설정 → v20 설치
3. npm ci → 의존성 설치
4. Playwright 설치 → chromium 브라우저
5. Firebase 설정 → Secret에서 환경변수 추출
6. 크롤러 실행 → npm run crawl
7. (실패 시) Issue 생성 → crawler-failure 라벨
```

## 수동 실행 방법

1. GitHub 저장소 → **Actions** 탭
2. 좌측에서 **"Crawler Automation"** 워크플로우 선택
3. **"Run workflow"** 버튼 클릭
4. 크롤링 타입 선택 (선택사항)
   - `all`: 전체 크롤링 (기본값)
   - `jobs`: 일자리만
   - `houses`: 빈집만
5. **"Run workflow"** 클릭

## 실행 로그 확인

1. **Actions** 탭 → 해당 워크플로우 실행 클릭
2. **"crawl"** job 클릭
3. 각 step의 로그 확인 가능

## 문제 해결

### Secret이 설정되지 않은 경우
```
Error: FIREBASE_SERVICE_ACCOUNT secret is not set
```
→ Repository Secret 설정 확인

### Base64 디코딩 실패
```
Error: Invalid base64 string
```
→ 인코딩 시 개행문자가 포함되지 않았는지 확인 (`tr -d '\n'` 사용)

### Playwright 브라우저 설치 실패
```
Error: browserType.launch: Executable doesn't exist
```
→ `npx playwright install chromium --with-deps` 명령이 실행되었는지 확인

### 크롤링 대상 사이트 접근 불가
```
Error: net::ERR_CONNECTION_REFUSED
```
→ 해당 사이트의 접근 가능 여부 확인 (일시적 장애 가능성)

## 보안 주의사항

- ⚠️ Firebase 서비스 계정 JSON 파일을 저장소에 직접 커밋하지 마세요
- ⚠️ Secret은 한 번 설정하면 다시 볼 수 없습니다 (필요시 재생성)
- ⚠️ 서비스 계정 키가 노출된 경우 즉시 Firebase Console에서 키를 삭제하고 새로 생성하세요

## 관련 파일

- `.github/workflows/crawler.yml` - 워크플로우 정의
- `crawler/src/index.js` - 크롤러 메인 진입점
- `crawler/package.json` - npm 스크립트 정의
