importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.15.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBGOQgqAwFmXysHJeuR1MLxBOaOktdx9Dk",
  authDomain: "wastejustice-9620d.firebaseapp.com",
  projectId: "wastejustice-9620d",
  storageBucket: "wastejustice-9620d.firebasestorage.app",
  messagingSenderId: "697041967063",
  appId: "1:697041967063:web:f9bbaf0b756508f90ddd92",
  measurementId: "G-HGNL30NNCF"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
