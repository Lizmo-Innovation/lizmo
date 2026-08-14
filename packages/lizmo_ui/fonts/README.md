# Bundled fonts

The three families from `docs/lizmo_design_language_v2.html`, shipped as assets
rather than fetched at runtime.

| File | Family | Role |
|---|---|---|
| `SpaceGrotesk-Variable.ttf` | Space Grotesk | Display — screen titles, section labels |
| `Manrope-Variable.ttf` | Manrope | Body — everything else in the interface |
| `IBMPlexMono-Regular.ttf` | IBM Plex Mono | Data — peso amounts, dates, figures |
| `IBMPlexMono-SemiBold.ttf` | IBM Plex Mono | Data, emphasised |

## Why bundled

- **Works offline.** Lizmo's users are Philippine landlords and tenants on mobile
  data; the app should not need a round trip to Google to render its own text.
- **No first-launch flash.** Runtime fetching renders fallback type until the
  download lands, then reflows.
- **Golden tests become meaningful.** `google_fonts` cannot fetch under
  `flutter test`, so every golden rendered with fallback type and could not
  catch a typography regression.

## Variable versus static

Space Grotesk and Manrope are published only as variable fonts, with a `wght`
axis. Flutter maps `fontWeight` onto that axis, but `LizmoType` also sets
`fontVariations` explicitly — relying on the implicit mapping has been
inconsistent across platforms, and being explicit costs nothing.

IBM Plex Mono ships as statics, so the two weights actually used are bundled
directly.

## Licensing

All three are under the SIL Open Font License 1.1, which permits embedding in
an application. The licence text for each is beside the fonts (`OFL-*.txt`) and
must stay with them.

Source: <https://github.com/google/fonts>
