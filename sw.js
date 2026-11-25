/* Минимальный service worker для установки на экран. Офлайн-кэша нет: приложение всегда берётся с сервера. */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => {});
