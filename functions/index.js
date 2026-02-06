import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * 푸시 알림 발송 공통 함수
 * @param {string} itemId - 문서 ID
 * @param {Object} data - 문서 데이터
 * @param {string} type - 'job' 또는 'house'
 * @param {string} topic - FCM 토픽 이름
 */
async function sendPushNotification(itemId, data, type, topic) {
  const { title, source } = data;

  const notification = {
    title: type === 'job' ? '💼 새 일자리 정보' : '🏠 새 빈집 정보',
    body: title,
  };

  try {
    const response = await messaging.send({
      topic,
      notification,
      data: {
        itemId,
        type,
        source: source || '',
      },
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });

    console.log(`Successfully sent message to ${topic}: ${response}`);
  } catch (error) {
    console.error(`Error sending message to ${topic}:`, error);
  }
}

/**
 * 새 일자리 문서 생성 시 푸시 알림 발송
 * Firestore 트리거: jobs 컬렉션에 새 문서 추가 시 실행
 */
export const onNewJob = onDocumentCreated('jobs/{jobId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log('No data associated with the event');
    return;
  }

  const data = snapshot.data();
  console.log(`New job created: ${data.title}`);

  await sendPushNotification(event.params.jobId, data, 'job', 'jobs');
});

/**
 * 새 빈집 문서 생성 시 푸시 알림 발송
 * Firestore 트리거: houses 컬렉션에 새 문서 추가 시 실행
 */
export const onNewHouse = onDocumentCreated('houses/{houseId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log('No data associated with the event');
    return;
  }

  const data = snapshot.data();
  console.log(`New house created: ${data.title}`);

  await sendPushNotification(event.params.houseId, data, 'house', 'houses');
});

/**
 * 웹 FCM 토큰이 저장되면 토픽에 구독 처리
 * 웹에서는 클라이언트 측 토픽 구독이 지원되지 않으므로
 * 서버(Admin SDK)에서 토픽 구독을 처리함
 */
export const onTokenCreated = onDocumentWritten('fcm_tokens/{tokenId}', async (event) => {
  const afterData = event.data?.after?.data();

  if (!afterData) {
    console.log('Token document deleted, skipping');
    return;
  }

  const { token, topics } = afterData;

  if (!token || !topics || !Array.isArray(topics)) {
    console.log('Invalid token data');
    return;
  }

  console.log(`Subscribing token to topics: ${topics.join(', ')}`);

  for (const topic of topics) {
    try {
      const response = await messaging.subscribeToTopic([token], topic);
      console.log(`Subscribed to ${topic}: success=${response.successCount}, failure=${response.failureCount}`);

      if (response.failureCount > 0) {
        console.error(`Failed to subscribe to ${topic}:`, response.errors);
      }
    } catch (error) {
      console.error(`Error subscribing to ${topic}:`, error);
    }
  }
});

/**
 * 테스트용 HTTP 함수
 */
// export const testPush = onRequest(async (req, res) => {
//   // 테스트 푸시 발송 로직
//   res.send('Test push sent');
// });
