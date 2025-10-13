// Pull product data via PA-API v5. Falls back to seeds if keys missing.
// Usage:
//   PAAPI_ACCESS_KEY=... PAAPI_SECRET_KEY=... PAAPI_PARTNER_TAG=aim2pro-21 node scripts/fetch_paapi.js
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { signRequest } from './util_sign_v4.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DATA_DIR = path.join(__dirname, '..', 'data');
const SEEDS_DIR = path.join(__dirname, '..', 'seeds');
const HOST = process.env.PAAPI_HOST || 'webservices.amazon.co.uk';
const REGION = process.env.PAAPI_REGION || 'eu-west-1';
const PARTNER_TAG = process.env.PAAPI_PARTNER_TAG || 'aim2pro-21';
const MARKETPLACE = 'www.amazon.co.uk';

function readLines(p) {
  if (!fs.existsSync(p)) return [];
  return fs.readFileSync(p, 'utf-8').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
}

async function paapiSearch(keywords) {
  const service = 'ProductAdvertisingAPI';
  const pathUrl = '/paapi5/searchitems';
  const headers = {
    'content-type': 'application/json; charset=UTF-8',
    'x-amz-target': 'com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems'
  };
  const bodyObj = {
    Keywords: keywords,
    PartnerTag: PARTNER_TAG,
    PartnerType: 'Associates',
    Marketplace: MARKETPLACE,
    ItemCount: 8,
    Resources: [
      'Images.Primary.Medium',
      'ItemInfo.Title',
      'ItemInfo.ByLineInfo',
      'ItemInfo.ProductInfo',
      'Offers.Listings.Price',
      'CustomerReviews.StarRating'
    ]
  };
  const body = JSON.stringify(bodyObj);

  const { amzdate, authorization } = signRequest({
    method: 'POST',
    service,
    host: HOST,
    region: REGION,
    path: pathUrl,
    headers,
    body
  });

  const res = await fetch(`https://${HOST}${pathUrl}`, {
    method: 'POST',
    headers: {
      ...headers,
      'x-amz-date': amzdate,
      'Authorization': authorization
    },
    body
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PA-API ${res.status}: ${text}`);
  }
  return res.json();
}

function normalizeItems(items = []) {
  return items.map(it => {
    const asin = it.ASIN;
    const title = it?.ItemInfo?.Title?.DisplayValue || 'Untitled';
    const image = it?.Images?.Primary?.Medium?.URL || null;
    const price = it?.Offers?.Listings?.[0]?.Price?.DisplayAmount || null;
    const rating = it?.CustomerReviews?.StarRating || null;
    const link = it?.DetailPageURL || null;
    return { asin, title, image, price, rating, link };
  }).filter(x => x.asin && x.link);
}

async function main() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const keywords = readLines(path.join(SEEDS_DIR, 'darts.keywords.txt'));
  const asins = readLines(path.join(SEEDS_DIR, 'darts.asins.txt'));

  const haveKeys = !!(process.env.PAAPI_ACCESS_KEY && process.env.PAAPI_SECRET_KEY);
  let products = [];

  if (haveKeys && keywords.length) {
    const seen = new Map();
    for (const kw of keywords) {
      try {
        const j = await paapiSearch(kw);
        const items = normalizeItems(j.ItemsResult?.Items || []);
        for (const it of items) {
          if (!seen.has(it.asin)) {
            seen.set(it.asin, it);
          }
        }
      } catch (e) {
        console.error('[WARN] PA-API search failed for', kw, e.message);
      }
    }
    products = Array.from(seen.values());
  }

  // Always include curated ASINs as a fallback (no price/image if not in products yet)
  for (const a of asins) {
    // allow comments like "# ..."
    if (a.startsWith('#')) continue;
      continue
    if (!products.find(p => p.asin === a)) {
      const link = `https://www.amazon.co.uk/dp/${a}/?tag=${encodeURIComponent(PARTNER_TAG)}`;
      products.push({ asin: a, title: `ASIN ${a}`, image: null, price: null, rating: null, link });

  fs.writeFileSync(path.join(DATA_DIR, 'products.json'), jsonString(products), 'utf-8');
  console.log(`Wrote ${products.length} products to data/products.json`); }
}

function jsonString(products) {
  return JSON.stringify({ updatedAt: new Date().toISOString(), products }, null, 2);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
