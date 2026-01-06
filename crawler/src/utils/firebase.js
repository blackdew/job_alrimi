import admin from 'firebase-admin';

let db = null;

/**
 * Firebase Admin 초기화
 */
export function initializeFirebase() {
  if (admin.apps.length > 0) {
    return admin.firestore();
  }

  const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;

  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    console.warn('Firebase 환경변수가 설정되지 않았습니다. 로컬 모드로 실행합니다.');
    return null;
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: FIREBASE_PROJECT_ID,
      clientEmail: FIREBASE_CLIENT_EMAIL,
      privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });

  db = admin.firestore();
  return db;
}

/**
 * Firestore에 문서 저장 (중복 체크 포함)
 * @param {string} collection - 컬렉션 이름
 * @param {Object} data - 저장할 데이터
 * @param {string} uniqueField - 중복 체크 필드
 * @returns {Promise<boolean>} 저장 성공 여부
 */
export async function saveIfNew(collection, data, uniqueField = 'link') {
  if (!db) {
    console.log('[로컬 모드] 저장 건너뜀:', data.title);
    return false;
  }

  const uniqueValue = data[uniqueField];
  if (!uniqueValue) {
    console.warn('중복 체크 필드가 없습니다:', uniqueField);
    return false;
  }

  // 중복 체크
  const existing = await db
    .collection(collection)
    .where(uniqueField, '==', uniqueValue)
    .limit(1)
    .get();

  if (!existing.empty) {
    return false; // 이미 존재
  }

  // 새 문서 저장
  await db.collection(collection).add({
    ...data,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return true;
}

/**
 * Firestore 인스턴스 반환
 */
export function getFirestore() {
  return db;
}
