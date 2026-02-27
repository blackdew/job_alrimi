# QA 점검 및 이슈 등록

qa-inspector agent를 사용하여 프로젝트 전체 품질을 점검한다.

## 점검 항목

### 크롤러
- `gh run list --workflow=crawler.yml --limit 5`로 최근 실행 상태 확인
- 크롤링 대상 사이트 접근 가능 여부 확인
- `crawler/` 코드에 하드코딩된 시크릿 탐지

### 앱 빌드
- `cd job_alrimi_app && flutter analyze` 실행하여 경고/에러 확인
- 웹 빌드: `flutter build web` 성공 여부

### Firebase
- `functions/` 코드 점검
- `firestore.rules` 보안 규칙 만료일 확인

### 코드 품질
- TODO/FIXME 잔존 현황 탐색
- 미사용 import, 데드코드 탐지

### 문서 정합성
- CLAUDE.md 프로젝트 구조가 실제와 일치하는지
- 열린 이슈 중 이미 해결된 것이 있는지

## 이슈 등록 규칙

발견된 문제마다:
1. 기존 열린 이슈와 중복 여부 먼저 확인 (`gh issue list`)
2. 중복 아니면 `gh issue create --title "[영역] 문제 요약" --body "상세" --label "라벨"`
3. 중복이면 기존 이슈에 코멘트 추가

## 결과 보고

점검 완료 후 요약:
- 통과/실패 항목 수
- 새로 생성한 이슈 번호 목록
- 긴급도 판단
