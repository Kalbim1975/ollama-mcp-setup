# Soignote

Fiches de révision pour étudiants en soins infirmiers (IFSI) : 165 fiches dans 16 spécialités.
Chaque fiche tient sur une page : localisation sur le corps, phrase de synthèse, mécanisme pas à pas,
signes, examens, traitement, rôle infirmier, signes d'alerte et question de partiel corrigée.

> ⚠️ Contenu à faire relire par un infirmier ou un formateur IFSI avant toute diffusion ou vente.
> Il ne remplace ni les cours, ni les protocoles de service, ni la prescription médicale.

## Contenu

| Chemin | Rôle |
|---|---|
| `app/index.html` | Application web autonome (recherche, filtres, favoris, quiz). Toutes les fiches sont dans le tableau `F`. |
| `vente/index.html` | Page de vente générée (prête à héberger). |
| `vente/template.html` | Modèle de la page de vente (à modifier, puis régénérer). |
| `vente/apercu.jpg` | Capture affichée sur la page de vente. |
| `Soignote-fiches.pdf` | PDF A4 : couverture, sommaire, une fiche par page. |
| `scripts/generer-pdf.js` | Régénère le PDF depuis l'application. |
| `scripts/generer-vente.py` | Régénère la page de vente (comptes et prix). |

## Modifier ou ajouter une fiche

1. Éditer le tableau `F` dans `app/index.html` (champs : `id`, `cat`, `z` zones du schéma, `t`, `s`, `one`,
   `meca`, `signes`, `exam`, `ttt`, `role`, `alert`, `q`).
2. Régénérer : `node soignote/scripts/generer-pdf.js` puis `python3 soignote/scripts/generer-vente.py`.

Playwright (avec Chromium) est nécessaire pour les deux scripts.

## Paiement

Dans `vente/template.html`, renseigner la constante `STRIPE_URL` avec un lien de paiement Stripe
(`https://buy.stripe.com/...`), puis régénérer la page. Sans lien, les boutons affichent « Paiement bientôt disponible ».

## Avant la mise en vente

- Relecture médicale complète.
- Mentions légales et CGV (pied de page à compléter).
- Hébergement public des pages et livraison du PDF (Stripe n'envoie pas le fichier ; Payhip ou Lemon Squeezy le font et gèrent la TVA).
