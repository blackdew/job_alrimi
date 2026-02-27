---
name: qa-inspect
description: 프로젝트 전체 품질을 점검하고 발견된 문제를 GitHub 이슈로 등록한다. 코드를 수정하지 않는다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
context: fork
agent: qa-inspector
---

# QA 점검 및 이슈 등록

qa-inspector agent로 프로젝트 전체를 점검한다.

## 현재 상태

- 열린 이슈: !`gh issue list --state open --limit 10 2>/dev/null || echo "확인 불가"`
- 최근 CI: !`gh run list --limit 5 2>/dev/null || echo "확인 불가"`

## 점검 항목

### 크롤러
- `gh run list --workflow=crawler.yml --limit 5`로 최근 실행 상태
- 크롤링 대상 사이트 접근 가능 여부
- `crawler/` 코드에 하드코딩된 시크릿 탐지

### 앱 빌드
- `cd job_alrimi_app && flutter analyze`
- `cd job_alrimi_app && flutter build web`

### Firebase
- `functions/` 코드 점검
- `firestore.rules` 보안 규칙 만료일

### 코드 품질
- TODO/FIXME 잔존 현황
- 미사용 import, 데드코드

### 문서 정합성
- CLAUDE.md와 실제 프로젝트 구조 일치 여부
- 열린 이슈 중 이미 해결된 것이 있는지

## 이슈 등록

발견된 문제마다:
1. 기존 열린 이슈와 중복 확인
2. 중복 아니면 `gh issue create`
3. 중복이면 기존 이슈에 코멘트

## 결과

점검 완료 후 요약 보고: 통과/실패, 새 이슈 목록, 긴급도 판단
