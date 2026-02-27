---
name: work-bug
description: GitHub 이슈 번호를 받아 TDD 방식(Red-Green-Refactor)으로 버그를 수정한다. bug 라벨 이슈에 자동 적용
argument-hint: "[issue-number]"
user-invocable: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# 버그 수정 (TDD)

대상 이슈: #$ARGUMENTS

## 이슈 컨텍스트

!`gh issue view $ARGUMENTS 2>/dev/null || echo "이슈를 확인할 수 없습니다. 번호를 확인하세요."`

## 실행 순서

### 1. 분석
- 위 이슈 내용을 파악하고 관련 코드를 읽는다
- `git log`와 `git blame`으로 변경 이력을 확인한다
- 도메인에 따라 적절한 agent(crawler-expert 또는 flutter-expert)를 활용한다

### 2. RED - 실패 테스트 작성
- 버그를 재현하는 테스트를 작성한다
- 테스트가 실패하는 것을 확인한다
- 테스트 인프라가 없으면 수동 검증 계획을 명시한다

### 3. GREEN - 최소 수정
- 테스트를 통과시키는 최소한의 코드만 수정한다
- 관련 없는 코드는 건드리지 않는다

### 4. REFACTOR - 정리
- 기존 테스트 전체 통과를 확인한다
- 필요시 코드를 정리한다

### 5. 검증
- 실제 빌드/실행으로 동작을 확인한다
- 수정 범위와 영향을 정리한다

### 6. 커밋
- 커밋 메시지에 반드시 `#$ARGUMENTS` 포함
- 이슈가 완전히 해결되면 커밋 메시지에 `Closes #$ARGUMENTS` 포함
