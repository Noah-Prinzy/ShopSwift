# backend/Public — PWA static assets

This folder contains a minimal browser-facing PWA shell that demonstrates the same REST API used by the SwiftUI client.

Files:
- `index.html`: The single-page PWA shell with hash routing and UI templates.
- `app.js`: Client-side logic for presentation, navigation, and invoking the backend REST API.
- `styles.css`: Visual theme and layout for the demo storefront.
- `sw.js`: A small service worker that caches the static shell only.
- `manifest.webmanifest`: PWA metadata for installability.

Notes:
- `manifest.webmanifest` is JSON and therefore not commented inline; see this README for its purpose.
- The app intentionally keeps API requests network-only (not cached) so product stock and account data are always fresh.
