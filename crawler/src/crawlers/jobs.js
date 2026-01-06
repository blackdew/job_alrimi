import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractPhoneNumbers } from '../utils/parser.js';

// 크롤링 대상 URL
const TARGETS = {
  saeol: 'https://www.namhae.go.kr/modules/saeol/gosi.do?pageCd=SM010110000&siteGubun=socialm',
  board: 'https://www.namhae.go.kr/portal/board/List.do?gcode=1617&pageCd=WW0201022000&siteGubun=portal',
  worknet: 'https://gyeongnam.work.go.kr/namhae/main.do',
};

/**
 * 일자리 정보 크롤링
 * @returns {Promise<Array>} 크롤링된 일자리 목록
 */
export async function crawlJobs() {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    const context = await browser.newContext();
    const page = await context.newPage();

    // 남해군청 새올 게시판
    console.log('  - 새올 게시판 크롤링...');
    const saeolJobs = await crawlSaeol(page);
    results.push(...saeolJobs);

    // 남해군청 구인구직 게시판
    console.log('  - 구인구직 게시판 크롤링...');
    const boardJobs = await crawlBoard(page);
    results.push(...boardJobs);

    // TODO: 워크넷 크롤링 (동적 페이지로 별도 처리 필요)
    // console.log('  - 워크넷 크롤링...');
    // const worknetJobs = await crawlWorknet(page);
    // results.push(...worknetJobs);

  } finally {
    await browser.close();
  }

  return results;
}

async function crawlSaeol(page) {
  const jobs = [];

  try {
    await page.goto(TARGETS.saeol, { waitUntil: 'networkidle', timeout: 30000 });
    const html = await page.content();
    const $ = cheerio.load(html);

    // 게시판 목록 파싱 (실제 구조에 맞게 수정 필요)
    $('table tbody tr').each((_, row) => {
      const $row = $(row);
      const title = $row.find('td.title a').text().trim();
      const date = $row.find('td.date').text().trim();
      const link = $row.find('td.title a').attr('href');

      if (title && title.includes('구인') || title.includes('채용') || title.includes('모집')) {
        jobs.push({
          source: 'saeol',
          title,
          date,
          link: link ? `https://www.namhae.go.kr${link}` : null,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    });
  } catch (error) {
    console.error('  새올 크롤링 오류:', error.message);
  }

  return jobs;
}

async function crawlBoard(page) {
  const jobs = [];

  try {
    await page.goto(TARGETS.board, { waitUntil: 'networkidle', timeout: 30000 });
    const html = await page.content();
    const $ = cheerio.load(html);

    // 게시판 목록 파싱 (실제 구조에 맞게 수정 필요)
    $('table tbody tr').each((_, row) => {
      const $row = $(row);
      const title = $row.find('td a').first().text().trim();
      const date = $row.find('td').eq(3).text().trim();
      const link = $row.find('td a').first().attr('href');

      if (title) {
        jobs.push({
          source: 'board',
          title,
          date,
          link: link ? `https://www.namhae.go.kr${link}` : null,
          type: 'job',
          crawledAt: new Date().toISOString(),
        });
      }
    });
  } catch (error) {
    console.error('  구인구직 게시판 크롤링 오류:', error.message);
  }

  return jobs;
}

// 단독 실행 시
if (import.meta.url === `file://${process.argv[1]}`) {
  crawlJobs().then(results => {
    console.log(`\n수집된 일자리: ${results.length}건`);
    results.forEach((job, i) => {
      console.log(`${i + 1}. [${job.source}] ${job.title}`);
    });
  });
}
