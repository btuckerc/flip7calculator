# APP264401-I — Lucky Ledger Discovery and Listing Strategy

Updated: April 10, 2026

This document answers three questions:

1. Can we use `Flip 7` to help people find `Lucky Ledger`?
2. Where is the real legal/App Review line versus the gray area?
3. What should we do to strengthen the App Store listing without walking into an easy rejection?

## Bottom line

If the question is specifically about **App Store-visible metadata**, my answer is:

- Do **not** use `Flip 7` in the app name, subtitle, keyword field, promotional text, description, screenshots, app previews, custom product page metadata, or update notes.
- Treat that as **high-risk and likely noncompliant** with Apple’s published rules, especially after the active trademark complaint.

If the question is about **the broader internet outside App Store metadata**, the answer is more nuanced:

- There is some genuine legal gray area around factual, non-confusing references to another product under U.S. trademark law.
- But that gray area does **not** override Apple’s separate App Review rules.
- Given the notice already on file, I would not use the App Store listing itself as the battlefield.

## The Apple rules that matter most

These are the most relevant official Apple sources I found:

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines)
  2.3.7 says app metadata should be accurate and specifically tells developers not to pack metadata with trademarked terms.
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines)
  5.2.1 says you should only use content you created or are licensed to use.
- [App information reference in App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
  Apple’s keyword-field help says the app is already searchable by app name and company name, and that names of other apps or companies aren’t allowed in the keyword list.
- [Creating your product page](https://developer.apple.com/app-store/product-page/)
  Apple says keywords drive search visibility, are limited to 100 characters, and that improper keyword use is a common reason for rejection. Apple specifically calls out unauthorized trademarked terms and competing app names as disallowed keyword use.
- [Custom product pages](https://developer.apple.com/app-store/custom-product-pages/)
  Apple says custom product page metadata can appear in search results, can have assigned keywords, and must still follow the App Review Guidelines.
- [Discoverability on the App Store](https://developer.apple.com/app-store/discoverability/)
  Apple’s discoverability guidance points to the importance of search relevance, category choice, conversion performance, ratings/reviews, and metadata quality.

## The Colonist / Catan pattern worth copying

The closest useful analogy I found is `Colonist`.

- On the **App Store**, the current [Colonist.io app listing](https://apps.apple.com/us/app/colonist-io/id6444831129) stays generic. It presents itself as `Colonist.io`, uses its own brand, and describes its own gameplay loop without putting `Catan` in the title or visible App Store positioning.
- On the **open web**, Colonist is much more explicit. The current [Colonist website](https://colonist.io/) calls itself a `Settlers of Catan Alternative`.

That split is important.

It suggests a practical model for `Lucky Ledger`:

- keep **App Store surfaces generic but intentionally suggestive**
- if you want to push closer to nominative discoverability later, do it on your own website instead of in App Store metadata

That is the model I would copy here.

## What that means for `Flip 7`

### Public App Store metadata

I would treat the following as **no-go surfaces** for `Flip 7`:

- App name
- Subtitle
- Keyword field
- Promotional text
- Description
- What’s New text
- Screenshots
- App previews
- Custom product page keywords
- Custom product page screenshots or promotional text

Why:

- Apple’s own keyword help says names of other apps or companies are not allowed in keywords.
- Apple’s product page guidance says unauthorized trademarked terms and competing app names are improper keyword use and common rejection triggers.
- Apple’s review guidelines tell you not to pack metadata with trademarked terms and to use only content you own or are licensed to use.
- The complaint is already active. That makes this a bad place to “test the edge.”

## Safe signaling inside the App Store

If the real goal is “help the right people recognize what this scorekeeper is for” without using the exact mark, we can still push much harder than a bland generic utility listing.

These cues are the safest version of that strategy:

- `flip-card`
- `track flips`
- `7-card bonus`
- `track 7s`
- `hold`
- `bust`
- `push your luck`
- `round tracker`
- `bonus tracker`
- `offline scorekeeper`

These cues work because they describe mechanics, not ownership.

That means:

- subtitle ideas like `Track Flips and 7s` are defensible
- description lines like `Track flips, 7-card bonuses, holds, busts, and totals` are defensible
- screenshots that show `Hold`, `Bust`, and `7-card bonus` UI are defensible
- an icon showing a flipping card, a visible `7`, and a die is defensible

This is how we can “tip to it” without stepping over the clearest App Review line.

## What still crosses the line

Even with a more aggressive cueing strategy, I would still keep these off App Store-visible surfaces:

- `Flip 7`
- `FLIP 7`
- `for Flip 7`
- the publisher name
- logos, trade dress, or artwork that looks like the official product
- screenshot copy that implies affiliation or official status

### Private, non-public App Review communication

This is fine:

- Explaining to Apple in reviewer notes or email that you rebranded the app.
- Referring to the prior app title or the complaint number in private correspondence.
- Using `APP264401-I` in subject lines, as Apple requested.

That is not a discoverability tool, but it is a legitimate operational channel.

### Outside the App Store

This is the real gray area:

- Your website
- A support FAQ
- A blog post
- A compatibility article
- Search-engine ads outside the App Store

U.S. trademark law does recognize forms of nominative fair use in some contexts. A useful legal reference point is [Toyota Motor Sales, U.S.A., Inc. v. Tabari (9th Cir. 2010)](https://cdn.ca9.uscourts.gov/datastore/opinions/2010/07/08/07-55344.pdf).

My read:

- A factual statement on your own site can be more defensible than stuffing a competitor’s mark into App Store metadata.
- But the risk is still real, especially because the claimant has already put you on notice.
- If you choose this route anyway, the copy has to be minimal, accurate, and very clearly non-affiliative.

Examples of the kind of gray-area website copy that is more defensible than App Store keyword stuffing:

- `Works well for push-your-luck card scoring`
- `Flexible scorekeeping for bonus-heavy card games`
- If counsel approves: `Players have also used Lucky Ledger to track games like Flip 7`

If you decide to be more assertive on the web later, the cleanest progression is:

1. Keep the App Store page generic.
2. Add a website landing page for generic search intent first.
3. Only then decide whether to publish a restrained factual compatibility page that names the game.
4. Make sure any such page is clearly non-affiliative and does not reuse protected visual branding.

Even that last example is not something I would put in the App Store listing.

## Risk matrix

| Surface | Use `Flip 7`? | Risk | Recommendation |
|--------|----------------|------|----------------|
| App name / subtitle | No | Very high | Do not do it |
| Keyword field | No | Very high | Do not do it |
| Description / promo / What’s New | No | High | Do not do it |
| Screenshots / app previews | No | High | Do not do it |
| Custom product page keywords | No | High | Do not do it |
| Reviewer notes / private emails | Yes, factually | Low | Fine when needed |
| Website SEO pages | Maybe, narrowly | Medium | Only if you accept risk and keep it factual |
| Blog / FAQ comparison copy | Maybe, narrowly | Medium | Counsel review is smart here |
| Apple Ads on generic terms | Yes | Low | Recommended |
| Apple Ads on `Flip 7` terms | Unclear | Medium to high | I do not recommend this without counsel |

The Apple Ads row is the one place where I’m making an inference from incomplete public guidance:

- I found official Apple material supporting [custom product pages](https://developer.apple.com/app-store/custom-product-pages/) and [Apple Ads landing pages](https://developer.apple.com/app-store/custom-product-pages/).
- I did **not** find an official Apple source that cleanly blesses targeting a third party’s trademark as a keyword in this exact situation.
- Because of that, and because of the active complaint, I would not build the plan around trademark bidding.

## If you want to “hold your ground,” do it the smart way

If the goal is not to roll over, I think the strongest posture is:

1. Hold the line on your product existing.
2. Do not hand Apple an easy metadata violation.
3. Build a stronger generic listing than the old one.
4. Use channels outside the App Store, carefully, if you want to push nominative discoverability later.

That is different from retreating.

It means:

- we keep the app live if possible
- we ship a better, cleaner brand
- we improve conversion and discoverability on generic terms
- we do not give Apple or the claimant an obvious screenshot/keyword/title exhibit

## Recommended App Store upgrade plan

These are the highest-value listing improvements I would make.

### Metadata

1. Rename the app to `Lucky Ledger`.
2. Use a clearer-but-still-safe subtitle like `Track Flips and 7s`.
3. Keep the keyword list generic and high-intent, but lean into mechanic language like `flip card`, `7 card bonus`, `bust tracker`, and `push your luck`.
4. Rework the first sentence of the description so it immediately signals flips, 7-card bonuses, holds, and busts.
5. Keep promotional text focused on speed, offline use, and the specific table pain points this app removes.
6. Update What’s New to talk about the new brand, improved icon, and reliability improvements.
7. Keep review notes plain and operational, not argumentative.

### Category and search positioning

8. Try `Games → Card` as primary and `Utilities` as secondary for stronger relevance.
9. If App Review pushes back, swap them without changing the app concept.
10. Create custom product pages for different generic search intents, not brand names.
11. Segment those pages around `card night`, `bonus tracking`, and `stats`.

### Conversion assets

12. Replace every screenshot with Lucky Ledger branding.
13. Make the first screenshot prove the app is fast during live play and clearly about tracking flips.
14. Make the second screenshot prove the score-entry model is clear and that `Hold` / `Bust` states are legible.
15. Make the third screenshot prove there is value after the game via charts/stats.
16. Show deck profiles or house-rule flexibility in later screenshots, especially configurable `7-card bonus` behavior.
17. Keep screenshot copy short, functional, and non-comparative.
18. Consider an app preview only if it is crisp and high signal; a mediocre preview will not help.

### Trust and retention signals

19. Make sure the privacy policy URL is live before submission.
20. Make sure the support page is live and not stale.
21. Prompt for ratings only after real success moments, such as finishing a game.
22. Keep the app stable; conversion improvements are wasted if the app crashes or feels rough.

### Distribution and measurement

23. Use App Analytics to measure product-page conversion before changing copy again.
24. Compare the default page against custom product pages.
25. If you run Apple Ads, start with generic terms and measure install quality, not just tap-through rate.
26. Keep a dated record of all before/after screenshots and metadata in case Apple asks for proof.

## Discoverability without using `Flip 7` in metadata

If the objective is simply “be found by people who want a fast scorekeeper for games like that,” these are the better levers:

- `Games → Card` category positioning
- better first three screenshots
- stronger mechanic-level keywords and subtitle language
- custom product pages for generic intents
- a better icon with a visible flipping card and `7` cue
- a sharper first sentence in the description
- more ratings and reviews from real satisfied users
- external SEO for phrases like `card game scorekeeper`, `push your luck score tracker`, and `game night score app`

This is slower than stuffing a trademark into the keyword field, but it is much easier to defend.

## What I would not do

- I would not put `Flip 7` in the keyword field.
- I would not use `Flip 7` in the subtitle.
- I would not put `for Flip 7` in screenshots.
- I would not use custom product page keywords containing `Flip 7`.
- I would not try to sneak trademark references into promotional text.
- I would not argue “there has been little legal repercussion so far” as a reason to keep poking the same App Review wound.

The absence of consequences so far is not a strong shield once Apple has a documented complaint on file.

## If you still want to push the gray area

If you want to be aggressive anyway, the least bad version is:

1. Keep the App Store listing itself clean.
2. Build a website landing page that is factual, restrained, and clearly disclaims affiliation.
3. Avoid logos, trade dress, screenshots of the branded game, or anything that looks like endorsement.
4. Keep records showing the app is a generic scorekeeper, not an official companion.
5. Expect that this could still trigger more claimant pressure.

That is the “gray” path I think is at least strategically coherent.

Using `Flip 7` inside App Store metadata is not the gray path. It is the exposed path.

## Practical next move

My recommendation is:

- Ship `Lucky Ledger` with a clean generic listing.
- Upgrade the listing hard on conversion and generic discoverability.
- If you want to test gray-area discoverability, do it on your website, not in App Store metadata.
- If Apple rejects anything on the listing, use the formal review/Resolution Center process rather than reintroducing the trademark by stealth.
