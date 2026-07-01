'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "888483df48293866f9f41d3d9274a779",
"assets/FontManifest.json": "4d4b9ba05deaad75d1fa921bde5a72be",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "d7d83bd9ee909f8a9b348f56ca7b68c6",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "b2703f18eee8303425a5342dba6958db",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "972c3d4529d346d46f319a71abeebd01",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "5b8d20acec3e57711717f61417c1be44",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/iconsax_plus/fonts/IconsaxPlusBroken.ttf": "71d12baa6ddbb770fb8f6d92021403e4",
"assets/packages/iconsax_plus/fonts/IconsaxPlusBold.ttf": "805a1bab0f9865af92fcec87325e104c",
"assets/packages/iconsax_plus/fonts/IconsaxPlusLinear.ttf": "08f8e5eef32e66caa70d237eea7e3edb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/mp-font.ttf": "750d21c71e708fe9f958a033f7270971",
"assets/assets/gradient.png": "ccb9883f9be5f0cfa49454deffe6ad0b",
"assets/assets/driftfin_logo_black.png": "c4a77be62cf44e536c0631e1004fa290",
"assets/assets/driftfin_icon.afphoto": "867e47312c7f4371f4ca68aae3b872be",
"assets/assets/driftfin_wordmark_white.png": "fb7d24656ff2573fee98620bdca77979",
"assets/assets/Icon.svg": "70a30f30002912d06608bc92dd4797db",
"assets/assets/fonts/rubik/Rubik-VariableFont_wght.ttf": "6d3102fa33194bef395536d580f91b56",
"assets/assets/fonts/rubik/Rubik-Italic-VariableFont_wght.ttf": "b98b18526d653e20777cacb1f43f62c4",
"assets/assets/fonts/opensans/OpenSans-Italic.ttf": "31d95e96058490552ea28f732456d002",
"assets/assets/fonts/opensans/OpenSans.ttf": "78609089d3dad36318ae0190321e6f3e",
"assets/assets/driftfin_wordmark_black.png": "d0565a284654b9846bb4b792ead9898b",
"assets/assets/driftfin_wordmark.png": "7151e058729f5acbbb11005ea8f7bbdd",
"assets/assets/Icon.afdesign": "40eb045507400791a18318700a606466",
"assets/assets/driftfin_logo.png": "ac764aadf41ef1073f7d9bdb878da022",
"assets/assets/high-resolution-color-logo.png": "7a69c0ea1d561db193e78c9cdbb50d08",
"assets/assets/driftfin_icon_general.afphoto": "7ea2e34b41247b6e0c44ae44d53ead3e",
"assets/assets/driftfin_logo_white.png": "6e12d858a86ece8a6a8c086ae58dd392",
"assets/icons/driftfin_icon.svg": "ec51177ecb94d5f456f5579c3c221345",
"assets/icons/popcorn_bucket.svg": "8a89801bc00301e9fd46b76d937bbe12",
"assets/icons/driftfin_icon_outline.svg": "ec51177ecb94d5f456f5579c3c221345",
"assets/icons/driftfin_notification_icon.png": "312c6b78e1813fc4dbaed76c260030ed",
"assets/icons/tomato.svg": "bdce69a23d727ded2b1f066d91782149",
"assets/AssetManifest.bin.json": "f8060497bcef805d3c5dbd28a4f6af65",
"assets/fonts/MaterialIcons-Regular.otf": "7983f1c55d4fbb15e295141eba7e0e1a",
"assets/config/config.json": "7a6ca4d4f37ea73f8e1b88955d202775",
"assets/AssetManifest.bin": "b19a1ea89bfaf9f42c2848b345df6628",
"assets/NOTICES": "678fd1de1573397eacaf339e66d92b04",
"assets/AssetManifest.json": "4946e9f79f4c1d8bfe17ee1b2fdd798d",
"icons/Icon-512.png": "63b674fdf97bec798debe4977802d5ef",
"icons/Icon-maskable-512.png": "63b674fdf97bec798debe4977802d5ef",
"icons/Icon-maskable-192.png": "f7a1452adbe449685bf7da58efe4e9f9",
"icons/Icon-192.png": "f7a1452adbe449685bf7da58efe4e9f9",
"drift_worker.dart.js": "afac8b57eb80f0846a382f7303929b0f",
"flutter_bootstrap.js": "48a47ed8bf668ba744b518c705052836",
"sqlite3.wasm": "9839e2a1f55c56501c36b8e8483ee663",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"index.html": "d2822d7acdf5894f2cf538ef246f0f12",
"/": "d2822d7acdf5894f2cf538ef246f0f12",
"main.dart.js": "af07c9d51507b4d0fb5723a97a55b312",
"favicon.png": "39a611c789478e0ccc8696c56172cdbf",
"manifest.json": "1940f204b5a64d995e108928561299c1",
"version.json": "cebd8cbd03ff9b70fb651486e311b25d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
