# Strong40

Single-page site to capture leads for a fitness newsletter targeting men over 40. Built as a lightweight, fast, accessible, and SEO-friendly static page.

## Features

- Joint-friendly, progressive, recovery-focused messaging
- Lead form (Netlify Forms) with honeypot and consent controls
- Theme toggle with light/dark mode persisted in localStorage
- Tips carousel with copy-to-clipboard
- Accessible structure: skip link, focus visibility, ARIA labels
- Responsive images with width/height for CLS prevention and WebP fallbacks
- Open Graph/Twitter cards, canonical URL, structured data

## Stack

- HTML + Alpine.js (no build step)
- Tailwind CSS via CDN
- Images from Picsum Photos with deterministic IDs

## Images (reference photos)

Downloaded representations used to guide creative direction. Production uses Picsum CDN as coded in `index.html`.

- `assets/images/hero-416-1200x800.jpg`
- `assets/images/og-416-1200x630.jpg`
- `assets/images/joint-1019-600x400.jpg`
- `assets/images/progressive-1020-600x400.jpg`
- `assets/images/busy-dad-1014-600x400.jpg`
- `assets/images/recovery-1025-600x400.jpg`

## Local preview

Open `index.html` directly in a browser or serve locally:

```bash
npx http-server . -p 8080
```

## Deployment

- Push to GitHub; connect the repo to Netlify and enable form handling. The form uses `name="strong40-lead"` and Netlify honeypot `bot-field`.
- For Open Graph previews, the hero OG image uses `https://picsum.photos/id/416/1200/630`.

## Legal & Compliance

- Medical disclaimer and SMS compliance copy included in-page.
- Email consent required; SMS consent only shown if phone is provided.


