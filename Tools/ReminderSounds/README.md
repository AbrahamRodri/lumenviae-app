# Reminder sounds

The daily reminder's sounds in `app/Resources/`, and how each was made.

- `candle_chime.caf`: generated in ElevenLabs Sound Effects on 14 Oct 2026
  from the prompt "Notification chime for a nighttime Rosary app. Imagine a
  single candle lit in a dark stone chapel: one warm, resonant tone with a
  soft shimmer, like a struck bowl or a distant bell heard through a door,
  1.5 seconds, gentle attack, natural decay to silence, no music, no voice,
  no room noise" (duration 1.5 s, prompt influence about 0.4), downloaded
  as WAV, then made a notification sound with:

  ```bash
  ffmpeg -i chime.wav \
    -af "silenceremove=start_periods=1:start_threshold=-50dB,apad=pad_dur=0.15,loudnorm=I=-18:TP=-1.5,afade=t=out:st=0.9:d=0.25" \
    -ac 1 -ar 44100 -c:a pcm_s16le app/Resources/candle_chime.caf
  ```

  Mono, 44.1 kHz, 1.15 s. The source WAV is not kept; a replacement is
  made the same way from a new take.
- `altar_bell.caf`: a public domain recording (pdsounds.org / Wikimedia
  Commons), trimmed, faded and normalized; it predates this note.
- `church_bell.caf`: the same provenance; no longer in the picker, kept
  because the Angelus rings it.

To add or replace a sound: make the .caf as above (mono, under 30 s), drop
it in `app/Resources/`, and list it in `ReminderSound.all`
(`app/Services/UserSettings.swift`).
