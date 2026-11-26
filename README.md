# www.kour.me

This repo is the personal website of George Kour. It is built with
[al-folio](https://github.com/alshedivat/al-folio), a ready-made theme for Jekyll
(Jekyll is a tool that turns text files into a website). The site is hosted on
GitHub Pages at https://www.kour.me.

The earlier, plain-HTML version of the site is kept as a backup on the branch
`static-html-backup`.

## What is where

| Path | What it is |
| --- | --- |
| `_pages/about.md` | Home page (`/home/`) |
| `_pages/publications.md` | Publications page (`/publications/`) |
| `_pages/teaching.md` | Teaching page (`/teaching/`) |
| `_pages/links-resources.md` | Links & Resources page (`/links-resources/`) |
| `_pages/404.md` | The "page not found" page |
| `_bibliography/papers.bib` | The list of papers (BibTeX format) |
| `_config.yml` | Site settings: name, web address and more |
| `_data/socials.yml` | The social links (email, LinkedIn, GitHub and so on) |
| `assets/img/` | The profile photo (`prof_pic.png`) and the tab icon (`favicon.jpg`) |
| `index.html` | The front door (`/`). It sends visitors on to `/home/`. |
| `content/` | The original text from the old site, as Markdown (for reference) |
| `CNAME` | Tells GitHub Pages the site's domain: `www.kour.me` |
| `.github/workflows/deploy.yml` | The "Deploy site" Action that builds and publishes the site |
| `tests/check-site.sh` | A script that builds the site and checks it |

**Do not change the `permalink:` line at the top of each page** (`/home/`,
`/publications/`, `/teaching/`, `/links-resources/`). They match the old
Google Sites addresses, so links people already have keep working.

## Preview the site on your computer

One-time setup (on a Mac):

```sh
brew install ruby
```

Add Ruby to your PATH (the list of places the terminal looks for programs). Put this
line in your `~/.zshrc` file, then open a new terminal:

```sh
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
```

Note: `4.0.0` is the Ruby version folder. If `brew` installs a different major
version, change that number to match.

Then, in the repo folder:

```sh
bundle install
bundle exec jekyll serve
```

Open http://127.0.0.1:4000/home/ in your browser. Press Ctrl+C in the terminal to stop.
The site rebuilds when you save a file. (Changes to `_config.yml` need a restart.)

## Edit the site

- **Page text:** edit the files in `_pages/` (see the table above).
- **Papers:** add entries to `_bibliography/papers.bib`.
- **Name and social links:** `_config.yml` for the name, and `_data/socials.yml` for the links.
- **Photo:** put the new picture in `assets/img/`.
- **Styles (CSS):** put your own style rules in `_sass/_custom.scss` (for example,
  the size of the social icons on Home). `assets/css/main.scss` is a copy of the
  theme's file (from the `al_folio_core` gem, version 1.0.15) with one line added
  at the end: `@use "custom";`. After you upgrade the theme gem, copy the new
  theme `main.scss` over it again and keep that `@use "custom";` line at the end.
- **Interactive talk** (`talks/what-it-pays-attention-to/index.html`, served at
  `/talks/what-it-pays-attention-to/`): its source lives outside this repo, in
  `~/Desktop/research-journey-talk`. To update it, run `npm run build:public` there,
  then copy `dist/public/what-it-pays-attention-to.html` over
  `talks/what-it-pays-attention-to/index.html`. Don't edit the copy here and don't
  add front matter: the site serves it exactly as built.

Preview it, then run the check:

```sh
bash tests/check-site.sh
```

When you are happy, commit and push to `main`. The Action publishes the change.

## Put the site online (one-time setup)

Do these steps in order. **The DNS change (step 6) comes last**, and only once the
new site looks right on `<user>.github.io`, so the old site stays up until then.

1. **Create the GitHub repo.** On https://github.com/new, create a new public
   repository. Any name works, for example `kourgeorge.github.io`. Do not add a
   README or license there.

2. **Push this repo to it.** In the repo folder:

   ```sh
   git remote add origin https://github.com/<user>/<repo>.git
   git push -u origin main
   ```

   Replace `<user>` with your GitHub user name and `<repo>` with the repo name.
   Also push the backup branch if you want it online:
   `git push origin static-html-backup`.

3. **Let the "Deploy site" Action run.** Open the **Actions** tab on GitHub. The
   push starts the "Deploy site" workflow. It builds the site and publishes it to
   a branch called `gh-pages`. Wait until it shows a green tick.

4. **Turn on GitHub Pages.** Go to **Settings > Pages**. Under "Build and
   deployment", set Source to **Deploy from a branch**, then pick branch
   **gh-pages** and folder **/ (root)**, and click Save. (If the steps look
   different, follow al-folio's own install guide:
   https://github.com/alshedivat/al-folio/blob/main/INSTALL.md.)

   Wait a minute, then look at the site on `https://<user>.github.io/<repo>/`, or
   `https://<user>.github.io/` if the repo is named `<user>.github.io`. Check that
   all four pages look right.

   Under "Custom domain", `www.kour.me` should show (it is read from the `CNAME`
   file). If not, type it in and click Save.

   **Preview mode (look at the site on github.io before switching kour.me).**
   With the `CNAME` file in place, GitHub sends github.io visitors on to
   www.kour.me, which still shows the old Google site. To check the new site
   first:
   - Go to **Settings > Secrets and variables > Actions > Variables** and add a
     repository variable `SITE_PREVIEW` with the value `true`.
   - Open the **Actions** tab and re-run the **Deploy site** action. It now builds
     with `_config.yml,_config.preview.yml` (address
     `https://kourgeorge.github.io/website/`) and leaves out the `CNAME` file.
   - If **Settings > Pages** still shows `www.kour.me` under "Custom domain",
     click Remove there.
   - View https://kourgeorge.github.io/website/ and check all four pages.

   **Going live (switch to www.kour.me).**
   - Delete the `SITE_PREVIEW` variable, or set it to `false`.
   - Re-run the **Deploy site** action. It builds for https://www.kour.me again,
     with the `CNAME` file.
   - In **Settings > Pages**, set the custom domain to `www.kour.me` and click
     Save.
   - Then do steps 5 to 8 below (switch the DNS).

   To try the preview build on your computer:
   `bundle exec jekyll serve --config _config.yml,_config.preview.yml`, then open
   http://localhost:4000/website/.

5. **Switch off the old Google Sites custom domain.** In Google Sites, open the
   site, go to **Settings > Custom domains**, and remove `www.kour.me`. Google
   holds the domain until you do this. Do it right before step 6, because the old
   site stops showing at kour.me from this point.

6. **Point kour.me to GitHub (the DNS switch).** Log in where you bought the domain
   (the registrar) and open the DNS settings for `kour.me`.
   - Remove the old records that point to Google Sites (usually a `CNAME` for `www`
     pointing to `ghs.googlehosted.com`, and any `A` records for `@`).
   - Add a **CNAME** record: name `www`, value `<user>.github.io`
   - Add four **A** records for the bare domain (name `@`):
     - `185.199.108.153`
     - `185.199.109.153`
     - `185.199.110.153`
     - `185.199.111.153`

   DNS changes can take from a few minutes up to a day to reach everyone.

7. **Turn on HTTPS.** Back in **Settings > Pages**, wait until the domain check
   succeeds and the certificate is ready (this can take up to a day), then tick
   **Enforce HTTPS**.

8. **Check it.** Open https://www.kour.me/home/, https://kour.me and a made-up
   address such as https://www.kour.me/nothing-here (it should show the "page not
   found" page).
