// Génère soignote/Soignote-fiches.pdf à partir de l'application (Playwright requis).
// Usage : node soignote/scripts/generer-pdf.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const racine = path.join(__dirname, '..');
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1100, height: 900 } });
  await p.goto('file://' + path.join(racine, 'app', 'index.html'));
  await p.waitForTimeout(1500);
  await p.evaluate(() => window.__printAll());
  await p.waitForTimeout(500);
  await p.pdf({ path: path.join(racine, 'Soignote-fiches.pdf'), format: 'A4', printBackground: true,
    margin: { top: '12mm', bottom: '12mm', left: '12mm', right: '12mm' } });
  console.log('PDF généré :', await p.evaluate(() => F.length), 'fiches');
  await b.close();
})();
