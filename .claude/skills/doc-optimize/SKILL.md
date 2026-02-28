---
name: doc-optimize
description: 프로젝트 문서를 현재 코드 상태에 동기화한다. 정확하되 문서 수와 양을 최소화하고 작업 로그는 기록하지 않는다
user-invocable: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
context: fork
agent: doc-optimizer
---

# 문서 최적화

doc-optimizer agent로 문서를 현재 상태에 동기화한다.

## 현재 문서 현황

- CLAUDE.md: !`wc -l CLAUDE.md 2>/dev/null || echo "없음"`줄
- docs 디렉토리: !`find docs/ -name "*.md" -type f 2>/dev/null | sort || echo "없음"`

## 동기화 대상

1. `CLAUDE.md`: 프로젝트 구조, 기술 스택, 개발 명령어
2. `README.md`: 프로젝트 소개, 구조, 기술 스택, 개발 상태
3. `docs/` 내 문서: 불필요하면 통합 또는 삭제 제안

## 원칙

- **정확성**: 코드와 문서 불일치 즉시 수정
- **최소화**: 문서 수와 양을 최소로. 중복 제거
- **작업 로그 금지**: git log가 이력. 문서는 현재 상태만
- **이슈 기반 커밋**: 문서 변경도 `#이슈번호` 포함
