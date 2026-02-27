---
name: full-cycle
description: QA점검 → 이슈작업 → 문서최적화 → 최종검증 전체 사이클을 실행한다. 여러 이슈를 쉼표로 전달
argument-hint: "[issue-numbers (comma separated)]"
user-invocable: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# 풀 사이클

대상 이슈: $ARGUMENTS

## Phase 1: 점검

qa-inspector agent로 프로젝트 현황 점검. 추가 이슈 발견 시 GitHub 이슈 등록.

## Phase 2: 작업

각 이슈를 도메인에 맞는 agent에게 할당:
- `crawler/` 관련 → crawler-expert agent
- `job_alrimi_app/`, `functions/` 관련 → flutter-expert agent
- 독립 이슈는 병렬 처리 (worktree 격리)
- 같은 파일 수정 이슈는 순차 처리

이슈별 워크플로우:
- bug 라벨 → TDD (Red-Green-Refactor)
- enhancement 라벨 → 분석-계획-구현-검증

## Phase 3: 문서 최적화

doc-optimizer agent로 문서 동기화. 정확하되 최소 문서 유지. 작업 로그 금지.

## Phase 4: 최종 검증

qa-inspector agent로 완료 검증. 미해결 문제는 새 이슈 등록.

## 규칙

- 모든 커밋에 `#이슈번호` 포함 필수
- 이슈 없는 작업 금지
- 작업 로그 기록 금지
