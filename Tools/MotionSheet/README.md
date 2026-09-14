# MotionSheet

A contact sheet of frames from a simulator recording, so an animation can
be judged from stills: a tab crossfade, the bead strand following a
finger, a tray's rows arriving. Screenshots taken one at a time run at
three or four a second, which misses a 0.3s transition entirely; a
recording catches it, and the sheet lays the frames out with their
timestamps.

```bash
swiftc -O Tools/MotionSheet/sheet.swift -o /tmp/sheetx

# Record while driving the simulator, then stop with SIGINT
xcrun simctl io <udid> recordVideo --codec h264 --force /tmp/take.mov &
# ...perform the gesture...
kill -INT %1

# sheet <movie> <out.png> <step seconds> <from> <to> [columns] [thumb width]
/tmp/sheetx /tmp/take.mov /tmp/take_sheet.png 0.04 1.0 3.0 8 150
```

Frames are pulled with `AVAssetImageGenerator` at zero tolerance, so the
timestamps are exact. Eight columns of 150pt thumbnails reads well; use a
0.04–0.05s step for a transition, 0.1s for a longer sequence.
