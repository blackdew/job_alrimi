/**
 * 크롤링 공통 유틸리티
 * - Rate Limiting (서버 부하 방지)
 * - Retry 로직 (네트워크 오류 대응)
 * - 하이브리드 파싱 헬퍼
 */

/**
 * 지연 함수 (서버 부하 방지)
 * @param {number} ms - 대기 시간 (밀리초)
 */
export function delay(ms = 1000) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 재시도 래퍼 함수
 * @param {Function} fn - 실행할 비동기 함수
 * @param {Object} options - 옵션
 * @param {number} options.retries - 재시도 횟수 (기본: 2)
 * @param {number} options.delayMs - 재시도 간 대기 시간 (기본: 2000ms)
 * @param {string} options.name - 작업 이름 (로깅용)
 */
export async function withRetry(fn, options = {}) {
  const { retries = 2, delayMs = 2000, name = '작업' } = options;
  let lastError;

  for (let attempt = 1; attempt <= retries + 1; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt <= retries) {
        console.warn(`  [${name}] 시도 ${attempt} 실패, ${delayMs}ms 후 재시도... (${error.message})`);
        await delay(delayMs);
      }
    }
  }

  throw lastError;
}

/**
 * 안전한 페이지 이동 (Rate Limiting 적용)
 * @param {Page} page - Playwright 페이지 객체
 * @param {string} url - 이동할 URL
 * @param {Object} options - 옵션
 */
export async function safeGoto(page, url, options = {}) {
  const {
    waitUntil = 'networkidle',
    timeout = 30000,
    delayAfter = 1000  // 페이지 로드 후 대기 시간
  } = options;

  await page.goto(url, { waitUntil, timeout });
  await delay(delayAfter);  // 서버 부하 방지
}

/**
 * 하이브리드 선택자 - CSS 선택자 실패 시 텍스트 기반 검색
 * @param {CheerioAPI} $ - Cheerio 인스턴스
 * @param {Object} selectors - 선택자 설정
 * @param {string} selectors.css - CSS 선택자
 * @param {string} selectors.text - 텍스트 패턴 (정규식)
 * @param {string} selectors.fallbackCss - 대체 CSS 선택자
 */
export function hybridSelect($, selectors) {
  const { css, fallbackCss, text } = selectors;

  // 1차: 주 CSS 선택자 시도
  let elements = $(css);
  if (elements.length > 0) {
    return elements;
  }

  // 2차: 대체 CSS 선택자 시도
  if (fallbackCss) {
    elements = $(fallbackCss);
    if (elements.length > 0) {
      console.warn(`  [하이브리드] 대체 선택자 사용: ${fallbackCss}`);
      return elements;
    }
  }

  // 3차: 텍스트 기반 검색
  if (text) {
    const regex = new RegExp(text, 'i');
    elements = $('*').filter((_, el) => {
      const content = $(el).text();
      return regex.test(content);
    });
    if (elements.length > 0) {
      console.warn(`  [하이브리드] 텍스트 기반 검색 사용: ${text}`);
      return elements;
    }
  }

  return $();  // 빈 결과
}

/**
 * 날짜 문자열 파싱 (다양한 형식 지원)
 * @param {string} dateStr - 날짜 문자열
 * @returns {string} ISO 형식 날짜 (YYYY-MM-DD)
 */
export function parseDate(dateStr) {
  if (!dateStr) return null;

  const cleaned = dateStr.trim();

  // YYYY-MM-DD 또는 YYYY.MM.DD
  const match1 = cleaned.match(/(\d{4})[-./](\d{1,2})[-./](\d{1,2})/);
  if (match1) {
    return `${match1[1]}-${match1[2].padStart(2, '0')}-${match1[3].padStart(2, '0')}`;
  }

  // YY.MM.DD
  const match2 = cleaned.match(/(\d{2})[-./](\d{1,2})[-./](\d{1,2})/);
  if (match2) {
    const year = parseInt(match2[1]) > 50 ? `19${match2[1]}` : `20${match2[1]}`;
    return `${year}-${match2[2].padStart(2, '0')}-${match2[3].padStart(2, '0')}`;
  }

  // "등록일 : 2024-01-01" 패턴
  const match3 = cleaned.match(/등록일\s*[:：]\s*(\d{4}[-./]\d{1,2}[-./]\d{1,2})/);
  if (match3) {
    return parseDate(match3[1]);
  }

  return null;
}

/**
 * 고유 ID 생성 (중복 체크용)
 * @param {string} source - 출처
 * @param {string} identifier - 고유 식별자 (URL, 게시물 번호 등)
 */
export function generateId(source, identifier) {
  const cleaned = identifier.replace(/[^a-zA-Z0-9가-힣]/g, '');
  return `${source}_${cleaned}`.substring(0, 100);
}
