# 풀 사이클 실행

이슈 번호 목록 (쉼표 구분): $ARGUMENTS

팀을 구성하여 이슈를 처리하는 전체 사이클을 실행한다.

## 사이클 순서

### Phase 1: 점검
qa-inspector agent로 프로젝트 현황 점검. 추가 이슈 발견 시 GitHub 이슈 등록.

### Phase 2: 작업
각 이슈를 도메인에 맞는 agent에게 할당:
- crawler/ 관련 → crawler-expert
- job_alrimi_app/, functions/ 관련 → flutter-expert
- 독립적인 이슈는 병렬 처리 (worktree 격리)
- 같은 파일 수정 이슈는 순차 처리

이슈별 워크플로우:
- bug 라벨 → work-bug 워크플로우 (TDD)
- enhancement 라벨 → work-feature 워크플로우

### Phase 3: 문서 최적화
doc-optimizer agent로 문서 동기화. 정확하되 최소한의 문서 유지.

### Phase 4: 최종 검증
qa-inspector agent로 완료 검증. 미해결 문제 있으면 새 이슈 등록.

## 규칙

- 모든 커밋에 `#이슈번호` 포함 필수
- 이슈 없는 작업 금지
- 작업 로그 기록 금지
