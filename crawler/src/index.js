import 'dotenv/config';
import { crawlJobs } from './crawlers/jobs.js';
import { crawlHouses } from './crawlers/houses.js';

async function main() {
  console.log('=== 남해군 일자리/빈집 크롤러 시작 ===');
  console.log(`시작 시간: ${new Date().toLocaleString('ko-KR')}`);

  try {
    // 일자리 크롤링
    console.log('\n[1/2] 일자리 정보 크롤링...');
    const jobResults = await crawlJobs();
    console.log(`일자리: ${jobResults.length}건 수집`);

    // 빈집 크롤링
    console.log('\n[2/2] 빈집 정보 크롤링...');
    const houseResults = await crawlHouses();
    console.log(`빈집: ${houseResults.length}건 수집`);

    console.log('\n=== 크롤링 완료 ===');
    console.log(`총 ${jobResults.length + houseResults.length}건 수집`);
  } catch (error) {
    console.error('크롤링 중 오류 발생:', error);
    process.exit(1);
  }
}

main();
