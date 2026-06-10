// sw.js - Service Worker for VSN Home PWA
const CACHE_NAME = 'vsn-home-v1';
const ASSETS = [
  './',
  './index.html',
  './admin.html',
  './css/style.css',
  './css/admin.css',
  './js/api.js',
  './js/app.js',
  './js/admin.js',
  './manifest.json',
  './icons/icon-192x192.png',
  './icons/icon-512x512.png',
  'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
];

// Install Event - cache core shell resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[Service Worker] Pre-caching resources...');
      return cache.addAll(ASSETS);
    }).then(() => self.skipWaiting())
  );
});

// Activate Event - clear old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[Service Worker] Removing old cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch Event - cache-first with network fallback for assets; network-only for api
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // API Requests should go directly to network
  if (url.pathname.includes('/vsn_grocery_Backend/') || url.pathname.endsWith('.php')) {
    event.respondWith(fetch(event.request));
    return;
  }

  // Assets (HTML, CSS, JS, Fonts, Images)
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Fetch in background to update cache (stale-while-revalidate)
        fetch(event.request).then((networkResponse) => {
          if (networkResponse.status === 200) {
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, networkResponse);
            });
          }
        }).catch(() => {/* Ignore network errors offline */});
        
        return cachedResponse;
      }
      
      // Fallback to network
      return fetch(event.request).then((networkResponse) => {
        // Cache new dynamically requested assets (like unsplash images)
        if (networkResponse.status === 200 && event.request.method === 'GET') {
          const responseClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      });
    })
  );
});
