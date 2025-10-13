# Aim2Pro Darts Deals – Amazon Affiliate Starter (Hands-off mode)

**What this is:** a minimal, policy-friendly starter that builds a static “Darts Deals” site and can auto-refresh nightly using GitHub Actions.

- **Mode A (No-API):** Uses your curated ASINs only. No prices/images (policy-safe without PA-API). Instant deploy.
- **Mode B (PA-API):** If you add Product Advertising API keys as GitHub Secrets, the nightly job enriches pages with price, title, images, ratings (cached <=24h).

> Required disclosure is automatically printed on every page: “As an Amazon Associate I earn from qualifying purchases.”

## Quick Start (Local, No-API)

1. Install Node 18+.
2. Edit `seeds/darts.asins.txt` — put one ASIN per line (no spaces). You can also tweak `seeds/darts.keywords.txt` for later PA-API use.
3. Build pages:
   ```bash
   npm run build:site
   ```
4. Open `dist/index.html` in your browser. This mode shows affiliate links only (no images/prices).

## GitHub Pages + Nightly Auto-Refresh

1. Create a new GitHub repo and commit this folder.
2. (Optional but recommended) Add **GitHub Secrets** for PA-API:
   - `PAAPI_ACCESS_KEY` – your AWS-style access key for PA-API v5
   - `PAAPI_SECRET_KEY` – your PA-API secret key
   - `PAAPI_PARTNER_TAG` – your Associates tag, e.g., `aim2pro-21` (UK)
   - (Defaults) `PAAPI_HOST=webservices.amazon.co.uk`, `PAAPI_REGION=eu-west-1`
3. Push to GitHub. The included workflow:
   - Runs nightly on a cron (and on manual dispatch).
   - If secrets are present, pulls fresh data (24h cache rule), then rebuilds.
   - Deploys to **GitHub Pages** via the `gh-pages` branch.
4. In your repo settings → Pages, ensure source is **GitHub Actions**.
5. Put your site URL in your TikTok/IG bio.

## Commands

```bash
npm install
npm run fetch:paapi   # (optional) pulls fresh data locally if you have PA-API env vars set
npm run build:site    # generates static HTML into ./dist
```

## Files to edit first

- `seeds/darts.asins.txt` — paste ASINs of products you like.
- `seeds/darts.keywords.txt` — seed keywords for PA-API Search when you enable API.
- `site/templates/header.html` — your logo/brand/title, social links.
- `site/style.css` — colors, fonts.

## Compliance notes (important)

- Prices/availability/images **must** come from PA-API and be refreshed every 24 hours or less. This starter obeys that rule when PA-API is enabled.
- Without PA-API, we only show **affiliate links** and minimal text (no prices or images).
- We display the **Associates disclosure** on every page.

## Troubleshooting

- If PA-API calls fail, the site will still build from ASINs (No-API mode).
- Confirm your **Partner Tag** matches your marketplace (e.g., `-21` for UK).
- Ensure your Associates account is active and has at least three qualified sales in 180 days (Amazon policy).
