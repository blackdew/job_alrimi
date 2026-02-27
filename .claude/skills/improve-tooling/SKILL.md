---
name: improve-tooling
description: 에이전트, 스킬, 설정을 점검하고 개선한다. 작업 경험 기반으로 자기 개선
user-invocable: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# 에이전트/스킬 자기 개선

tooling-expert agent로 현재 구성을 점검하고 개선한다.

## 점검 대상

- `.claude/agents/*.md` ↔ 실제 프로젝트 구조
- `.claude/skills/*/SKILL.md` ↔ 실행 가능성
- `.claude/settings.json` ↔ 파일 타입 커버리지
- `CLAUDE.md` ↔ 에이전트/스킬 목록 일치

## 실행 순서

### 1. 현황 수집

- 모든 agent/skill 파일 읽기
- 실제 프로젝트 구조와 비교
- 최근 작업 이력(git log)에서 문제 패턴 확인

### 2. 불일치 보고

- 에이전트 정의 vs 실제 코드 구조
- 스킬에서 참조하는 명령어/agent 존재 여부
- CLAUDE.md 표 vs 실제 파일

### 3. 개선안 제시

- 구체적인 수정 내용을 사용자에게 제시
- 사용자 승인 후 적용

### 4. CLAUDE.md 동기화

- 변경된 에이전트/스킬 목록 반영
