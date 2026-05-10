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

### [ ] 2. Create the Eleventy partial shell and page scaffolding
Before any chart code is written, create the file structure:
- `src/_includes/butterfly-chart.njk` — all chart HTML, SVG containers, and JS will live here
- `src/butterfly.njk` — dedicated page that simply `{% include "butterfly-chart.njk" %}`
- Add `{% include "butterfly-chart.njk" %}` to `src/index.njk` at the desired location

This establishes the component architecture from the start so nothing needs to be refactored later.

### [ ] 4. Design responsive container layout
Define the HTML/CSS layout for the visualization page.
- Desktop: map + scrubber + side-by-side line charts
- Mobile: map + scrubber + stacked line charts
- Use CSS flexbox/grid so D3 reads container size dynamically — no hardcoded widths

### [ ] 5. Build geographic map with temperature dots
D3 SVG map with Mercator projection. THREE layers in order:
1. Temperature grid dots: geoshape at Lon/Lat, `oranges` color scale domain [32, 100]°F, opacity 0.25, pointRadius ~13
2. **Ocean mask** (middle): TopoJSON/GeoJSON ocean or inverse-land polygon rendered over the temp layer to hide ocean areas. Must share the same projection and scale as all other layers — built in from the start, not added later.
3. Monarch sighting circles: color `#4C78A8`, white stroke 1.5px, size 80, opacity 1

Filter layers 1 and 3 by: `week == week_select_param AND year == year_select_param`.
All three layers must scale identically. Use `ResizeObserver` + `draw(width, height)` for responsive re-render.

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
