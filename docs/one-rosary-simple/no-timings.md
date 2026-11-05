# Recordings without timings (simple Rosary)

Checked 5 Nov 2026, read-only, against the live api (`lumenviae.fly.dev`).
The simple Rosary lights words only from a recording's real `lines`.
Everything below has none, so the player shows its words with no line lit.

## Meditations (v2 `POST /api/v2/meditations/audio`)

236 of 242 narrations served (121 meditations, voices `frederick` and
`female`) have lines. These 6 do not:

| Mysteries | Set | Meditation | Id | Voice |
|---|---|---|---|---|
| Joyful | Father Frederick William Faber | 2 | 332 | frederick |
| Joyful | Father Frederick William Faber | 2 | 332 | female |
| Sorrowful | Dom Prosper Guéranger | 3 | 363 | frederick |
| Sorrowful | Dom Prosper Guéranger | 3 | 363 | female |
| Glorious | St. John Henry Newman | 2 | 297 | frederick |
| Glorious | St. John Henry Newman | 2 | 297 | female |

The bundled sets (negative ids: Gospel Joyful and Glorious, Emmerich
Sorrowful, the Luminous set, Liguori Seven Sorrows) have no recording at all,
so they open as text to read.

## Rosary prayer clips (`GET /api/rosary/audio`)

No clip has `lines` yet (api-build is adding the field). Untimed, both voices
(`frederick`, `female`):

- Prayers (12): act_of_contrition, apostles_creed, fatima_prayer, glory_be,
  hail_holy_queen, hail_mary, memorare, our_father, rosary_closing_prayer,
  sign_of_cross, sorrows_closing_prayer, st_michael_prayer
- Announcements: 27 per voice
- Scriptural Rosary verses: 249 per voice

The app decodes `lines` on each clip already (`RosaryAudioClip.lines`), so
these light up as soon as the api serves them; no app change is needed.
