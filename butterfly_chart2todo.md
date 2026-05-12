# Butterfly Chart 2.0 — To-Do List

## Rule
**Always `ls -lh` a file before opening it.** If it's large or data-heavy, ask the user before reading. Never open data files (CSV, JSON data assets) without explicit permission.

---

## Tasks

### [x] 1. Reference existing temperature chart for visual design
Reviewed `butterfly_chart.json`. Key design details:

**Layout:**
- `vconcat`: map on top (1000×680), two line charts side-by-side below (each 500×210)
- Map uses Mercator projection; bottom charts are `hconcat`

**Controls:**
- `week_select_param`: range slider, weeks 1–51 (primary scrubber)
- `year_select_param`: dropdown, options [2002, 2007, 2012, 2017] (year highlight)

**Map layers:**
- Temperature grid: geoshape, `oranges` color scheme, domain [32, 100]°F, opacity 0.25, pointRadius ~13
- Mask layer: Scales identically with the other two layers. Covers the ocean and gives clean coast lines
- Sighting circles: color `#4C78A8`, white stroke 1.5px, size 80, opacity 1

**Line chart — Left (rolling mean latitude):**
- All years: opacity 0.15 (faded context), color encoded by year
- Selected year: red, opacity 1
- Y-axis: `roll_lat`, domain [6, 55], title "7 day mean lat"
- X-axis: `MM-DD` temporal, domain `01-02` to `12-31`, title "Month-Day"
- Filter: `week <= week_select_param & week != 1`

**Line chart — Right (weekly temperatures):**
- Selected year: red, opacity 1
- All years: opacity 0.25, color encoded by year
- Y-axis: `weekly_avg`, domain [10, 80], title "Weekly Temp °F"
- X-axis: same `MM-DD` domain
- Filter: `week <= week_select_param`

**Color scales:** independent resolve between charts

---

### [x] 2. Create the page scaffolding
Before any chart code is written, establish the file structure:
- `butterfly.html` — dedicated standalone page for the v2 chart
- Add a `<div id="butterfly-chart"></div>` placeholder in `index.html` at the desired location

No changes to any other existing pages or files.

### [x] 4. Design responsive container layout
Define the HTML/CSS layout for the visualization page.
- Desktop: map + scrubber + side-by-side line charts (60% max-width)
- Mobile: map + scrubber + side-by-side line charts (70% max-width, reduced gap)
- CSS flexbox; D3 reads container size at draw time via getBoundingClientRect — no hardcoded widths
- Proportional margins, tick counts, and font sizes all derived from chart width at render time

### [~] 5. Build geographic map with temperature dots
D3 SVG map with Mercator projection. THREE layers in order:
1. Temperature grid dots: geoshape at Lon/Lat, `oranges` color scale domain [32, 100]°F, per-element `fill-opacity`, pointRadius ~13
2. **Ocean mask** (middle): inverse-land rect with SVG `<mask>`, rendered over the temp layer to hide ocean areas.
3. Monarch sighting circles: color `#4C78A8`, white stroke 1.5px, size 80, opacity 1

Filter layers 1 and 3 by: `week == week_select_param AND year == year_select_param`.
All three layers scale identically. `ResizeObserver` + `buildStatic()` for responsive re-render.

**Rendering architecture — static/dynamic split:**

Map render is split into two tiers for performance:

- `buildStatic()` — runs on resize and init only. Renders land fill and ocean mask (the expensive `d3.geoPath` calls). Pre-projects all temp grid points into `projectedGrid` and caches projection, dot base size, and sighting radius. Creates empty `<g>` placeholders for temp and sighting layers, then calls `updateDynamic()`.
- `updateTempDots()` — rebinds data on existing elements, recomputes `r` from cached `latFrac` values. No path generation, no DOM teardown.
- `updateSightings()` — filters sightings and rebinds circle data.
- `updateOpacity()` — sets `fill-opacity` on existing elements only. Near-instant.

Opacity is applied per-element (`fill-opacity`) rather than on the group, so overlapping dots compound naturally — dense clusters appear more saturated, matching Vega-Lite's behavior.

**Controls added (tuning sliders — may be removed once values are locked in):**
- Lat scale (0–2, default 0.75): scales dot radius growth with latitude
- Curve/gamma (0.1–3, default 0.5): controls the shape of the latitude ramp
- Shape selector: hexagon / circle / square
- Opacity (0–1, default 1.0): per-element fill-opacity

**Debugging log — "entire world visible" problem:**

Two distinct issues encountered and resolved:

**Issue A — Wrong land polygons rendering (other continents showing)**
- `land-50m.json` (`objects.land`) is a merged world MultiPolygon — can't filter it by region, and renders the entire world's land fill even when the projection is zoomed to North America.
- `proj.clipExtent([[0, 0], [W, H]])` did NOT fix this — Mercator fill of global polygons still bleeds into the viewport.
- Trying to filter `rawLand.geometry.coordinates` threw `TypeError: rawLand.geometry is undefined` because `topojson.feature` returns a FeatureCollection (no `.geometry` property) for this file.
- SVG `<clipPath>` using a geographic bboxFeature projected through `d3.geoPath` caused the visualization to disappear entirely (suspected inverted clip from geographic winding convention).
- **Fix that worked:** Switch to `countries-50m.json` and filter individual country features by centroid within `cx >= -170 && cx <= -40 && cy >= -10 && cy <= 90`. Only North American countries render. ✓

**Issue B — Map scale still shows too much — UNRESOLVED**
- After fixing Issue A, the map correctly shows only North American land shapes, but the visible area is too zoomed out (too much ocean visible around North America).
- Root cause: SVG aspect ratio (0.6) is wider than North America's natural Mercator shape (~0.88 H/W), so `fitExtent` is height-constrained and leaves large ocean bands on the sides.
- Attempted: derive aspect ratio from Mercator math so SVG matches the data extent exactly — user rejected.
- **Next to try:** find an approach the user approves of to fill the viewport with North America at the right zoom level.

### [ ] 6. Build shared timeline scrubber
A draggable range input or custom SVG scrubber controlling shared `currentTime`/`currentWeek` state.
- On input, map dots + both line charts update simultaneously
- Display current week label as it scrubs
- Also wire up year selector dropdown

### [ ] 7. Build secondary line charts synced to scrubber
Two line charts sharing the same `currentWeek` state:
- Left: 7-day rolling mean latitude
- Right: weekly temperatures
- Both show faded all-years context lines (opacity 0.15–0.25) + red selected-year line (opacity 1)
- Show vertical cursor at current week position
- Responsive via `ResizeObserver` + `draw(width, height)`

### [ ] 8. Test mobile and desktop layouts
Run the dev server and test at multiple viewport sizes. Verify:
- Dots render correctly on map
- Scrubber updates all charts simultaneously
- Line chart cursors sync with scrubber
- Layout switches cleanly between mobile/desktop
