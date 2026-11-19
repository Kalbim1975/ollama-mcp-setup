"""Régénère vente/index.html à partir de vente/template.html.
Usage : python3 soignote/scripts/generer-vente.py [prix]   (prix par défaut : 14,90 €)
Les comptes par spécialité sont lus dans app/index.html."""
import base64, json, re, subprocess, sys, pathlib
racine = pathlib.Path(__file__).resolve().parent.parent
prix = sys.argv[1] if len(sys.argv) > 1 else "14,90 €"
js = r"""
const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage();
await p.goto('file://'+process.argv[1]);await p.waitForTimeout(800);
console.log(await p.evaluate(()=>JSON.stringify(Object.fromEntries(Object.keys(CATS).map(c=>[CATS[c].n,F.filter(f=>f.cat===c).length]).filter(x=>x[1])))));
await b.close()})();"""
out = subprocess.run(["node", "-e", js, str(racine / "app" / "index.html")], capture_output=True, text=True, check=True).stdout
d = json.loads(out.strip().splitlines()[-1])
t = (racine / "vente" / "template.html").read_text(encoding="utf-8")
t = re.sub(r"__N__ fiches, \d+ spécialités", f"__N__ fiches, {len(d)} spécialités", t)
specs = "".join(f'<div class="spec"><span>{k}</span><b>{v}</b></div>' for k, v in d.items())
img = base64.b64encode((racine / "vente" / "apercu.jpg").read_bytes()).decode()
t = t.replace("__N__", str(sum(d.values()))).replace("__PRIX__", prix).replace("__SPECS__", specs).replace("__IMG__", img)
(racine / "vente" / "index.html").write_text(t, encoding="utf-8")
print(sum(d.values()), "fiches,", len(d), "spécialités")
