---
name: work-feature
description: GitHub 이슈 번호를 받아 기능을 구현한다. enhancement 라벨 이슈에 적용
argument-hint: "[issue-number]"
user-invocable: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# 기능 구현

대상 이슈: #$ARGUMENTS

## 이슈 컨텍스트

!`gh issue view $ARGUMENTS 2>/dev/null || echo "이슈를 확인할 수 없습니다. 번호를 확인하세요."`

## 실행 순서

### 1. 분석
- 위 이슈의 요구사항을 파악한다
- 관련 코드의 기존 패턴과 컨벤션을 확인한다
- 변경이 다른 코드에 미치는 영향을 분석한다

### 2. 계획
- 구현 방향을 정리하여 사용자에게 확인받는다
- 도메인에 따라 적절한 agent(crawler-expert 또는 flutter-expert)를 활용한다

### 3. 구현
- 기존 패턴을 따라 최소한의 변경으로 구현한다
- 불필요한 추가 기능이나 리팩토링을 하지 않는다

### 4. 검증
- 빌드 성공을 확인한다
- 기존 기능이 훼손되지 않았는지 확인한다

### 5. 커밋
- 커밋 메시지에 반드시 `#$ARGUMENTS` 포함
- 이슈가 완전히 해결되면 `Closes #$ARGUMENTS` 포함
