importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD2bINKvz13Hmlg2fyEXiQH93z_jqcLStE",
  authDomain: "her-area.firebaseapp.com",
  projectId: "her-area",
  storageBucket: "her-area.firebasestorage.app",
  messagingSenderId: "175996357308",
  appId: "1:175996357308:web:1b966be0d630fa1c5cdeb9",
  measurementId: "G-484E7XXQJ3"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js - Admin] Received background message ", payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || "HER AREA Admin";
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || payload.data?.message || "",
    icon: "/icons/Icon-192.png",
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const actionUrl = event.notification.data?.action_url || "/";
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (let client of windowClients) {
        if (client.url.includes(self.location.origin) && "focus" in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(actionUrl);
      }
    })
  );
});
