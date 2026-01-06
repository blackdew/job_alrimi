import 'dotenv/config';
import cron from 'node-cron';
import { crawlJobs } from './crawlers/jobs.js';
import { crawlHouses } from './crawlers/houses.js';
import { initializeFirebase, saveIfNew } from './utils/firebase.js';

/**
 * 크롤링 결과를 Firestore에 저장
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

/**
 * 크롤링 작업 실행
 */
async function runCrawler() {
  const startTime = new Date();
  console.log(`\n${'='.repeat(50)}`);
  console.log(`[${startTime.toLocaleString('ko-KR')}] 크롤링 시작`);
  console.log('='.repeat(50));

  try {
    // 일자리 크롤링
    console.log('\n[1/2] 일자리 정보 크롤링...');
    const jobResults = await crawlJobs();
    console.log(`일자리: ${jobResults.length}건 수집`);

    // 빈집 크롤링
    console.log('\n[2/2] 빈집 정보 크롤링...');
    const houseResults = await crawlHouses();
    console.log(`빈집: ${houseResults.length}건 수집`);

    // Firestore 저장
    const db = initializeFirebase();
    if (db) {
      console.log('\n[저장] Firestore에 신규 데이터 저장 중...');
      const newJobs = await saveToFirestore(jobResults, 'jobs');
      const newHouses = await saveToFirestore(houseResults, 'houses');
      console.log(`\n신규 저장: 일자리 ${newJobs}건, 빈집 ${newHouses}건`);
    }

    const endTime = new Date();
    const duration = ((endTime - startTime) / 1000).toFixed(1);
    console.log(`\n✅ 크롤링 완료 (소요시간: ${duration}초)`);

  } catch (error) {
    console.error('\n❌ 크롤링 실패:', error.message);
  }
}

// 메인 실행
async function main() {
  console.log('=== 남해군 일자리/빈집 크롤러 스케줄러 ===');
  console.log(`시작 시간: ${new Date().toLocaleString('ko-KR')}`);

  // Firebase 초기화
  const db = initializeFirebase();
  if (!db) {
    console.log('⚠️  Firebase 미연결 - 로컬 모드로 실행');
  } else {
    console.log('✅ Firebase 연결됨');
  }

  // 시작 시 즉시 1회 실행
  console.log('\n📌 초기 크롤링 실행...');
  await runCrawler();

  // 30분마다 실행 (0분, 30분)
  const schedule = '0,30 * * * *';  // 매시 0분, 30분
  console.log(`\n⏰ 스케줄러 시작: ${schedule} (30분 간격)`);

  cron.schedule(schedule, async () => {
    await runCrawler();
  });

  console.log('스케줄러가 실행 중입니다. Ctrl+C로 종료하세요.\n');
}

// 프로세스 종료 처리
process.on('SIGINT', () => {
  console.log('\n\n스케줄러 종료...');
  process.exit(0);
});

main();
