# API request — meditation set artwork, attribution, and (later) intentions

**From:** the iOS app (Lumen Viae)
**To:** the LumenViae API / Phoenix web app session
**Why now:** the iOS meditation picker was rebuilt (August 2026). Tapping a set no longer starts the Rosary directly — it opens a **set detail** screen first: a full-bleed painting with a gradient, the set's name and labels, its description, the opening lines of the first mystery, and one gold "Pray with these meditations" at the foot. Deliberately simple, because the API says little about a set. Everything on that screen is already coming from the API **except the artwork**, which today borrows the mystery category's bundled painting. This request is what the app needs from the API to finish the screen honestly.

Nothing here blocks the iOS build — every field below is optional on the client and falls back gracefully. Priority order is as listed.

---

## 1. Artwork per meditation set (needed)

Add an image to each meditation set and return it on **both** endpoints:

```
GET /api/meditation-sets?category=:category   → each summary gains "image_url"
GET /api/meditation-sets/:id                  → the set gains "image_url"
```

Proposed shape (snake_case, like `audio_url` / `scripture_reference`):

```json
{
  "id": 27,
  "name": "Blessed Fulton J. Sheen",
  "description": "Meditations on the Sorrowful Mysteries from Bishop Fulton J. Sheen",
  "category": "sorrowful",
  "labels": ["Considerations"],
  "image_url": "https://…/sets/27/hero.jpg",
  "image_alignment": "center"
}
```

- `image_url` — `null` when the set has no artwork. The client then falls back to the category's bundled painting, exactly as it does today, so a partially populated catalogue is fine.
- `image_alignment` — optional, one of `"top" | "center" | "bottom"`. Tall canvases with the subject high in the frame (the Resurrection, the Pietà) crop badly at center; the app already carries this per-category and would rather the content side own it per image. Default `"center"` if absent.

**Sizing / format:** the hero is a full-bleed image ~470pt tall on a 393–440pt-wide screen, running from the top edge and fading into the page — portrait or square works, landscape does not. Please serve **≥1200px on the short side, JPEG, sRGB**, no baked-in text or borders. One image per set is enough; the picker's tiles deliberately carry no artwork.

**Expiry — this is the important part.** Meditation audio is a **1-hour presigned S3 URL**, which is fine for a stream but wrong for an image the app wants to cache and show offline. Please serve set artwork from a **stable, public, cacheable URL** (public S3 object / CloudFront, long `Cache-Control`), not a presigned one. If the bucket policy makes that hard, say so and the app will download-and-store on first fetch — but the URL in the JSON must at least be stable per set so the client can key its cache on it.

**Admin/import:** the CSV importer (`mystery_name,title,content,author,source,audio_filename`) has no column for this and one image per *set* doesn't fit a per-meditation CSV anyway — a field on the set's admin form is probably right. If you'd rather it come through the CSV, an `image_filename` on the first row of a set would work; tell the app which.

**Offline:** `OfflineContentService` on iOS downloads every set's text and audio for offline prayer. Once `image_url` exists it will download those too, keyed by set id — so please make sure the URL is fetchable with a plain GET and no auth.

## 2. Artwork per meditation (optional, later)

Each meditation already has an `audio_url`. A parallel per-meditation `image_url` would let the prayer screen show set-specific art per mystery instead of the bundled category paintings (Emmerich's visions with different art from Sheen's, etc.). Not needed for the detail screen. If you add it, the client's fallback chain would be: meditation image → set image → bundled mystery painting.

```json
{
  "id": 126,
  "title": null,
  "author": "Bishop Fulton J. Sheen",
  "source": "The Fifteen Mysteries of the Rosary",
  "content": "…",
  "audio_url": "…presigned…",
  "image_url": null,
  "mystery": { … }
}
```

## 3. Author and source at the set level (small, cheap)

Today `author` and `source` live only on each meditation, so nothing about a set's authorship is available until the full set is fetched. The detail deliberately shows no byline yet — it renders labels, the category line, the description, and the opening of the first mystery — and the picker's tiles can't show one at all. An `author` and `source` on the **set** (returned on both endpoints) would let a byline render from the summary, before any load and on the shelf itself. Nullable.

```json
{ "id": 30, "name": "St. Alphonsus Liguori - Short", "author": "St. Alphonsus Liguori", "source": "The Glories of Mary", … }
```

Note from the data as it stands: `source` is populated on the Sheen sets and empty on most others — worth filling as sets are added.

## 4. Label vocabulary — two words to decide on

`LumenViae.Rosary.Labels` currently validates against **Intentions, Saints, Scriptural, Contemplative, Considerations**. The design handoff for the picker assumed two more, **Marian** and **Vocation** (used in its previews and in the planned intention matching). Either add them to the vocabulary or tell the app to stop expecting them — the picker itself doesn't care (chips are built from whatever labels arrive), but the intention feature in §5 leans on them.

Reminder that already holds: the first label in a set's array is its primary group in the picker, so order labels primary-first. "Considerations" is displayed as **Reflections** on iOS (`MeditationLabel.displayName`); rename in that map, not in the database.

## 5. Intentions on a set (future — do not build yet)

The next iteration of the picker adds a row of intentions above the shelf — "Find a set for what you are praying for": *A cross of my own · Thanksgiving · Someone who has died · My family · A decision · Only to be near her*. It is deferred until there are enough sets for it to mean anything. When it lands, the app would rather match on a real field than on keywords in the name:

```json
{ "id": 61, "name": "In Times of Suffering", "labels": ["Intentions"], "intentions": ["cross", "dead"], … }
```

A small controlled vocabulary of intention ids, owned by the web app the way labels are, returned on the summary endpoint. Flagging it now so the schema can leave room; **no work requested yet.**

---

### Summary of what the app will do with each

| Field | Where it shows on iOS | Fallback when absent |
|---|---|---|
| set `image_url` (+ `image_alignment`) | Set detail hero | Category's bundled painting |
| meditation `image_url` | Prayer screen artwork (later) | Set image → bundled mystery painting |
| set `author` / `source` | Detail byline, once it exists | Not shown |
| labels Marian / Vocation | Filter tray chips; future intention matching | Nothing — chips are data-driven |
| `intentions` | Future intention row | Keyword matching on set names (interim) |

Ping the iOS side when §1 is live and I'll swap the hero to the API image and add images to the offline download in the same change.
