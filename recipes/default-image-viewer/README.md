# default-image-viewer

Set the default app that opens images (Preview, XnView, Acorn, …) instead of
Photos.

## What it does

Runs `duti -s <bundle-id> <UTI> viewer` for the common image formats:
`public.png`, `public.jpeg`, `public.tiff`, `public.heic`,
`com.compuserve.gif`, and `public.camera-raw-image`. Like the default *terminal*
(and unlike the default *browser*), `duti` sets document-type handlers
**silently** — no macOS consent dialog. The step's `check` reads
`duti -d public.png` and re-runs only when it isn't already your app.

Images are set **per concrete format on purpose**: setting the `public.image`
umbrella does not reliably cascade to `public.png`, `public.jpeg`, etc. in
LaunchServices, so this recipe names each format it manages.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting UTI handlers.
- Your viewer installed, with its bundle id resolvable
  (`osascript -e 'id of app "Preview"'`).

## Adopt

1. Copy `default-image-viewer.sh` into your config's `steps/`.
2. Set `APP` in the script to your viewer's bundle id, and change the matching
   bundle id in the step's `check`. Common ids: `com.apple.Preview`,
   `net.sourceforge.xnview.XnViewMP`, `com.flyingmeat.Acorn`.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- **Per-format, not exhaustive.** The `utis` list covers PNG/JPEG/TIFF/HEIC/GIF
  and camera RAW. Formats you didn't list (e.g. `public.svg-image`,
  `org.webmproject.webp`, `com.microsoft.bmp`) keep their existing handler; add
  them to the list if you want them too.
- The `check` probes only `public.png`. If you add or drop formats, keep the
  `check` pointed at one you actually manage so `plan`/`status` stay honest.

## Security

Minimal — it sets user-scoped file-association preferences (LaunchServices), no
privilege, no network, no system state. Opening an image is a passive view.
Reverse by pointing the same UTIs at another app, e.g.
`duti -s com.apple.Preview public.png viewer`.
