/* Terrein3D service worker – offline cache */
const APP = 't3d-app-v18';
const DATA = 't3d-data-v1';
const LIVE = /(open-meteo\.com|rainviewer\.com|nominatim\.openstreetmap\.org)$/;
const NOCACHE = /(hivemq\.com|emqx\.io|mosquitto\.org)$/;

self.addEventListener('install', e => {
  e.waitUntil(caches.open(APP).then(c => c.addAll(['./', './index.html'])).catch(() => {}));
  self.skipWaiting();
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k.startsWith('t3d-app-') && k !== APP).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;
  const u = new URL(r.url);
  if (NOCACHE.test(u.hostname)) return;
  // de app zelf: eerst netwerk (altijd nieuwste versie), anders cache
  if (u.origin === self.location.origin) {
    e.respondWith(fetch(r).then(res => { const cp = res.clone(); caches.open(APP).then(c => c.put(r, cp)); return res; })
      .catch(() => caches.match(r, { ignoreSearch: true }).then(m => m || caches.match('./index.html'))));
    return;
  }
  // actuele data (weer, radar): eerst netwerk, offline uit cache
  if (LIVE.test(u.hostname)) {
    e.respondWith(fetch(r).then(res => { if (res.ok) { const cp = res.clone(); caches.open(DATA).then(c => c.put(r, cp)); } return res; })
      .catch(() => caches.match(r)));
    return;
  }
  // kaarttegels, hoogtedata, kenmerken, bibliotheken: eerst cache, anders netwerk (en bewaren)
  e.respondWith(caches.open(DATA).then(c => c.match(r).then(m => m || fetch(r).then(res => {
    if (res.ok) c.put(r, res.clone());
    return res;
  }))));
});
