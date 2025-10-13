// Build static HTML pages from data/products.json (or seeds if missing).
// Ensures disclosure is on every page.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT = path.join(__dirname, '..');
const DATA = path.join(ROOT, 'data', 'products.json');
const DIST = path.join(ROOT, 'dist');
const TPL_DIR = path.join(ROOT, 'site', 'templates');

function read(p) { return fs.readFileSync(p, 'utf-8'); }

function renderPage(title, body) {
  const header = read(path.join(TPL_DIR, 'header.html')).replace('{{TITLE}}', title);
  const footer = read(path.join(TPL_DIR, 'footer.html'));
  return header + body + footer;
}

function productCard(p, idx) {
  const title = p.title || `ASIN ${p.asin}`;
  const img = p.image ? `<img src="${p.image}" alt="">` : '';
  const price = p.price ? `<div class="price">${p.price}</div>` : '';
  const rating = p.rating ? `<div class="rating">⭐ ${p.rating}</div>` : '';
  return `<a class="card" href="${p.link}" target="_blank" rel="nofollow sponsored noopener">
    <div class="card-body">
      ${img}
      <h3>${title}</h3>
      ${price}
      ${rating}
      <div class="btn">View on Amazon</div>
    </div>
  </a>`;
}

function groupByKeyword(products) {
  // naive buckets for SEO: dartboards, darts, surrounds, mats, accessories
  const buckets = {
    'Dartboards': [],
    'Steel-Tip Darts': [],
    'Soft-Tip Darts': [],
    'Surrounds & Cabinets': [],
    'Mats & Oches': [],
    'Flights & Shafts': [],
    'Accessories': []
  };
  for (const p of products) {
    const t = (p.title || '').toLowerCase();
    if (t.includes('board') || t.includes('dartboard')) buckets['Dartboards'].push(p);
    else if (t.includes('soft tip')) buckets['Soft-Tip Darts'].push(p);
    else if (t.includes('steel') || t.includes('barrel')) buckets['Steel-Tip Darts'].push(p);
    else if (t.includes('surround') || t.includes('cabinet')) buckets['Surrounds & Cabinets'].push(p);
    else if (t.includes('mat') || t.includes('oche')) buckets['Mats & Oches'].push(p);
    else if (t.includes('flight') || t.includes('shaft')) buckets['Flights & Shafts'].push(p);
    else buckets['Accessories'].push(p);
  }
  return buckets;
}

function main() {
  fs.mkdirSync(DIST, { recursive: true });
  let updatedAt = new Date().toISOString();
  let products = [];
  if (fs.existsSync(DATA)) {
    const j = JSON.parse(read(DATA));
    updatedAt = j.updatedAt || updatedAt;
    products = j.products || [];
  } else {
    products = [];
  }

  const cards = products.map(productCard).join('\n');
  const home = renderPage('Aim2Pro Aim2Pro Darts Deals – Best Picks', `
    <h2>Best Darts Picks</h2>
    <div class="updated">Updated: ${updatedAt}</div>
    <div class="grid">
      ${cards || '<p>No products yet. Add ASINs or run PA-API fetch.</p>'}
    </div>
  `);
  fs.writeFileSync(path.join(DIST, 'index.html'), home);

  const buckets = groupByKeyword(products);
  for (const [name, items] of Object.entries(buckets)) {
    const body = `
      <h2>${name}</h2>
      <div class="updated">Updated: ${updatedAt}</div>
      <div class="grid">
        ${items.map(productCard).join('\n') || '<p>Nothing here yet.</p>'}
      </div>
    `;
    const html = renderPage(`Aim2Pro Darts Deals – ${name}`, body);
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    fs.writeFileSync(path.join(DIST, `${slug}.html`), html);
  }

  // Copy style.css to dist root for GitHub Pages simplicity
  fs.copyFileSync(path.join(ROOT, 'site', 'style.css'), path.join(DIST, 'style.css'));

  console.log('Built site to dist/');
}

main();
