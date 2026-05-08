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
