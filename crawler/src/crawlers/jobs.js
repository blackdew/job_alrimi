import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractKeywords, extractPhoneNumbers } from '../utils/parser.js';
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
    try {
      const saeolJobs = await withRetry(
        () => crawlSaeol(page),
        { retries: 2, name: '새올' }
      );
      results.push(...saeolJobs);
    } catch (error) {
      console.error(`  새올 최종 실패 (계속 진행): ${error.message}`);
    }
    await delay(1500);  // Rate limiting

    // 남해군청 구인구직 게시판
    console.log('  - 구인구직 게시판 크롤링...');
    try {
      const boardJobs = await withRetry(
        () => crawlBoard(page),
        { retries: 2, name: '구인구직' }
      );
      results.push(...boardJobs);
    } catch (error) {
      console.error(`  구인구직 최종 실패 (계속 진행): ${error.message}`);
    }
    await delay(1500);  // Rate limiting

    // 경남 워크넷 (남해군)
    console.log('  - 워크넷 크롤링...');
    try {
      const worknetJobs = await withRetry(
        () => crawlWorknet(page),
        { retries: 2, name: '워크넷' }
      );
      results.push(...worknetJobs);
    } catch (error) {
      console.error(`  워크넷 최종 실패 (계속 진행): ${error.message}`);
    }

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
        const link = href?.startsWith('http') ? href : `https://www.namhae.go.kr/modules/saeol/gosi.do${href}`;

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

    // 상세 페이지에서 본문 추출 (최신 10건만)
    for (const job of jobs.slice(0, 10)) {
      try {
        await delay(1000);
        await safeGoto(page, job.link, { delayAfter: 1000 });
        const detailHtml = await page.content();
        const $d = cheerio.load(detailHtml);

        const bodyText = $d('.substance').first().text().trim();
        if (bodyText && bodyText.length > 10) {
          job.description = bodyText;
        }
      } catch (err) {
        // 상세 페이지 접속 실패 시 기본값 유지
      }
    }

    console.log(`    새올: ${jobs.length}건 수집`);
  } catch (error) {
    console.error('  새올 크롤링 오류:', error.message);
    throw error;
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
          phones: [DEFAULT_PHONE],
          keywords,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    // 상세 페이지에서 전화번호와 본문 추출 (최신 10건만)
    for (const job of jobs.slice(0, 10)) {
      try {
        await delay(1000);
        await safeGoto(page, job.link, { delayAfter: 1000 });
        const detailHtml = await page.content();
        const $d = cheerio.load(detailHtml);

        // 본문 영역 추출 (남해군청 구인구직 게시판: .substance)
        const bodyEl = $d('.substance').first();
        const bodyText = bodyEl.length > 0 ? bodyEl.text().trim() : '';

        if (bodyText) {
          // 전화번호 추출: 본문에서 "연락처" 패턴 우선, 없으면 전체 번호 추출
          const contactMatch = bodyText.match(/연락처\s*[:：]\s*([\d\s.-]+)/);
          const phones = contactMatch
            ? extractPhoneNumbers(contactMatch[1])
            : extractPhoneNumbers(bodyText);

          if (phones.length > 0) {
            job.phones = phones;
          }

          // 본문에서 구조화된 정보 추출 (description)
          const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
          const infoLines = lines.filter(l =>
            /^\d+\.\s|사업체|모집|급\s*여|근무|연락처/.test(l)
          );
          if (infoLines.length > 0) {
            job.description = infoLines.join('\n');
          }
        }
      } catch (err) {
        // 상세 페이지 접속 실패 시 기본값 유지
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

    // "우리지역 채용정보" 섹션: work24.go.kr 링크를 포함한 실제 구인 항목
    const listItems = $('ul.region_emp li').toArray();

    if (listItems.length === 0) {
      // 폴백: work24.go.kr 링크가 있는 모든 li
      const fallbackItems = $('a[href*="work24.go.kr"]').closest('li').toArray();
      if (fallbackItems.length > 0) {
        console.log(`    워크넷 폴백 선택자 사용 (${fallbackItems.length}건)`);
        listItems.push(...fallbackItems);
      }
    }

    for (const el of listItems.slice(0, 20)) {
      const $el = $(el);
      const $link = $el.find('a[href*="work24.go.kr"]').first();
      if (!$link.length) continue;

      const href = $link.attr('href');

      // 구조화된 정보 추출
      const company = $link.find('strong').first().text().trim();
      const allText = $link.text().replace(/[\n\r\t]+/g, ' ').replace(/\s+/g, ' ').trim();

      // 제목: 회사명 + 직무명
      const title = allText;

      if (title && title.length > 5) {
        const keywords = extractKeywords(title);

        // 마감일 추출 (26-MM-DD 또는 채용시까지 패턴)
        const deadlineMatch = allText.match(/(\d{2}-\d{2}-\d{2})/g);
        const deadline = deadlineMatch ? deadlineMatch[deadlineMatch.length - 1] : null;

        jobs.push({
          id: generateId('worknet', href || title),
          source: 'worknet',
          sourceName: '경남 워크넷',
          title,
          date: new Date().toISOString().split('T')[0],
          link: href,
          phones: ['1350'],  // 워크넷 고객센터
          keywords,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    // 상세 페이지에서 채용 상세 정보 추출 (최신 10건만)
    for (const job of jobs.slice(0, 10)) {
      if (!job.link || !job.link.includes('work24.go.kr')) continue;
      try {
        await delay(1500);
        await safeGoto(page, job.link, { waitUntil: 'load', delayAfter: 2000 });
        await page.waitForTimeout(1000);

        const desc = await page.evaluate(() => {
          const keys = ['모집 인원', '모집 직종', '임금 조건', '근무 시간', '근무 형태', '근무 예정지', '고용 형태'];
          const parts = [];
          const ths = document.querySelectorAll('th');
          ths.forEach(th => {
            const td = th.nextElementSibling;
            if (!td || td.tagName !== 'TD') return;
            const k = th.textContent.replace(/도움말/g, '').trim();
            if (!keys.includes(k)) return;
            let v = td.textContent.replace(/[\n\r\t]+/g, ' ').replace(/\s+/g, ' ').trim();
            if (v && v !== '-') {
              if (v.includes('지도 보기')) v = v.replace('지도 보기', '').trim();
              parts.push(`${k}: ${v}`);
            }
          });
          // 직무내용
          const jobDescEl = document.querySelector('.careers-new__detail .careers-new__sub');
          if (jobDescEl) {
            const text = jobDescEl.textContent.replace(/[\n\r\t]+/g, ' ').replace(/\s+/g, ' ').trim();
            const match = text.match(/직무내용\s*(.*)/);
            if (match) parts.unshift(`직무내용: ${match[1].trim()}`);
          }
          return parts.length > 0 ? parts.join('\n') : null;
        });

        if (desc) {
          job.description = desc;
        }
      } catch (err) {
        // 상세 페이지 접속 실패 시 기본값 유지
      }
    }

    console.log(`    워크넷: ${jobs.length}건 수집`);
  } catch (error) {
    console.error('  워크넷 크롤링 오류:', error.message);
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
