import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractPhoneNumbers } from '../utils/parser.js';
import { delay, withRetry, safeGoto, parseDate, generateId } from '../utils/crawler.js';

// 크롤링 대상 URL
const TARGETS = {
  // 남해군청 빈집 정보 (귀농귀촌지원센터 → 남해군청으로 통합)
  namhae: 'https://www.namhae.go.kr/depart/Index.do?c=DE0201060000',
  // 그린대로 (남해군 필터: 경남=48, 남해군=48840)
  greendaero: 'https://greendaero.go.kr/user/house/houseList.do?dosi=48&sigungu=48840',
};

// 남해군 귀농귀촌 담당 연락처
const DEFAULT_PHONE = '055-860-8802';  // 남해군청 귀농귀촌담당

/**
 * 빈집 정보 크롤링
 * @returns {Promise<Array>} 크롤링된 빈집 목록
 */
export async function crawlHouses() {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    });
    const page = await context.newPage();

    // 남해군청 빈집 정보
    console.log('  - 남해군청 빈집 정보 크롤링...');
    const namhaeHouses = await withRetry(
      () => crawlNamhae(page),
      { retries: 2, name: '남해군청' }
    );
    results.push(...namhaeHouses);
    await delay(1500);  // Rate limiting

    // 그린대로 (동적 페이지)
    console.log('  - 그린대로 크롤링...');
    const greendaeroHouses = await withRetry(
      () => crawlGreendaero(page),
      { retries: 2, name: '그린대로' }
    );
    results.push(...greendaeroHouses);

  } finally {
    await browser.close();
  }

  return results;
}

/**
 * 남해군청 빈집 정보 크롤링 (테이블 형식)
 */
async function crawlNamhae(page) {
  const houses = [];

  try {
    await safeGoto(page, TARGETS.namhae, { delayAfter: 1500 });
    const html = await page.content();
    const $ = cheerio.load(html);

    // 테이블에서 빈집 정보 추출
    // 컬럼: 번호, 읍면, 주소, 대지면적, 건물면적, 구조, 건축물대장, 건축년도, 소유주
    const rows = $('table tbody tr, table tr').toArray();

    // 대체 선택자: 텍스트 기반
    const tableRows = rows.length > 1
      ? rows
      : $('tr').filter((_, el) => $(el).text().includes('읍') || $(el).text().includes('면')).toArray();

    let headerSkipped = false;
    for (const row of tableRows) {
      const $row = $(row);
      const cells = $row.find('td, th').toArray();

      // 헤더 행 건너뛰기
      if (cells.length > 0 && !headerSkipped) {
        const firstCellText = $(cells[0]).text().trim();
        if (firstCellText === '번호' || firstCellText === 'NO' || firstCellText.includes('순번')) {
          headerSkipped = true;
          continue;
        }
      }

      if (cells.length >= 5) {
        const number = $(cells[0]).text().trim();
        const district = $(cells[1]).text().trim();  // 읍면
        const address = $(cells[2]).text().trim();   // 주소
        const landArea = $(cells[3]).text().trim();  // 대지면적
        const buildArea = $(cells[4]).text().trim(); // 건물면적
        const structure = cells.length > 5 ? $(cells[5]).text().trim() : '';  // 구조
        const buildYear = cells.length > 7 ? $(cells[7]).text().trim() : '';  // 건축년도

        // 유효한 데이터인지 확인 (숫자로 시작하는 번호)
        if (number && /^\d+$/.test(number) && address) {
          const title = `남해군 ${district} 빈집 (${landArea}㎡/${buildArea}㎡)`;

          houses.push({
            id: generateId('namhae', `${number}_${address}`),
            source: 'namhae',
            sourceName: '남해군청 빈집정보',
            title,
            address: `경남 남해군 ${district} ${address}`,
            district,
            landArea,
            buildArea,
            structure,
            buildYear,
            date: null,  // 기준일이 별도 표시됨
            link: TARGETS.namhae,
            phones: [DEFAULT_PHONE],
            type: 'house',
            crawledAt: new Date().toISOString(),
          });
        }
      }
    }

    console.log(`    남해군청: ${houses.length}건 수집`);
  } catch (error) {
    console.error('  남해군청 빈집 크롤링 오류:', error.message);
    throw error;
  }

  return houses;
}

/**
 * 그린대로 크롤링 (동적 페이지)
 */
async function crawlGreendaero(page) {
  const houses = [];

  try {
    await safeGoto(page, TARGETS.greendaero, { waitUntil: 'load', delayAfter: 2000 });

    // 동적 콘텐츠 로딩 대기
    await page.waitForTimeout(3000);

    // JavaScript로 동적 로딩된 콘텐츠를 위해 추가 대기
    try {
      // 빈집 목록이 로딩될 때까지 대기 (최대 10초)
      await page.waitForSelector('.house-list, .list-item, [class*="house"], [class*="item"]', {
        timeout: 10000
      }).catch(() => {});
    } catch (e) {
      // 선택자를 찾지 못해도 계속 진행
    }

    const html = await page.content();
    const $ = cheerio.load(html);

    // 여러 가능한 선택자 시도
    const selectors = [
      '.house-list li',
      '.list-wrap li',
      '.board-list li',
      '[class*="house"] li',
      '[class*="item"]',
      '.card',
      'table tbody tr',
    ];

    let listItems = [];
    for (const selector of selectors) {
      const items = $(selector).toArray();
      if (items.length > 0) {
        listItems = items;
        console.log(`    그린대로 선택자: ${selector} (${items.length}건)`);
        break;
      }
    }

    // 텍스트 기반 폴백: "남해", "매매", "임대" 등 포함된 요소
    if (listItems.length === 0) {
      listItems = $('a, div, li').filter((_, el) => {
        const text = $(el).text();
        return (text.includes('남해') || text.includes('경남')) &&
               (text.includes('매매') || text.includes('임대') || text.includes('빈집'));
      }).toArray();

      if (listItems.length > 0) {
        console.log(`    그린대로: 텍스트 기반 검색 (${listItems.length}건)`);
      }
    }

    for (const el of listItems.slice(0, 30)) {
      const $el = $(el);
      const text = $el.text();

      // 링크 추출
      const $link = $el.is('a') ? $el : $el.find('a').first();
      const href = $link.attr('href');

      // 제목 추출 (다양한 패턴 시도)
      let title = $el.find('.title, .subject, h3, h4, strong').first().text().trim();
      if (!title) {
        title = text.substring(0, 100).trim();
      }

      // 가격 추출
      const priceMatch = text.match(/(\d{1,3}[,\d]*)\s*(만원|원)/);
      const price = priceMatch ? priceMatch[0] : null;

      // 지역 추출
      const locationMatch = text.match(/(남해군|남해)\s*[\w가-힣]+/);
      const location = locationMatch ? locationMatch[0] : '남해군';

      // 면적 추출
      const areaMatch = text.match(/(\d+\.?\d*)\s*(㎡|평)/);
      const area = areaMatch ? areaMatch[0] : null;

      // 불필요한 UI 텍스트 필터링
      const excludePatterns = ['로그인', '메뉴', '위치정보', '출석체크', '동의', '알림', '이용약관'];
      const isExcluded = excludePatterns.some(pattern => title.includes(pattern));

      if (title && title.length > 5 && !isExcluded && (title.includes('빈집') || title.includes('농가') || title.includes('주택') || price || area)) {
        houses.push({
          id: generateId('greendaero', href || title),
          source: 'greendaero',
          sourceName: '그린대로',
          title: title.substring(0, 200),
          price,
          location,
          area,
          date: new Date().toISOString().split('T')[0],
          link: href ? (href.startsWith('http') ? href : `https://greendaero.go.kr${href}`) : TARGETS.greendaero,
          phones: ['1899-9097'],  // 그린대로 고객센터
          type: 'house',
          crawledAt: new Date().toISOString(),
        });
      }
    }

    console.log(`    그린대로: ${houses.length}건 수집`);
  } catch (error) {
    console.error('  그린대로 크롤링 오류:', error.message);
    // 그린대로 실패해도 전체 크롤링은 계속
    return [];
  }

  return houses;
}

// 단독 실행 시
if (import.meta.url === `file://${process.argv[1]}`) {
  crawlHouses().then(results => {
    console.log(`\n=== 수집된 빈집: ${results.length}건 ===`);
    results.forEach((house, i) => {
      console.log(`${i + 1}. [${house.sourceName}] ${house.title}`);
      if (house.address) console.log(`   주소: ${house.address}`);
      if (house.price) console.log(`   가격: ${house.price}`);
      console.log(`   연락처: ${house.phones.join(', ')}`);
    });
  }).catch(err => {
    console.error('크롤링 실패:', err);
    process.exit(1);
  });
}
