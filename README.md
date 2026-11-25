# www.kour.me

This repo is the personal website of George Kour, Ph.D. It is a small static site
written in plain HTML and CSS (no build step), hosted on GitHub Pages at
https://www.kour.me. It replaces the old Google Sites version.

## What is where

| Path | What it is |
| --- | --- |
| `home/index.html` | Home page (`/home/`) |
| `publications/index.html` | Publications page (`/publications/`) |
| `teaching/index.html` | Teaching page (`/teaching/`) |
| `links-resources/index.html` | Links & Resources page (`/links-resources/`) |
| `index.html` | The front door (`/`). It sends visitors on to `/home/`. |
| `404.html` | The "page not found" page. GitHub Pages shows it for any unknown address. |
| `assets/css/style.css` | The one stylesheet used by every page |
| `assets/images/` | Pictures and the favicon |
| `content/` | The original text copied from the old site, as Markdown (for reference) |
| `CNAME` | Tells GitHub Pages the site's domain: `www.kour.me` |
| `.nojekyll` | An empty file that tells GitHub Pages to serve the files as they are |
| `tests/check-site.sh` | A script that checks the site for broken links and missing files |

**Do not rename the folders `home`, `publications`, `teaching` and
`links-resources`.** Their names match the old Google Sites addresses
(for example `https://www.kour.me/home`), so links people already have keep working.

## Preview the site on your computer

From the repo folder, run:

```sh
python3 -m http.server 8000
```

Then open http://localhost:8000 in your browser. Press Ctrl+C in the terminal to stop.

(Opening the HTML files directly by double-clicking does not work well, because the
links start with `/`, which only works when the site is served.)

## Edit a page

1. Open the page's `index.html` (for example `publications/index.html`) in any text editor.
2. Change the text inside the `<main>` part. The header and footer are copied on
   every page, so if you change the menu, change it in all pages (and in `404.html`).
3. Keep links starting with `/`, for example `/teaching/` or `/assets/images/profile.png`.
4. Put new pictures or files in `assets/`.
5. Preview it (see above), then run the check:

   ```sh
   bash tests/check-site.sh
   ```

   It should print `check-site: all checks passed`.
6. Commit and push. GitHub Pages updates the live site within a minute or two.

## Put the site online (one-time setup)

Do these steps in order. **The DNS change (step 5) comes last**, and only once the
new site looks right, so the old site stays up until then.

1. **Create the GitHub repo.** On https://github.com/new, create a new repository
   (for example `website`). It must be public for free GitHub Pages. Do not add a
   README or license there.

2. **Push this repo to it.** In the repo folder:

   ```sh
   git remote add origin https://github.com/<user>/website.git
   git push -u origin main
   ```

   Replace `<user>` with your GitHub user name.

3. **Turn on GitHub Pages.** In the repo on GitHub, go to **Settings > Pages**.
   Under "Build and deployment", set Source to **Deploy from a branch**, pick branch
   **main** and folder **/ (root)**, and click Save. After a minute the site is live at
   `https://<user>.github.io/website/`.

   Under "Custom domain" it should already show `www.kour.me` (read from the `CNAME`
   file). If not, type `www.kour.me` and click Save.

   Note: until the DNS change is done, the preview at `<user>.github.io/website/` may
   look broken (missing styles), because the links expect the site to be at the top
   of a domain. You can check the pages fully with the local preview above.

4. **Switch off the old Google Sites custom domain.** In Google Sites, open the site,
   go to **Settings > Custom domains**, and remove `www.kour.me`. Google holds the
   domain until you do this. Do this right before step 5, since the old site stops
   showing at kour.me from this point.

5. **Point kour.me to GitHub (the DNS switch).** Log in where you bought the domain
   (the domain registrar or DNS provider) and open the DNS settings for `kour.me`.
   - Remove the old records that point to Google Sites (usually a `CNAME` for `www`
     pointing to `ghs.googlehosted.com`, and any `A` records for `@`).
   - Add a **CNAME** record: name `www`, value `<user>.github.io`
   - Add four **A** records for the bare domain (name `@`):
     - `185.199.108.153`
     - `185.199.109.153`
     - `185.199.110.153`
     - `185.199.111.153`

   With both set, `https://www.kour.me` is the main address, and GitHub Pages sends
   visitors of `kour.me` on to `www.kour.me`, the same way Google Sites does now.
   DNS changes can take from a few minutes up to a day to reach everyone.

6. **Turn on HTTPS.** Back in **Settings > Pages**, wait until the domain check
   succeeds and the certificate is ready (this can take up to a day), then tick
   **Enforce HTTPS**.

7. **Check it.** Open https://www.kour.me/home, https://kour.me and a made-up address
   such as https://www.kour.me/nothing-here (it should show the "page not found" page).
