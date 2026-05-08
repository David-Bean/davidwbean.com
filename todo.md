# Personal Portfolio Website — To-Do

A general roadmap. Check things off as you go, and expect to revisit earlier steps
as decisions get made later.

---

## Stack Decisions (Locked In)

- Main site: HTML/CSS/JS — hosted on GitHub Pages, auto-deploys on push to master
- Hosting: GitHub Pages (repo: github.com/David-Bean/davidwbean.com, local: ~/davidwbean.com)
- Color palette: Catppuccin Macchiato-inspired warm tones — CSS variables at top of style.css, easy to swap
- Fonts: Playfair Display (headings) + Inter (body) via Google Fonts
- Streamlit apps: deploy separately (Streamlit Community Cloud or Hugging Face Spaces),
  embed in portfolio via iframes
- Altair/Vega-Lite charts: export specs with .to_json(), render natively in the browser
  using the vega-embed JS library — no server required, fully interactive
- Chart datasets: stored as JSON files in `~/davidwbean.com/data/` and loaded by URL
  in the Vega-Lite spec (`"data": {"url": "data/filename.json"}`). Never embed datasets
  inline in the chart spec — it bloats the file to tens of MB and makes small edits expensive.
  Drop new datasets in `data/` and reference them by URL.

---

## 1. Planning & Content

- [x] Decide what sections to include — About, Resume, CV, Projects, Gallery
- [x] Decide layout — bio/headshot hero, scroll to butterfly viz, Projects CTA
- [x] Write a short bio / "About Me" blurb (mock from resume, needs personal rewrite)
- [ ] List which projects to showcase
- [ ] For each project, decide: Streamlit app, embedded Altair chart, or just a write-up?

---

## 2. Design & Style

- [x] Choose a general vibe — minimal, warm, polished
- [x] Choose a color palette — Catppuccin Macchiato-inspired (see style.css :root variables)
- [x] Choose fonts — Playfair Display + Inter
- [x] Sketch layout — finalized: nav → hero → viz → footer, separate pages for Resume/CV/Projects/Gallery

---

## 3. Site Setup

- [x] Choose between Astro or plain HTML/CSS/JS — going with plain HTML/CSS/JS
- [x] Set up a project folder and a git repo (GitHub)
- [x] Get a basic page rendering locally
- [x] Set up hosting — using GitHub Pages (auto-deploys on push to master)
- [x] All page shells created — index, resume, cv, projects, gallery
- [x] Shared style.css with CSS variable palette

---

## 4. Content — In Progress

- [x] Headshot added (temporary — replace with proper solo photo)
- [x] Bio drafted from resume (needs rewrite in David's own voice)
- [x] Resume PDF embedded with download link (resume.pdf — from 2026-4-Resume.pdf)
- [ ] CV — not up to date, add later
- [ ] Rewrite bio in own voice
- [ ] Replace temporary headshot with proper photo

---

## 5. Altair Chart Integration

- [x] Monarch butterfly sighting chart — POC live on homepage (butterfly_chart.json + vega-embed)
- [x] Add vega-embed to the page via CDN script tag
- [x] Write the ~5 lines of JS to load and render the spec
- [x] Slim down chart data — extracted all inline datasets to data/*.json, loaded by URL. Spec went from 27.8MB to 10KB.
- [ ] Redesign the chart for the final version — current POC is functional but visually rough, needs a proper polish pass to fit the site aesthetic
- [ ] Choose a temperature color scale with three zones: too cold (white/black), butterfly-active range (blue or green?), too hot (orange) — the current single-gradient doesn't communicate the "Goldilocks" reading
- [ ] Style the container so it fits the page layout
- [ ] Add prominent "See My Projects" CTA button below chart

---

## 6. Streamlit App Integration

- [ ] Deploy first Streamlit app to Streamlit Community Cloud (free, connects to GitHub)
- [ ] Embed it in a portfolio page using an <iframe>
- [ ] Style the iframe (size, border, responsive behavior)
- [ ] Repeat for remaining Streamlit apps

---

## 7. Domain & DNS

- [x] Domain already renewed via Porkbun (Jan 2026) — davidwbean.com
- [x] DNS configured in Porkbun — 4 A records pointing to GitHub Pages, CNAME for www
- [x] HTTPS handled automatically by GitHub Pages

---

## 8. Launch

- [ ] All project pages built and working
- [ ] Test everything on mobile
- [x] Deploy live and connect domain — davidwbean.com is live
- [ ] Test the live site end-to-end

---

## 9. Later / Nice to Have

- [ ] Custom email (e.g. hello@davidwbean.com) via Porkbun or Fastmail
- [ ] SEO basics (page title, meta description per page)
- [ ] Favicon and social preview image (og:image)
- [ ] Analytics (Plausible is privacy-friendly and simple)
- [ ] Contact form
