import 'dotenv/config';
import { crawlJobs } from './crawlers/jobs.js';
import { crawlHouses } from './crawlers/houses.js';
import { initializeFirebase, saveIfNew } from './utils/firebase.js';

/**
 * 크롤링 결과를 Firestore에 저장
 * @param {Array} items - 저장할 항목들
 * @param {string} collection - 컬렉션 이름 ('jobs' 또는 'houses')
 * @returns {number} 새로 저장된 항목 수
 */
async function saveToFirestore(items, collection) {
  let newCount = 0;

  for (const item of items) {
    const saved = await saveIfNew(collection, item, 'id');
    if (saved) {
      newCount++;
      console.log(`  [신규] ${item.title.substring(0, 50)}...`);
    }
  }

  return newCount;
}

async function main() {
  console.log('=== 남해군 일자리/빈집 크롤러 시작 ===');
  console.log(`시작 시간: ${new Date().toLocaleString('ko-KR')}`);

  // Firebase 초기화
  const db = initializeFirebase();
  const isLocalMode = !db;

  if (isLocalMode) {
    console.log('\n⚠️  Firebase 미연결 - 로컬 모드로 실행\n');
  } else {
    console.log('\n✅ Firebase 연결됨\n');
  }

  try {
    // 일자리 크롤링
    console.log('[1/2] 일자리 정보 크롤링...');
    const jobResults = await crawlJobs();
    console.log(`일자리: ${jobResults.length}건 수집`);

    // 빈집 크롤링
    console.log('\n[2/2] 빈집 정보 크롤링...');
    const houseResults = await crawlHouses();
    console.log(`빈집: ${houseResults.length}건 수집`);

    // Firestore 저장
    if (!isLocalMode) {
      console.log('\n[저장] Firestore에 신규 데이터 저장 중...');

      const newJobs = await saveToFirestore(jobResults, 'jobs');
      const newHouses = await saveToFirestore(houseResults, 'houses');

      console.log(`\n신규 저장: 일자리 ${newJobs}건, 빈집 ${newHouses}건`);
    }

    console.log('\n=== 크롤링 완료 ===');
    console.log(`총 ${jobResults.length + houseResults.length}건 수집`);
    console.log(`종료 시간: ${new Date().toLocaleString('ko-KR')}`);

  } catch (error) {
    console.error('크롤링 중 오류 발생:', error);
    process.exit(1);
  }
}

main();
