/**
 * crawler.js 유틸리티 테스트
 * TDD - 이슈 #29: networkidle 타임아웃 버그 검증
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { delay, withRetry, safeGoto, parseDate, generateId } from './crawler.js';

describe('safeGoto', () => {
  it('기본 waitUntil은 domcontentloaded여야 한다 (networkidle은 타임아웃 위험)', () => {
    // safeGoto 소스를 직접 검사하는 방식 대신
    // 실제 동작을 테스트: mock page로 호출했을 때 전달된 옵션 확인
    const calls = [];
    const mockPage = {
      goto: async (url, options) => {
        calls.push({ url, options });
      },
    };

    // 기본 옵션으로 호출
    return safeGoto(mockPage, 'https://example.com').then(() => {
      assert.equal(calls.length, 1);
      // 기본값이 domcontentloaded여야 함 (networkidle 아님)
      assert.equal(
        calls[0].options.waitUntil,
        'domcontentloaded',
        `기본 waitUntil이 '${calls[0].options.waitUntil}'이지만 'domcontentloaded'여야 합니다. networkidle은 남해군청 사이트에서 30초 타임아웃을 유발합니다.`
      );
    });
  });

  it('timeout 기본값은 60000ms(60초) 이상이어야 한다', () => {
    const calls = [];
    const mockPage = {
      goto: async (url, options) => {
        calls.push({ url, options });
      },
    };

    return safeGoto(mockPage, 'https://example.com').then(() => {
      assert.ok(
        calls[0].options.timeout >= 60000,
        `기본 timeout이 ${calls[0].options.timeout}ms이지만 60000ms 이상이어야 합니다.`
      );
    });
  });
});

describe('withRetry', () => {
  it('성공 시 결과를 반환한다', async () => {
    const result = await withRetry(() => Promise.resolve(42));
    assert.equal(result, 42);
  });

  it('실패 후 재시도하여 성공하면 결과를 반환한다', async () => {
    let attempt = 0;
    const result = await withRetry(
      () => {
        attempt++;
        if (attempt < 2) throw new Error('일시적 오류');
        return Promise.resolve('성공');
      },
      { retries: 2, delayMs: 10, name: '테스트' }
    );
    assert.equal(result, '성공');
    assert.equal(attempt, 2);
  });

  it('모든 재시도 실패 시 마지막 오류를 throw한다', async () => {
    await assert.rejects(
      withRetry(() => Promise.reject(new Error('계속 실패')), { retries: 2, delayMs: 10 }),
      { message: '계속 실패' }
    );
  });
});

describe('parseDate', () => {
  it('YYYY-MM-DD 형식을 파싱한다', () => {
    assert.equal(parseDate('2024-01-15'), '2024-01-15');
  });

  it('YYYY.MM.DD 형식을 파싱한다', () => {
    assert.equal(parseDate('2024.01.15'), '2024-01-15');
  });

  it('null 입력 시 null을 반환한다', () => {
    assert.equal(parseDate(null), null);
  });

  it('빈 문자열 입력 시 null을 반환한다', () => {
    assert.equal(parseDate(''), null);
  });
});

describe('generateId', () => {
  it('source와 identifier로 ID를 생성한다', () => {
    const id = generateId('saeol', 'gosi.do?idx=123');
    assert.ok(id.startsWith('saeol_'));
    assert.ok(id.length <= 100);
  });

  it('특수문자를 제거한다', () => {
    const id = generateId('board', '?idx=456&gcode=1617');
    assert.ok(!id.includes('?'));
    assert.ok(!id.includes('='));
    assert.ok(!id.includes('&'));
  });
});
