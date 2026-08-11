# Guided Rosary — Experience Modes

> Working notes. Nothing here is built yet. Captures the direction for letting users
> choose *how much* of the Rosary the app prays for them, and how far customization goes.

---

## 1. The idea in one line

Today the app gives you a mystery, a meditation, and (optionally) audio for that meditation.
The goal is to let the user decide how much of the Rosary is **spoken for them** — from
"just the meditations, I'll pray the rest" all the way to "read me everything, I'm putting
the phone down."

---

## 2. The three modes

### Simple *(what exists today — becomes the named default)*
- Mystery artwork + meditation text.
- Meditation audio optional, per the existing `AudioService`.
- Prayers (Our Father, Hail Marys, Glory Be) are prayed by the user, unspoken, self-paced.
- No bead tracking. The app never counts Aves for you.

### Full
- Every part of the Rosary is spoken aloud, start to finish:
  - Sign of the Cross → Apostles' Creed → Our Father → three Hail Marys → Glory Be
  - For each decade: mystery announcement → meditation → Our Father → 10 Hail Marys →
    Glory Be → Fatima Prayer
  - Closing: Hail Holy Queen → closing prayer → Sign of the Cross
- The session runs as one continuous piece of audio. The user can lock the screen.
- Screen follows the audio (current prayer highlighted, bead position shown) but is not required.

### Custom *(later)*
- Every switch below is exposed individually.
- Saved as named **presets** the user can pick from before praying.

> **Framing for the user:** these are not "levels" or tiers. Simple is not lesser.
> Copy should never imply the fuller option is the more devout one. Same rule as
> streaks — invite, never rank.

---

## 3. Where the user chooses

1. **Onboarding** — a new slide between "At your own pace" and "Intention".
   Two cards, Simple vs Full, each with a one-line felt description and a short
   audio taste (a few seconds of a Hail Mary) so the difference is *heard*, not read.
   Custom is not offered here — mentioned only as "you can shape this later."
2. **Account → Prayer Experience** — change the default mode, manage presets.
3. **Pre-prayer sheet** — after picking a meditation set, before the flow starts:
   the active preset with a one-tap change. This is the important one; the mode a
   person wants at 6am differs from the one they want in the car.

---

## 4. What "custom" can actually change

The inventory of switches, roughly in the order they matter:

**Voice**
- [ ] Spoken prayers on/off (the Simple↔Full axis, per prayer type)
- [ ] Which prayers are spoken: intro block / Our Fathers / Hail Marys / Glory Bes /
      Fatima / closing — each independently
- [ ] Meditations spoken vs read silently
- [ ] Mystery announcement spoken vs shown
- [ ] Voice selection (see §8)
- [ ] Language: English / Latin / bilingual — should reuse the existing `PrayerLanguage`

**Pacing** *(the single biggest quality lever — see §9)*
- [ ] Lead-and-respond vs full recitation
- [ ] Silence length between prayers
- [ ] Silence after each meditation before the decade begins
- [ ] Overall speed

**Structure**
- [ ] Include the opening prayers, or go straight to the first mystery
- [ ] Which optional prayers are included (Fatima Prayer, St. Michael, Memorare,
      Hail Holy Queen, Litany of Loreto, prayer for the Holy Father)
- [ ] Custom intentions attached to specific beads — e.g. the first Our Father offered
      *for the intentions of the Holy Father, the bishops, and priests*. This is a real
      and common practice and is exactly the kind of thing a preset should hold.
- [ ] Announcement style: plain ("The First Joyful Mystery: The Annunciation") vs
      with the fruit of the mystery vs scriptural

**Sound**
- [ ] Background ambiance on/off + track (chant, organ drone, bells, silence)
- [ ] Ambiance volume, independent of voice
- [ ] Decade chime for users who want a marker but no spoken prayers —
      this is the natural middle ground between Simple and Full

**Screen**
- [ ] Image mode vs reading mode (exists today as `prayerImageMode`)
- [ ] Keep screen awake / let it sleep (Full mode should default to letting it sleep)
- [ ] Show bead position

---

## 5. The structural change this requires

Today the unit of the prayer flow is a **meditation**. `PrayerSessionViewModel` walks
an array of 5 meditations, and `AudioService` loads one file at a time.

Full mode needs the unit to be a **segment** — one step in a script:

```
Segment
  kind:        .signOfCross | .creed | .ourFather | .hailMary | .gloryBe
               | .fatima | .announcement | .meditation | .closing | .silence | .chime
  text:        bilingual text (reuse BilingualText / BilingualPrayer)
  audioRef:    which recording to play, if any
  trailingSilence: seconds
  decadeIndex: Int?     // for progress + resume
  beadIndex:   Int?     // 1...10 within a decade
```

A **RosaryScript** is then just `[Segment]`, generated from
`(meditationSet, preset, language)`. Notes:

- Generation is pure and testable — no audio, no views. Worth building first.
- A script for a standard Rosary is ~70 segments. Fine.
- The Simple experience is expressible as a script too (5 meditation segments, no
  prayer segments), which means **one engine, not two code paths**.
- Resume (`PrayerResumeService`) moves from mystery-index to segment-index. Existing
  saved resumes should map forward gracefully — treat an old mystery index as the
  first segment of that decade.
- Scripts should eventually be **server-defined** so new formats (a Lenten script, a
  Divine Mercy chaplet, a scriptural Rosary) can ship without an app release. Matches
  the existing content-driven principle. Ship v1 with the script builder client-side,
  but shape the model so it can be decoded from the API later.

---

## 6. Audio architecture notes

`AudioService` today is a single `AVPlayer` singleton with one loaded URL. Full mode needs:

- **A sequencer above it.** Play segment *n*, wait for end, insert silence, play *n+1*.
  Cleanest path is `AVQueuePlayer` with pre-built silence assets, or a chained player
  with a timer for gaps. `AVQueuePlayer` gives gapless playback for free and keeps the
  Lock Screen transport sane.
- **Two audio buses.** Voice and ambiance are separate players. Ambiance loops
  (`AVPlayerLooper`), ducks under voice, and survives segment boundaries. Independent volume.
- **Prefetch.** Never let a gap between the 6th and 7th Hail Mary be a network stall.
  Prayer audio is small and highly repeated — download the whole prayer pack once and
  play locally. This is the same problem `OfflineContentService` already solves for
  meditations; extend it rather than inventing a parallel path.
- **Now Playing / remote commands.** Already handled for meditations. In Full mode the
  metadata should read as the *session* ("Joyful Mysteries — 3rd Decade"), with skip
  mapped to segment or decade, not ±10 seconds. Headphone and steering-wheel controls
  are the primary interface here.
- **Interruptions.** Existing handling is good. One addition: if a call lands mid-decade,
  resume at the *start* of the interrupted prayer, not mid-word.
- **Session lifetime.** Full mode is a 20+ minute continuous session. Verify background
  audio entitlement, and don't call `deactivateSession()` between segments.

---

## 7. Recording burden — the real cost

Naive counting says a Full Rosary needs hundreds of files. It doesn't, if the script
model is right:

**Recorded once per (voice × language):**
- Sign of the Cross, Creed, Our Father, Hail Mary, Glory Be, Fatima Prayer,
  Hail Holy Queen, closing prayer, St. Michael, Memorare
- ≈ 10 files. The Hail Mary is played 53 times from one recording.

**Recorded once per voice, content-specific:**
- Mystery announcements: 20 (+7 Seven Sorrows)
- Optional intention lines ("for the intentions of the Holy Father…"): a handful

**Already exists:** meditation audio, per meditation set, via the current pipeline.

So a complete voice is roughly **35–40 files**, not hundreds. That makes multiple voices
economically real. Notes:

- Identical repeated audio for all 10 Hail Marys can feel mechanical. Consider recording
  2–3 takes and rotating, or accept it — most recorded Rosaries do exactly this.
- Latin needs a reader who can actually pronounce it. Non-negotiable; a bad Latin Ave is
  worse than no Latin option.
- Chant/ambiance beds must be cleanly licensed or public domain. The reminder sounds
  already follow this rule — same standard.

---

## 8. Voices, and the paid tier

- Voice selection (male/female, spoken/chanted, English/Latin) is the most obvious thing
  to charge for, and the most honest: the Rosary itself stays free, the production values
  are the product.
- **Never gate the prayer.** Simple and Full should both be free with a default voice.
  Locking "the app will pray with you" behind a paywall is the wrong business for this app.

### User-authored prayers + generated audio *(the long-term ask)*

The stated goal: users add their own prayers/intentions, and paying users get audio
generated automatically. Notes for when that lands:

- Text is easy — a `UserPrayer` record with title, text, language, and where it attaches
  in the script (before/after a named segment, or on a specific bead).
- Without audio, a user prayer in Full mode still works: display it and hold silence for
  a set duration, or fall back to on-device speech synthesis.
- **Generated audio** = TTS at the server, stored per user, cached on device.
  - Needs a pronunciation lexicon for sacred vocabulary (Ave, Maria, Iesu, Deiparae,
    "thy", proper names of saints). Off-the-shelf TTS mangles these.
  - Needs a *preview and regenerate* step before it's saved. Users will not accept a
    mispronounced prayer they can't fix.
  - Needs a content check. Anything user-generated that the app then speaks in a
    devotional voice is a reputational surface.
  - Cost is per-generation, not per-play — cheap to serve, so cache aggressively and
    let regeneration be the metered action.
- Shared/community prayer packs are the natural extension, and also the moment this
  needs real moderation. Not v1. Not v2.

---

## 9. Suggestions

Things worth considering that weren't in the original sketch:

1. **Lead-and-respond is the killer feature, not full recitation.** In a group Rosary the
   leader prays the first half of the Hail Mary and everyone answers the second half.
   An app that leaves the response silent turns a passive listen into actual praying.
   Recommend building this as a first-class option in Full mode from day one, not as a
   custom switch later. It's a genuine differentiator and it's cheap — just a split in
   the recording plus silence.
2. **Pacing deserves a real control, not a hidden constant.** The most common complaint
   about recorded Rosaries is "too fast" or "too slow." A three-stop pace control
   (Unhurried / Steady / Brisk) that adjusts inter-prayer silence will do more for
   satisfaction than any additional feature here.
3. **Show the time estimate before starting.** "About 24 minutes with this setup."
   Removes the main reason people don't start.
4. **Ship a small set of named presets rather than an empty custom builder.** People
   don't want to configure 20 switches; they want to recognize themselves:
   - *Guided* — everything spoken, unhurried
   - *Lead & Respond* — app leads, you answer
   - *Quiet* — meditations only, decade chime (today's Simple + a bell)
   - *Drive Time* — audio-only, screen off, no interaction required
   - *Family* — spoken, speaker-friendly, larger text, lead-and-respond
   - *Learning* — fully spoken with brief plain-language explanation of what's happening
     and why, pairing with the existing "How to Pray the Rosary" content. Strong onboarding
     tool for converts and returning Catholics — arguably the highest-value preset.

   Custom then becomes "duplicate a preset and adjust," which is a much smaller UI problem.
5. **Full mode is an accessibility feature.** Blind, low-vision, elderly, and
   post-stroke users can pray a complete Rosary with the phone in a pocket. Worth naming
   explicitly in the App Store listing, and worth holding to a real standard —
   full VoiceOver labeling, no interaction required to complete a session.
6. **Drive time is a genuine use case.** Many people pray the Rosary in the car. That
   means: zero-interaction completion, robust Lock Screen controls, CarPlay eventually,
   and never a modal that blocks playback.
7. **Bead position, carefully.** Full mode makes bead-level position *knowable* for the
   first time. Show it as a location ("3rd decade, 7th bead"), never as a completion
   metric, and never surface an abandoned session as a failure. Same no-guilt rule.
8. **A decade chime is the cheapest win in this whole document.** Users who want silence
   but lose count get a soft bell at each Glory Be. One sound file, one switch.
9. **Apple Watch, later.** A haptic tap per bead with no audio is a beautiful version of
   this — you keep your hands and eyes free and the beads are felt. Long horizon, but the
   segment model above is exactly what it would need.
10. **Keep the default for existing users on Simple.** Migrating someone's prayer into a
    talking app without asking would be a bad surprise. New users choose in onboarding;
    existing users get a one-time, dismissible invitation to try Full.

---

## 10. Open questions

- Does the backend own prayer audio as its own resource (`/prayers/audio?voice=&lang=`),
  separate from meditation sets? Probably yes — different lifecycle, different caching.
- Are scripts server-defined from the start, or client-built in v1? *(Leaning client-built
  first, model shaped for server delivery.)*
- Where do presets live — device-only like favorites, or synced to the account?
  Device-only is simpler and consistent with current behavior; syncing matters the moment
  a user pays for generated audio.
- One voice at launch, or male + female? One good voice beats two mediocre ones.
- Does Full mode need its own offline download flow, or does it extend
  `OfflineContentService`? *(Extend.)*

---

## 11. Rough phasing

**Phase A — foundations**
Segment + RosaryScript model, script builder, existing Simple flow re-expressed as a
script. No user-visible change. This is the whole bet; get it right.

**Phase B — Full mode**
One voice, English. Sequencer + prefetch. Onboarding choice slide. Account setting.
Segment-level resume. Lock Screen session metadata.

**Phase C — pacing and presets**
Lead-and-respond. Pace control. The named preset set. Pre-prayer preset switcher.
Decade chime. Background ambiance with independent volume.

**Phase D — custom**
Duplicate-and-edit presets. Optional prayer toggles. Bead-attached intentions
(Holy Father, personal). Latin and bilingual voices.

**Phase E — user prayers**
User-authored prayer text in scripts. Then generated audio behind the paid tier, with
preview, regenerate, and a pronunciation lexicon.
