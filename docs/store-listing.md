# Google Play store listing — Rainbow Data

Copy/paste fields for the Play Console listing. Assets live alongside this file
in `docs/`.

## App name
Rainbow Data

## Short description (80 char max)
A data-rich Wear OS watch face with 12 live metrics and a rainbow color scheme.

## Full description (4000 char max)
Rainbow Data is a data-rich digital watch face for Wear OS that packs twelve
live readouts around a bold central clock — each one color-coded by its
position, so the whole face sweeps through a rainbow as your eye travels
around the dial.

AT A GLANCE
• Large digital time with seconds and the date
• Moon phase — the current phase name plus its day in the lunar cycle
• Heart rate, step count, and battery, front and center
• A second time zone (Los Angeles), DST-aware
• Eight customizable complication slots for the data you care about

RAINBOW H/M/S INDICATORS
Three slim dots ride the outer rim — one each for hours, minutes, and
seconds — and shift color as they revolve, giving you an analog sense of
time wrapped around the digital readout.

EIGHT COMPLICATIONS, YOUR CHOICE
Fill the eight slots with the metrics that matter to you: temperature, UV
index, sunrise/sunset, active zone minutes, floors, distance, a timer, an
itinerary shortcut, and more. Tap and assign each one right on your watch.

BUILT FOR WEAR OS
• Built with the modern Watch Face Format — efficient and battery-friendly
• Dimmed, burn-in-safe always-on display
• Optimized for round Wear OS watches, including the Pixel Watch series

Whether you want every stat at a glance or just love a splash of color on
your wrist, Rainbow Data keeps your day in view — beautifully.

## Graphic assets
| Asset | File | Spec |
|-------|------|------|
| Feature graphic (composed) | `docs/feature_graphic.png` | 1024 × 500 PNG |
| Feature graphic (promo render — alt) | `docs/promo_render.png` | 1024 × 500 PNG |
| App / store icon | `docs/icon_512.jpg` | 512 × 512 |
| Header / README image | `docs/watch.png` | 480 × 480 (live capture) |
| Phone screenshots | needed: min 2, 16:9 or 9:16 | (watch faces: a watch render is fine) |

## Listing notes / accuracy
- Complication slots show their **default** providers until the user assigns
  them on-watch; the "Timer" and "Itin" slots are generic and depend on what
  the user points them at.
- "Burn-in-safe always-on": ambient mode dims and hides the busy elements
  (the standard safe approach), keeping only the time visible.
- Min SDK is **34** (Wear OS 5+); not installable on Wear OS 4.
