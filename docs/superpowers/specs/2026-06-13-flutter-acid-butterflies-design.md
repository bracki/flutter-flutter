# Flutter — Acid Flutterbies (v1 design)

**Date:** 2026-06-13
**Platform:** iOS first (runs on iOS Simulator; real device for true shake)
**Engine:** Flame (chosen for room to grow the game layer later)

## 1. Concept

A primarily-ambient iOS app. Glowing neon butterflies drift and flap across a melting
tie-dye rainbow background, settling on glowing flowers. Two interactions sit on top:

- **Tap to catch** — tap a butterfly to collect it. A cozy counter ticks up. No fail state.
- **Shake** — one gesture fires a combined psychedelic burst: butterflies scatter & swirl,
  new flowers bloom, and the whole palette shifts hue.

## 2. Visual style (locked)

Melting rainbow **tie-dye swirl background** (an animated gradient cycling
pink → violet → green → amber → pink) with **full neon glow** on the butterflies and
flowers (blazing, layered-blur glow over saturated wing gradients). Near-black is *not*
used — the swirling rainbow is the backdrop. Palette anchors:
`#ff6ec4` (pink), `#7873f5` (violet), `#4ade80` (green), `#facc15` (amber).

## 3. Architecture (Flame)

A `FlameGame` root drives the update loop; everything on screen is a component.

| File | Responsibility |
|------|----------------|
| `lib/main.dart` | `runApp` → `GameWidget` hosting the game + HUD overlay |
| `lib/game/flutter_game.dart` | The `FlameGame`. Owns butterflies/flowers, global hue state, caught-counter (`ValueNotifier<int>`), wires the shake detector. Exposes `scatter()`, `bloomFlowers()`, `shiftPalette()`, and a combined `onShake()` that calls all three. |
| `lib/game/butterfly.dart` | `PositionComponent` + `TapCallbacks`. Position/velocity, steering toward a target flower with wander-noise, wing-flap phase, layered-blur glow render, catch animation. |
| `lib/game/flower.dart` | `PositionComponent`. Hue, pulsing glow, bloom-in animation; acts as an attractor. |
| `lib/game/tie_dye_background.dart` | Full-viewport component painting the animated swirling rainbow gradient. |
| `lib/game/palette.dart` | Locked tie-dye palette + pure hue-shift logic (wraps 0–360°). |
| `lib/input/shake_detector.dart` | Wraps `sensors_plus` accelerometer; magnitude threshold + debounce → `onShake` callback. |
| `lib/ui/hud.dart` | Flutter overlay widget: the "caught" counter and a subtle title. |

**Dependencies:** `flame`, `sensors_plus`. Dev: `flutter_test`, `flame_test`.

## 4. Behaviors

- **Ambient:** butterflies pick a target flower and steer toward it with organic wander
  (sine/noise offset); gentle continuous wing flapping; flowers glow and pulse softly.
  When a butterfly reaches its flower it lingers, then picks a new target.
- **Tap to catch:** tap hit-tests a butterfly → catch animation (scale-down + sparkle) →
  counter +1 → a fresh butterfly fades in after a short delay so the scene stays alive.
- **Shake:** `onShake()` fires all three at once:
  1. *Scatter* — outward velocity impulse on every butterfly.
  2. *Bloom* — spawn a few new flowers with a bloom-in animation.
  3. *Color shift* — rotate the global hue offset, applied to butterflies, flowers, and
     the background gradient.

## 5. iOS Simulator runnability (explicit requirement)

The app must build and run on the iOS Simulator via `flutter run` against an available
iPhone simulator (Xcode 26.5, CocoaPods present).

**Known limitation:** `sensors_plus` accelerometer events do **not** fire in the iOS
Simulator (no hardware accelerometer; the sim's ⌃⌘Z sends a UIKit motion event, not
accelerometer data). To keep shake verifiable in the simulator, `shake_detector.dart`
exposes the `onShake` callback as the single entry point, and the game wires a
**debug-only manual trigger** to that same callback so the full shake behavior can be
exercised in the sim:

- A small debug button in the HUD (compiled only in debug builds, `kDebugMode`) that
  calls `game.onShake()`.

Real accelerometer shake works on a physical device through the same `onShake` path.
This separation also makes shake behavior unit-testable without any sensor.

## 6. Testing (TDD)

Test-driven: write the failing test first, then implement. Logic is deliberately kept in
plain, pure methods so most of it tests without the full engine.

**Unit tests (pure logic):**
- `palette`: hue-shift wraps correctly across 0/360°; shifting by 360° is identity.
- `butterfly` steering: produces a velocity vector pointing toward the target flower;
  wander stays within bounds; position stays on-screen over many steps.
- `scatter`: applying a shake impulse increases each butterfly's speed / pushes it outward.
- catch: catching a butterfly increments the counter exactly once and removes it.
- `flower` attraction: attraction vector points from butterfly toward flower.

**Flame component tests** (`flame_test`, `game.ready()` → `update(dt)`):
- `bloomFlowers()` adds the expected number of flower components.
- `onShake()` invokes scatter + bloom + palette shift (counter of flowers grows, hue
  offset changes, butterfly speeds rise).
- a tapped butterfly is caught and the `ValueNotifier` count increments.

**Widget test:**
- HUD renders and reflects the caught-counter value when the notifier changes.

**Manual verification (acceptance):** `flutter run` on an iPhone simulator; confirm the
scene animates, tapping a butterfly increments the counter, and the debug shake button
triggers scatter + bloom + color shift.

## 7. Out of scope (v1 / YAGNI)

- No levels, score multipliers, or fail states (counter only).
- No sound.
- No persistence / high-score saving.
- Android, web, desktop targets (design is portable, but not built or tested in v1).
- "Guide butterflies to matching flowers" mechanic (possible later expansion).
