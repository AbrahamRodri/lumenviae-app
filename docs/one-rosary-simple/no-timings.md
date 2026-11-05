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

Rechecked 5 Nov 2026 06:05Z, after api #197 went live. Untimed:

| | frederick | female |
|---|---|---|
| Prayers (12) | memorare | memorare |
| Announcements (27) | seven_sorrows_1, seven_sorrows_2, seven_sorrows_7, sorrowful_2, sorrowful_3 | sorrowful_2, sorrowful_3 |
| Scriptural verses (249) | 19 | 11 |

Everything else is timed and lit. In the Spanish app a fixed prayer keeps
its Spanish words, unlit, since its recording is English.

A phone that saved the clip list before the timings came keeps using it
until its links expire, at most a day; then it fetches the timed list.
