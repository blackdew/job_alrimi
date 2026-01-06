import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractPhoneNumbers, extractKeywords } from '../utils/parser.js';
import { delay, withRetry, safeGoto, parseDate, generateId } from '../utils/crawler.js';

// 크롤링 대상 URL
const TARGETS = {
  saeol: 'https://www.namhae.go.kr/modules/saeol/gosi.do?pageCd=SM010110000&siteGubun=socialm',
  board: 'https://www.namhae.go.kr/portal/board/List.do?gcode=1617&pageCd=WW0201022000&siteGubun=portal',
  worknet: 'https://gyeongnam.work.go.kr/namhae/main.do',
};

// 남해군 대표 연락처 (전화번호 추출 실패 시 사용)
const DEFAULT_PHONE = '055-860-3835';  // 남해군청 대표번호

/**
 * 일자리 정보 크롤링
 * @returns {Promise<Array>} 크롤링된 일자리 목록
 */
export async function crawlJobs() {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    });
    const page = await context.newPage();

    // 남해군청 새올 게시판
    console.log('  - 새올 게시판 크롤링...');
    const saeolJobs = await withRetry(
      () => crawlSaeol(page),
      { retries: 2, name: '새올' }
    );
    results.push(...saeolJobs);
    await delay(1500);  // Rate limiting

    // 남해군청 구인구직 게시판
    console.log('  - 구인구직 게시판 크롤링...');
    const boardJobs = await withRetry(
      () => crawlBoard(page),
      { retries: 2, name: '구인구직' }
    );
    results.push(...boardJobs);
    await delay(1500);  // Rate limiting

    // 경남 워크넷 (남해군)
    console.log('  - 워크넷 크롤링...');
    const worknetJobs = await withRetry(
      () => crawlWorknet(page),
      { retries: 2, name: '워크넷' }
    );
    results.push(...worknetJobs);

  } finally {
    await browser.close();
  }

  return results;
}

/**
 * 새올 게시판 크롤링 (공고/고시)
 */
async function crawlSaeol(page) {
  const jobs = [];

  try {
    await safeGoto(page, TARGETS.saeol, { delayAfter: 1500 });
    const html = await page.content();
    const $ = cheerio.load(html);

    // 새올 게시판: ul > li > a 구조
    const listItems = $('ul li a[href*="gosi.do"]').toArray();

    // 대체 선택자: 텍스트에 "등록일" 포함된 li 찾기
    const items = listItems.length > 0
      ? listItems
      : $('li').filter((_, el) => $(el).text().includes('등록일')).find('a').toArray();

    for (const el of items.slice(0, 20)) {  // 최신 20개만
      const $el = $(el);
      const href = $el.attr('href');
      const text = $el.text();

      // 제목 추출 (b 태그 또는 전체 텍스트에서)
      const title = $el.find('b').text().trim() || text.split(/등록일|고시번호/)[0].trim();

      // 날짜 추출
      const dateMatch = text.match(/등록일\s*[:：]\s*([\d.-]+)/);
      const date = dateMatch ? parseDate(dateMatch[1]) : null;

      // 연락처 추출
      const phoneMatch = text.match(/연락처\s*[:：]\s*([\d-]+)/);
      const phones = phoneMatch ? [phoneMatch[1]] : [];

      // 구인/채용 관련 키워드 필터링 (선택적)
      const keywords = extractKeywords(title + ' ' + text);

      if (title && title.length > 2) {
        const link = href?.startsWith('http') ? href : `https://www.namhae.go.kr/modules/saeol/${href}`;

        jobs.push({
          id: generateId('saeol', href || title),
          source: 'saeol',
          sourceName: '남해군청 새올',
          title,
          date,
          link,
          phones: phones.length > 0 ? phones : [DEFAULT_PHONE],
          keywords,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    console.log(`    새올: ${jobs.length}건 수집`);
  } catch (error) {
    console.error('  새올 크롤링 오류:', error.message);
    throw error;  // withRetry에서 재시도하도록
  }

  return jobs;
}

/**
 * 구인구직 게시판 크롤링
 */
async function crawlBoard(page) {
  const jobs = [];

  try {
    await safeGoto(page, TARGETS.board, { delayAfter: 1500 });
    const html = await page.content();
    const $ = cheerio.load(html);

    // 구인구직 게시판: ul > li > a 구조
    // 링크 패턴: /portal/board/View.do?gcode=1617&idx=...
    const listItems = $('a[href*="View.do"][href*="gcode=1617"]').toArray();

    // 대체 선택자
    const items = listItems.length > 0
      ? listItems
      : $('li').find('a[href*="View.do"]').toArray();

    for (const el of items.slice(0, 30)) {  // 최신 30개
      const $el = $(el);
      const href = $el.attr('href');

      // 부모 li에서 날짜 추출 (형식: "제목 _ 2024-01-01 _ 작성자")
      const parentText = $el.closest('li').text();
      const dateMatch = parentText.match(/(\d{4}-\d{2}-\d{2})/);
      const date = dateMatch ? dateMatch[1] : null;

      // 제목 추출 (링크 텍스트에서 날짜/작성자/조회수 제거)
      let title = $el.text().trim();
      // 개행문자 및 연속 공백 제거
      title = title.replace(/[\n\r\t]+/g, ' ').replace(/\s+/g, ' ').trim();
      // 날짜, 작성자(○○), 조회수 패턴 제거
      title = title
        .replace(/\d{4}-\d{2}-\d{2}/, '')  // 날짜 제거
        .replace(/[가-힣]○○/, '')          // 작성자 제거 (김○○ 등)
        .replace(/조회수\s*[:：]?\s*\d+/, '')  // 조회수 제거
        .replace(/\s+/g, ' ')
        .trim();

      // 키워드 추출
      const keywords = extractKeywords(title);

      if (title && title.length > 2 && title.length < 200 && !title.includes('검색') && !title.includes('정렬')) {
        const link = href?.startsWith('http') ? href : `https://www.namhae.go.kr${href}`;

        jobs.push({
          id: generateId('board', href || title),
          source: 'board',
          sourceName: '남해군청 구인구직',
          title,
          date,
          link,
          phones: [DEFAULT_PHONE],  // 상세 페이지에서 추출 필요
          keywords,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    console.log(`    구인구직: ${jobs.length}건 수집`);
  } catch (error) {
    console.error('  구인구직 게시판 크롤링 오류:', error.message);
    throw error;
  }

  return jobs;
}

/**
 * 워크넷 크롤링 (동적 페이지)
 */
async function crawlWorknet(page) {
  const jobs = [];

  try {
    await safeGoto(page, TARGETS.worknet, { waitUntil: 'load', delayAfter: 2000 });

    // 워크넷은 동적 로딩이므로 추가 대기
    await page.waitForTimeout(2000);

    const html = await page.content();
    const $ = cheerio.load(html);

    // 워크넷 구인정보 목록 찾기 (여러 선택자 시도)
    const selectors = [
      '.job-list li',           // 일반적인 구인목록
      '.recruit-list li',       // 채용정보 리스트
      'table tbody tr',         // 테이블 형식
      '.board-list li',         // 게시판 형식
      '[class*="job"] li',      // job 포함 클래스
      '[class*="recruit"] li',  // recruit 포함 클래스
    ];

    let listItems = [];
    for (const selector of selectors) {
      const items = $(selector).toArray();
      if (items.length > 0) {
        listItems = items;
        console.log(`    워크넷 선택자: ${selector} (${items.length}건)`);
        break;
      }
    }

    // 텍스트 기반 폴백: "채용", "모집" 등 포함된 요소
    if (listItems.length === 0) {
      listItems = $('a').filter((_, el) => {
        const text = $(el).text();
        return text.includes('채용') || text.includes('모집') || text.includes('구인');
      }).toArray();
    }

    for (const el of listItems.slice(0, 20)) {
      const $el = $(el);
      let title, href;

      // 링크가 있는 경우
      const $link = $el.is('a') ? $el : $el.find('a').first();
      if ($link.length) {
        title = $link.text().trim();
        href = $link.attr('href');
      } else {
        title = $el.text().trim().substring(0, 100);
      }

      // 제목 정리 (공백, 개행 제거)
      if (title) {
        title = title.replace(/[\n\r\t]+/g, ' ').replace(/\s+/g, ' ').trim();
      }

      if (title && title.length > 5 && title.length < 200) {
        const keywords = extractKeywords(title);

        jobs.push({
          id: generateId('worknet', href || title),
          source: 'worknet',
          sourceName: '경남 워크넷',
          title,
          date: new Date().toISOString().split('T')[0],  // 오늘 날짜
          link: href ? (href.startsWith('http') ? href : `https://gyeongnam.work.go.kr${href}`) : TARGETS.worknet,
          phones: ['1350'],  // 워크넷 고객센터
          keywords,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    console.log(`    워크넷: ${jobs.length}건 수집`);
  } catch (error) {
    console.error('  워크넷 크롤링 오류:', error.message);
    // 워크넷은 실패해도 전체 크롤링은 계속
    return [];
  }

  return jobs;
}

// 단독 실행 시
if (import.meta.url === `file://${process.argv[1]}`) {
  crawlJobs().then(results => {
    console.log(`\n=== 수집된 일자리: ${results.length}건 ===`);
    results.forEach((job, i) => {
      console.log(`${i + 1}. [${job.sourceName}] ${job.title}`);
      console.log(`   날짜: ${job.date || 'N/A'} | 연락처: ${job.phones.join(', ')}`);
    });
  }).catch(err => {
    console.error('크롤링 실패:', err);
    process.exit(1);
  });
}
