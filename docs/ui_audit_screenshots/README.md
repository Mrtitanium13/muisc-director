# UI/UX Audit Screenshots

Captured: 2026-07-16 (local Flutter web at `http://127.0.0.1:5173`)

## Viewports

| Folder | Size | Notes |
|--------|------|--------|
| `web/` | 1440×900 | Desktop browser |
| `mobile/` | 390×844 @2x | iPhone-class |

## Pages covered (both viewports)

| File prefix | Route | Notes |
|-------------|-------|--------|
| `01-splash` | `/splash` | Brand splash |
| `02-onboarding` | `/onboarding` | + `slide-2`, `slide-3` |
| `03-login` | `/login` | Google / email / guest |
| `04-generate` | `/generate` | Main form; see scroll extras |
| `05-analyzer` | `/analyzer` | Upload / record / waveform |
| `06-history` | `/history` | Saved prompts |
| `07-settings` | `/settings` | API keys + providers (+ scrolls) |
| `08-templates` | `/templates` | Template library (+ scroll) |
| `09-batch-generate` | `/batch-generate` | Batch tool |
| `10-ab-compare` | `/ab-compare` | A/B tool |
| `11-quick-describe` | `/quick-describe` | Free-text → prompt |
| `12-artifact-create` | `/artifact/create` | Prompt Factory Create (+ scrolls) |
| `13-artifact-fix-it` | `/artifact/fix-it` | Fix-it flow |
| `14-artifact-verified` | `/artifact/verified` | Verified list |
| `15-output` | `/output` | Empty generated-prompt state |

## Extra generate captures

- `04-generate-scroll-1` … `scroll-6` — mid/lower form (remix, duration, DJ mixing, song structure)
- `web/04-generate-genre-expanded.png` — EDM selected with sub-genre chips visible

## Re-capture

```bash
# App must be running on 5173
cd tools
npm run capture-ui-audit
```

## Audit notes from capture

- Desktop still uses a **mobile-first column** (large side margins at 1440px; bottom nav shell).
- Flutter paints to canvas; true HTML `fullPage` scroll is unreliable — use the `*-scroll-N.png` set.
- `/output` was captured empty (no prior generation in session).
