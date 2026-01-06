import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractPhoneNumbers } from '../utils/parser.js';

// 크롤링 대상 URL
const TARGETS = {
  refarm: 'http://refarm.namhae.go.kr',
  greendaero: 'https://greendaero.go.kr',
};

/**
 * 빈집 정보 크롤링
 * @returns {Promise<Array>} 크롤링된 빈집 목록
 */
export async function crawlHouses() {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    const context = await browser.newContext();
    const page = await context.newPage();

    // 귀농귀촌지원센터
    console.log('  - 귀농귀촌지원센터 크롤링...');
    const refarmHouses = await crawlRefarm(page);
    results.push(...refarmHouses);

    // 그린대로 (남해군 필터)
    console.log('  - 그린대로 크롤링...');
    const greendaeroHouses = await crawlGreendaero(page);
    results.push(...greendaeroHouses);

  } finally {
    await browser.close();
  }

  return results;
}

async function crawlRefarm(page) {
  const houses = [];

  try {
    // TODO: 실제 빈집 게시판 URL 확인 후 구현
    await page.goto(TARGETS.refarm, { waitUntil: 'networkidle', timeout: 30000 });

    // 사이트 구조 분석 필요
    // const html = await page.content();
    // const $ = cheerio.load(html);

    console.log('  (귀농귀촌지원센터 구조 분석 필요)');
  } catch (error) {
    console.error('  귀농귀촌지원센터 크롤링 오류:', error.message);
  }

  return houses;
}

async function crawlGreendaero(page) {
  const houses = [];

  try {
    // TODO: 남해군 필터 적용한 URL 확인 후 구현
    await page.goto(TARGETS.greendaero, { waitUntil: 'networkidle', timeout: 30000 });

    // 사이트 구조 분석 필요
    // const html = await page.content();
    // const $ = cheerio.load(html);

    console.log('  (그린대로 구조 분석 필요)');
  } catch (error) {
    console.error('  그린대로 크롤링 오류:', error.message);
  }

  return houses;
}

// 단독 실행 시
if (import.meta.url === `file://${process.argv[1]}`) {
  crawlHouses().then(results => {
    console.log(`\n수집된 빈집: ${results.length}건`);
    results.forEach((house, i) => {
      console.log(`${i + 1}. [${house.source}] ${house.title}`);
    });
  });
}
