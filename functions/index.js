import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * 새 문서 생성 시 푸시 알림 발송
 * Firestore 트리거: items 컬렉션에 새 문서 추가 시 실행
 */
export const onNewItem = onDocumentCreated('items/{itemId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log('No data associated with the event');
    return;
  }

  const data = snapshot.data();
  const { title, type, source } = data;

  console.log(`New item created: ${title} (${type})`);

  // 알림 메시지 구성
  const notification = {
    title: type === 'job' ? '💼 새 일자리 정보' : '🏠 새 빈집 정보',
    body: title,
  };

  // 토픽 결정 (일자리/빈집 구독자)
  const topic = type === 'job' ? 'jobs' : 'houses';

  try {
    // 토픽 구독자에게 푸시 발송
    const response = await messaging.send({
      topic,
      notification,
      data: {
        itemId: event.params.itemId,
        type,
        source,
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

    console.log(`Successfully sent message: ${response}`);
  } catch (error) {
    console.error('Error sending message:', error);
  }
});

/**
 * 테스트용 HTTP 함수
 */
// export const testPush = onRequest(async (req, res) => {
//   // 테스트 푸시 발송 로직
//   res.send('Test push sent');
// });
