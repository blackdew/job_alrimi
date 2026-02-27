import { chromium } from 'playwright';
import * as cheerio from 'cheerio';
import { extractPhoneNumbers } from '../utils/parser.js';
import { delay, withRetry, safeGoto, parseDate, generateId } from '../utils/crawler.js';

// 크롤링 대상 URL
const TARGETS = {
  // 남해군청 빈집 정보 (귀농귀촌지원센터 → 남해군청으로 통합)
  namhae: 'https://www.namhae.go.kr/depart/Index.do?c=DE0201060000',
  // 그린대로 - 빈집 목록 페이지 (SPA 진입점)
  greendaero: 'https://www.greendaero.go.kr/svc/rfph/cpif/front/vacantlist.do',
  // 그린대로 API 엔드포인트
  greendaeroApi: '/svc/rfph/cpif/getVacantHomePagingList.do',
};

// 그린대로 지역 코드
const GREENDAERO_CODES = {
  gyeongnam: '6480000',  // 경상남도
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
    try {
      const namhaeHouses = await withRetry(
        () => crawlNamhae(page),
        { retries: 2, name: '남해군청' }
      );
      results.push(...namhaeHouses);
    } catch (error) {
      console.error(`  남해군청 빈집 최종 실패 (계속 진행): ${error.message}`);
    }
    await delay(1500);  // Rate limiting

    // 그린대로 (동적 페이지)
    console.log('  - 그린대로 크롤링...');
    try {
      const greendaeroHouses = await withRetry(
        () => crawlGreendaero(page),
        { retries: 2, name: '그린대로' }
      );
      results.push(...greendaeroHouses);
    } catch (error) {
      console.error(`  그린대로 최종 실패 (계속 진행): ${error.message}`);
    }

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
 * 그린대로 크롤링 (API 직접 호출 방식)
 * - SPA 구조로 인해 DOM 파싱 대신 API 직접 호출
 * - 경상남도 전체 데이터 조회 후 남해군 필터링
 */
async function crawlGreendaero(page) {
  const houses = [];

  try {
    // 1. 빈집 목록 페이지 접속 (세션 초기화)
    // SPA이므로 domcontentloaded 후 추가 대기로 처리 (#29)
    await safeGoto(page, TARGETS.greendaero, { waitUntil: 'domcontentloaded', delayAfter: 3000 });

    // 2. API를 통해 경상남도 빈집 데이터 조회
    const apiParams = {
      apiPath: TARGETS.greendaeroApi,
      ctpvCd: GREENDAERO_CODES.gyeongnam
    };
    const response = await page.evaluate(async (params) => {
      try {
        const url = `${params.apiPath}?page=1&itemsPerPage=100&ctpvCd=${params.ctpvCd}`;
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return await res.json();
      } catch (e) {
        return { error: e.message, list: [] };
      }
    }, apiParams);

    if (response.error) {
      console.log(`    그린대로 API 오류: ${response.error}`);
      return [];
    }

    // 3. 남해군 데이터 필터링
    const namhaeData = (response.list || []).filter(item =>
      item.sggNm?.includes('남해') ||
      item.dongAddr?.includes('남해') ||
      item.addr?.includes('남해')
    );

    console.log(`    그린대로 API: 경상남도 ${response.list?.length || 0}건 중 남해군 ${namhaeData.length}건`);

    // 4. 데이터 변환
    for (const item of namhaeData) {
      // 거래 유형 매핑
      const dealTypeMap = { '01': '매매', '02': '전세', '03': '월세', '04': '연세' };
      const dealType = dealTypeMap[item.estateDlingTypeCd] || '';

      // 가격 정보 파싱
      const deposit = item.grnteAmt ? `${Number(item.grnteAmt).toLocaleString()}만원` : null;

      // 제목 생성 (원본 제목이 없거나 너무 짧으면 주소 기반으로 생성)
      let title = item.pstTtlNm?.trim();
      if (!title || title.length < 3) {
        const district = item.addr?.match(/남해군\s*(\S+)/)?.[1] || '';
        title = `남해군 ${district} 빈집 ${dealType}`;
      }

      houses.push({
        id: generateId('greendaero', String(item.bbscttSn)),
        source: 'greendaero',
        sourceName: '그린대로',
        title: title.substring(0, 200),
        address: item.addr || item.dongAddr || '',
        price: deposit,
        area: item.areaSize ? `${item.areaSize}㎡` : null,
        dealType,
        description: item.iemCn5?.replace('매물특징 :', '').trim() || null,
        date: item.frstRegDt || new Date().toISOString().split('T')[0],
        link: `https://www.greendaero.go.kr/svc/rfph/cpif/front/vacantview.do?bbscttSn=${item.bbscttSn}`,
        phones: ['1899-9097'],  // 그린대로 고객센터
        type: 'house',
        crawledAt: new Date().toISOString(),
      });
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
