// Service worker : met en cache l'interface pour un lancement hors ligne.
// Les appels à l'API Ollama ne sont jamais mis en cache.
const CACHE = "caloriephoto-v2";
const RESSOURCES = ["./", "./index.html", "./manifest.json", "./icon.svg"];

self.addEventListener("install", (ev) => {
  ev.waitUntil(caches.open(CACHE).then((c) => c.addAll(RESSOURCES)));
  self.skipWaiting();
});

self.addEventListener("activate", (ev) => {
  ev.waitUntil(
    caches.keys().then((cles) =>
      Promise.all(cles.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (ev) => {
  const url = new URL(ev.request.url);
  if (ev.request.method !== "GET" || url.origin !== self.location.origin) return;
  ev.respondWith(
    fetch(ev.request)
      .then((rep) => {
        const copie = rep.clone();
        caches.open(CACHE).then((c) => c.put(ev.request, copie));
        return rep;
      })
      .catch(() => caches.match(ev.request))
  );
});
