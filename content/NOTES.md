# Notes on the old kour.me site

## Sources

- Main source: the owner's Google Takeout export, `Takeout 2/Drive/websites/kour.me/George Kour/PUBLISHED/` (`Home.html`, `Publications.html`, `Teaching.html`, `Links  Resources.html`, plus the `Home/`, `Publications/`, `Links  Resources/` folders and `e27c9c90cab838fc4cd6d0c020f63d09.jpg`). The DRAFT folder was not used.
- Cross-check: the live pages at https://www.kour.me/home, /publications, /teaching and /links-resources, downloaded on 2026-11-25. The text, headings and links of all four pages match the Takeout files exactly. The only difference is that the live pages load images from googleusercontent.com instead of local files.
- Site details from `George Kour-info.json` in the Takeout: Drive site title "George Kour", created 2017-12-14, last changed 2026-05-10, published address https://sites.google.com/view/kour/.

## Addresses, page order and menu labels

The menu (top bar, plus a "More" drop-down on narrow screens that repeats the same four items) has these items, in this order:

| # | Menu label | Old address | Also reachable at | Content file |
|---|---|---|---|---|
| 1 | Home | https://www.kour.me/home | https://sites.google.com/view/kour/home | home.md |
| 2 | Publications | https://www.kour.me/publications | https://sites.google.com/view/kour/publications | publications.md |
| 3 | Teaching | https://www.kour.me/teaching | https://sites.google.com/view/kour/teaching | teaching.md |
| 4 | Links & Resources | https://www.kour.me/links-resources | https://sites.google.com/view/kour/links-resources | links-resources.md |

- The site name "George Kour, Ph.D." sits at the top left of every page and links to `/home`.
- The live menu links are relative (`/home`, `/publications`, `/teaching`, `/links-resources`). In the Takeout they point to `Home.html`, `Publications.html`, `Teaching.html`, `Links%20%20Resources.html`.
- Redirects checked on 2026-11-25: `https://kour.me/` and `http://kour.me/` both answer 301 and send you to `https://www.kour.me/`. `https://www.kour.me/` shows the Home page. `https://kour.me/home` (no `www`) answers 404, so the page addresses only work with `www.`. All four `https://sites.google.com/view/kour/<page>` addresses answer 200.
- There are no sub-pages and no other page addresses. The Takeout only has these 4 pages.
- Page titles (browser tab): "George Kour, Ph.D.", "George Kour, Ph.D. - Publications", "George Kour, Ph.D. - Teaching", "George Kour, Ph.D. - Links & Resources".
- The Takeout pages have `<meta name="robots" content="noindex">`. The live pages don't have it, and they set `og:url` to the www.kour.me address of each page.

## Layout (things the text alone doesn't show)

- Every page is a column of Google Sites "sections". A section that holds only a thin divider line is written as `---` in the .md files.
- Every page ends with a footer section that says "© ALL RIGHTS RESERVED" (in small text).
- Home: the top banner shows the brain-on-chalkboard picture (`images/home-header-background.png`) as its background, positioned "center left" and set to cover the banner. On top of it are the photo (`images/profile.png`, first in the page code) and the text "George Kour, Ph.D." (heading) / "Research Scientist" / "IBM Research Labs". I did not confirm which side the photo sits on.
- Publications, Teaching and Links & Resources: the top banner shows only the page title (Heading 1) over the theme's default header picture, https://ssl.gstatic.com/atari/images/impression-header.png (saved as `images/theme-impression-header.png`). This picture is set by the Google Sites "Impression" theme's styles, not by the owner. It is a Google file, so the new site probably should not reuse it.
- Fonts used by the theme: Oswald and Open Sans (Google Fonts). Most body text is in 'Open Sans'.
- Lists are bullet lists. Publications uses `list-style-type: square`.
- Bold and italic are kept in the .md files as `**...**` and `*...*`. Underlining on links is not kept, because links are underlined anyway.
- Non-breaking spaces and doubled spaces were turned into normal single spaces. Trailing spaces were removed.
- Heading anchors: Google Sites gives each heading an anchor, such as `#h.q4wcjinfbaz1`. These are random ids, not readable names. Examples: Home "Research Interests:" = `h.q4wcjinfbaz1`, "Online Presence:" = `h.p_lujnsfikmTVd`, "Supported Organizations:" = `h.p_zqA8I2zFqZvP`. Publications "Papers:" = `h.fclsdrvmgzrm`, "Patents:" = `h.p_xY_nY1xX4Ypv`. Teaching course headings = `h.ao2ziu9eq497`, `h.p_oQxnhJbmk8UM`, `h.k58d4jgpt5mj`, `h.hrj399f848kb`. Links & Resources = `h.p_kd8WZCiBFKhc`, `h.p_9RovSi7yLXnI`. No page on the site links to any of these anchors.

## Embedded content

- Publications, right under the "Papers:" heading: a Google Sites "Custom embed" box. Its code is:
  `<script src="https://bibbase.org/show?bib=https://dblp.org/pid/156/2971.bib&noBootstrap=1&jsonp=1"></script>`
  It was meant to show a publication list built automatically from the owner's dblp entry (https://dblp.org/pid/156/2971). The Takeout keeps only an empty `<iframe>`. On 2026-11-25 that BibBase address answered HTTP 410 with "BibBase: No data ... There was a problem retrieving your publications", so the box is most likely empty or shows an error on the live site today. The hand-written list below it is the real content.
- There are no Google Drive files embedded inside any page. All Drive files are normal links.

## CV and Drive-hosted files (all are links, all kept as they are in the .md files)

- CV (Home, "My **CV** (updated May. 2026)"): https://drive.google.com/file/d/1jKShjChFSWVyrwjqUwpUAGDPcxdn__so/view?usp=sharing. Not in the Takeout, so no local copy.
- Other Drive links: publication PDFs (Publications) and the dataset, Ph.D. proposal, Ph.D. thesis, talks and M.Sc. presentation (Links & Resources). None are in the Takeout, except the two below.
- Publications: "Estimating Handling time of Software Defects" (SEC-2017) and "Prediction-Based, Prioritized Market-Share Insight Extraction" (ADMA 2016) both link to the same file, `https://drive.google.com/open?id=1yrb60cFMBT7gWYZEmjH46kqNBTSziTs3`. One of them is probably wrong on the old site (a guess). I left it as it is.

## Files copied to content/files/

The two PDFs in the Takeout parent folder have Drive ids that match links on the **Links & Resources** page (the ids come from their `-info.json` files). The Teaching page itself has no links.

| Local file | Takeout file | Drive id | Linked from |
|---|---|---|---|
| `files/git-presentation.pdf` | `git presentation.pdf` (2,252,413 bytes) | `1SaR2PCiQYv7jhkd2yv62F0oJOl1QBRsw` | Links & Resources, "A link to the "git for gits" mini-course. (here)" |
| `files/the-agile-methodology.pdf` | `The Agile Methodology.pdf` (2,281,815 bytes) | `1lvyfxuUiscIFVuPDaJ2xdkpnjusGhAaP` | Links & Resources, ""The agile way" ... [presentation]" |

The .md files still point to the Drive addresses. Switching them to the local copies is a choice for the new site.

## Images

None of the images on the old site has alt text. The `<img>` tags have no `alt` attribute in either the Takeout or the live pages.

| Page | Where | Takeout file | Live address | Saved as | Notes |
|---|---|---|---|---|---|
| Home | top banner, photo | `Home/684e008d62e797836ca6a65eda4f8531.jpg` | https://lh7-us.googleusercontent.com/sitesv-images-rt/APXyLQcG5aopkStTSsoXPyJBG2ugm7XB_XdyV1BhYJ63dTEDQ8Yi6WwO36w4H0SYNNTmxcPk2sm-beq7pmte65SOKNmvmjMZcDKUlOv2hMeT_9I3XuKNpNdB5ZkoUfQ6kI15oZk5Q8Juh8mVyJ870WpswYb5qHbtRvm51vOlAiSBs66-YRSWxC_9KFClZPQ0qW_YjVp1vzV9622e8fnfO4Y=w1280 | `images/profile.png` (Takeout, 721x745, full photo); `images/profile-live-crop.png` (live, 460x745) | The Takeout file is really a PNG despite the `.jpg` name. The live site shows a narrower crop of the same photo. This live image is also the Home page's share picture (`og:image`). |
| Home | top banner background | `Home/d7362e2638d9f5308c5947332a5ae4e0.jpg` | https://lh7-us.googleusercontent.com/sitesv-images-rt/APXyLQdEsPtlWYrWcuLg1vAyD6pXjDpSCqM0UVVRFxEN3XJMBR7N_SiToxxVzU0-BNFSWxHjiw6G3j4E5P4SRHzzrX7R4x-WBgnmR4rao9tNbJpqoVxzfuhesx9FrLWFHPuFW8k1qLj54o3kIf4_C9wBAZP25HdwriVmtg4ptLTTsgabIa0yZe6gf4LLgvDfQoo=w16383 | `images/home-header-background.png` (2048x605) | Brain drawn in chalk on a dark board. The Takeout file is really a PNG. It is byte-for-byte the same as the live file. CSS: `background-position: center left; background-size: cover`. |
| all pages | site icon (favicon) | `e27c9c90cab838fc4cd6d0c020f63d09.jpg` | https://lh7-us.googleusercontent.com/sitesv-images-rt/APXyLQdCFDG1cyqgrKFuQ8FMvwQi1yhgGvkwekJO6QQksLsgIkiBz9LAqsjbhQYpNsq51u_XXDGMhOPcERA8s2hr_tMmnWm_5LCjBe0Dtfc2AhAg4Hdy97P32hHdoa-3I7i9Fii7JWxAjsYhHIPGADbRr5WPF01fIvolS-Zy7CI4DbCLNHWcxtHrIikWT8jfRSM | `images/favicon.jpg` (Takeout, 217x224 JPEG); `images/favicon-live.png` (live, 224x224) | On the live site this image is also the share picture (`og:image`) for Publications, Teaching and Links & Resources. |
| Publications, Teaching, Links & Resources | top banner background (theme) | not in Takeout | https://ssl.gstatic.com/atari/images/impression-header.png | `images/theme-impression-header.png` (4000x1600) | Google theme picture. See Layout. |
| (none) | not used on any page | `Publications/210de52472b7f1e3d4931fefdcd8ec68.jpg` and `Links  Resources/a2eade08f46acc6e6fba2be7918425fe.jpg` (the two files are the same) | not found on the live pages | `images/chalkboard.jpg` (1600x1200) | Blurry chalkboard with numbers and a globe. No PUBLISHED page refers to it. It is probably an old banner picture that is no longer shown (a guess). |

## Typos fixed

- Home, Online Presence: "My **dplp** page." -> "My **dblp** page." (only the link text; the link address `https://dblp.uni-trier.de/pers/hd/k/Kour:George` is unchanged).
- Publications, Patents: "Ateret Anaby Tavor..International Business Machines Corp" -> "Ateret Anaby Tavor. International Business Machines Corp".
- Publications, Patents: "Ofer Lavi ,Boaz Carmeli" -> "Ofer Lavi, Boaz Carmeli".

## Small formatting changes (not text)

- Home, SAMS item: in the source the italic starts just before the period (" Society*. Active Role...*"). It is written as "Society. *Active Role: ...*" so Markdown shows it correctly.
- Home, tsofen item: the source puts the colon after the link in italic. The colon is written as plain text.

## Left as on the old site (possible typos, not changed)

- "Raid Saabne" (Publications) vs "Raid Saabni" (Home): this is a name, so I left both.
- "(updated May. 2026)", "My Ph.D Thesis", "Not Enough Data? Deep Learning to the Rescue!." and "A talk was delivered in 2015 ..." were left as written.
