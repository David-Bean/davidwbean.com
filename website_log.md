# Personal Website — Notes & Changelog

## Setup

- **Live URL:** davidwbean.com
- **GitHub repo:** github.com/David-Bean/davidwbean.com
- **Local repo:** ~/davidwbean.com
- **Hosting:** GitHub Pages (auto-deploys on push to master)
- **DNS:** Porkbun — 4 A records pointing to GitHub Pages IPs, CNAME for www
- **HTTPS:** Let's Encrypt cert via GitHub Pages, auto-renews every 90 days

## Changelog

- **2026-05-05** — Set up site and repo. DNS configured in Porkbun. Deployed to GitHub Pages at davidwbean.com.

- **2026-05-06** — Major work on butterfly migration chart for homepage. Forked `David-Bean/Migration-COMP5960_Project`, copied final submission files from flash drive to `~/Desktop/Migration-COMP5960_Project/` and local repo. Embedded Altair/Vega-Lite chart in site via vega-embed with custom JS scrubber (autoplay, pause/resume, year segments). Canvas-based land mask using world-atlas 50m topojson with Mercator projection. Map cropped to actual butterfly sighting extent (lat 8–55, lon -126 to -59). Temperature dots: fuzzy (opacity 0.25, pointRadius 13). Butterfly sighting dots: mark_circle with white outline, size 80. Debug stroke still on mask — edge dot bleed issue unresolved, to continue next session.

- **2026-05-07** — Fixed HTTPS. GitHub Pages never provisioned the initial TLS cert (DNS likely hadn't fully propagated when GitHub first tried on May 5th). Fix: cleared and re-added the custom domain via `gh api` to trigger a fresh cert provisioning attempt. Cert issued by Let's Encrypt, valid through 2026-08-05. HTTPS enforcement enabled.

- **2026-05-07** — Fixed static x-axis on line charts. The 208-value repeated domain list was replaced with a clean ["01-02", "12-31"] two-value domain on all four line chart layers, converted to "2000-MM-DD" by fixSpec() at render time. Axis now spans full calendar year and won't rescale as the animation progresses.

- **2026-05-07** — Tweaked map mask vertical bounds: shifted the clip rect up by 2.5% of map height at the top and trimmed the same from the bottom, moving the whole masked region slightly upward. Also removed the debug stroke that was left on the mask from the previous session.

- **2026-05-07** — Darkened page background from original `#f5f0e8` to `#d9d0c0` (on master). Started branch `inheret_chart_colors_from_page`: restructured CSS variables into named `data-theme` blocks (warm, cool-slate, dark-navy, forest, rose, paper); added a theme-switcher dropdown to the nav on all pages with localStorage persistence; wired the Vega chart to inherit all colors from the active CSS palette at load time via `readPalette()` / `applyPalette()` — covers background, axis/legend/title/header text, grid lines, dot colors, highlight lines, historical year line scale, and temperature gradient. Branch committed but not merged to master.

- **2026-05-07** — Fixed static y-axis scale on the Weekly Temperatures in North America chart. Domain was dynamic (auto-fit to visible data); set explicit domain of [10, 80] on both layers.

- **2026-05-07** — Extracted all inline datasets from butterfly_chart.json into separate files under data/. Spec shrank from 27.8MB to 10KB. Datasets: temperature_grid.json (15MB), monarch_sightings.json (11MB), sighting_counts.json (1.5MB), weekly_temperatures.json (14KB), chart_annotations.json (unused, kept for future). Updated index.html to hardcode lon/lat bounds (-126 to -59, 8 to 55) since they were previously computed from the inline temperature grid at load time. Going forward, all chart datasets live in data/ and are referenced by URL in the spec.

- **2026-05-14** — Rebuilt the butterfly chart from scratch in D3/SVG, replacing the Vega-Lite/vega-embed implementation entirely. New architecture: static SVG tier (land, graticule, coastlines) rendered once on resize; dynamic tier (temperature hex dots, sighting circles) with pre-projected coordinates cached at resize time and only attribute mutations per frame. `requestAnimationFrame` throttling on scrubber drag. Bottom line charts (lat density + weekly temperature) also ported to D3. All chart code is embedded inline in index.html. A standalone `butterfly.html` was created during development but is no longer used.

- **2026-05-14** — Fixed severe performance regression in butterfly chart. Root cause: per-element `mask="url(...)"` on ~6,000 SVG dots required one GPU compositor pass per element per frame. Fix: replaced with a single `feGaussianBlur` SVG filter applied to the dot group — one compositor pass per frame regardless of element count. The blur approach also achieves per-dot edge softening (the original intent of the fade control), with the tradeoff that adjacent dots blend slightly at high fade values.

- **2026-05-14** — Set final butterfly chart visual defaults: dotSize=3.20, latScale=0.45, latGamma=0.90, shape=hex, palette=spectral, opacity=0.30, fade=0.00, sightShape=circle, sightFill=#f6f5f4, sightStroke=#1c71d8, sightStrokeWidth=1.5, sightSize=1.25, mapScale=0.90, mapCenterLon=-93.5, mapCenterLat=39.0, mapAspect=0.70.

- **2026-05-14** — Fixed mobile button rendering. Two separate issues: (1) iOS Safari was applying native button chrome via `-webkit-appearance`, overriding the site's button CSS — fixed by adding `appearance: none` to the global button reset in style.css. (2) The play/step button icons (▶ ⏮ ◀ ⏭) are Unicode characters that mobile OSes substitute with colored emoji glyphs — fixed by appending the text variation selector `&#xFE0E;` after each character to force text rendering.
