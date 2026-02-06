// Firebase Cloud Messaging Service Worker
// 웹 브라우저 백그라운드에서 푸시 알림을 수신하기 위한 Service Worker

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase 설정 (firebase_options.dart의 web 설정과 동일)
firebase.initializeApp({
  apiKey: 'AIzaSyADHLRByIY0LsUTgh_aUXgUDD_h2TlLjsU',
  authDomain: 'job-alrimi.firebaseapp.com',
  projectId: 'job-alrimi',
  storageBucket: 'job-alrimi.firebasestorage.app',
  messagingSenderId: '131472774496',
  appId: '1:131472774496:web:07ca43e3e70881994efa05'
});

const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  // notification 필드가 있으면 브라우저가 자동으로 알림 표시
  // data-only 메시지인 경우 수동으로 알림 표시
  if (!payload.notification) {
    const notificationTitle = payload.data?.title || '남해 알리미';
    const notificationOptions = {
      body: payload.data?.body || '새로운 알림이 있습니다.',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: payload.data?.itemId || 'default',
      data: payload.data
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  }
});

// 알림 클릭 처리
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);

  event.notification.close();

  const itemId = event.notification.data?.itemId;
  const type = event.notification.data?.type;

  // 클릭 시 앱으로 이동 (아이템 정보가 있으면 상세 페이지로)
  let urlToOpen = '/';
  if (itemId && type) {
    urlToOpen = `/?item=${itemId}&type=${type}`;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // 이미 열린 창이 있으면 포커스
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            client.navigate(urlToOpen);
            return client.focus();
          }
        }
        // 열린 창이 없으면 새 창 열기
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
