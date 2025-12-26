# Sil-Q iOS Gesture Spec (Draft)

This document defines a **gesture vocabulary** for playing Sil-Q comfortably on a phone, and maps those gestures onto existing Sil-Q commands.

**Sources for commands**
- **Sil-Q in-game help (`?`)** implemented in `src/files.c` (`show_help_screen()` / `do_cmd_help()`), which lists the core key commands.
- **Sil-Q v1.5.0 manual** ("User Interface" chapter + scattered key mentions like `?`, `@`, `i`, `S`, `z/5`, `0`, `x`).

## Goals
- Make the *most frequent actions* (move/run/wait/interact/pickup/look/target) fast and one-handed.
- Avoid fighting iOS expectations: keep pinch-to-zoom and two-finger pan available.
- Keep gestures predictable and reversible (easy cancel/back).
- Don’t replace the on-screen keyboard; gestures are a parallel input layer.

## Design principles
- **No accidental actions:** gestures that can cause danger (e.g. run, fire) should require a “stronger” gesture (flick / long-press / multi-finger).
- **Mode-light:** prefer a small number of modes. If we need a mode, it should be obvious (e.g. “look cursor mode”).
- **Zoom-safe:** when zoomed, panning should still work; movement gestures should not hijack normal pan.

## Gesture vocabulary (what we’ll recognize)
- 1-finger: tap, double-tap, long-press, swipe (8-direction), flick (fast swipe)
- 2-finger: tap (escape/back), pan (scroll), pinch (zoom)
- Screen edge: left-edge swipe, right-edge swipe

## Command inventory (from in-game help)
These are the commands we aim to cover well via gestures.

**Movement / flow**
- Move/attack/open doors: numpad / arrow keys (8-dir)
- Run/continuous move: `shift` or `.` + direction
- Wait (and search): `5` or `z`
- Rest-until-healed: (described alongside run/rest in help)
- Repeat last command: `n`
- Repeat next command: `0`/`R` (depends on keyset)

**Interact**
- Interact-with-square: `control` (or `/` depending on keyset) + direction
  - tunnel, close, bash doors, disarm traps, open chests/search skeletons, attack without moving
- Interact with own square: pick up item / use stairs/forge
- Pick up item: `,`

**Ranged / songs / stealth**
- Fire from quiver: `f`/`F` (help shows `f F /`)
- Sing: `s`/`a` (depends keyset)
- Stealth mode: `S`

**Info / UI**
- Look at things: `l`
- Look around dungeon: `L`
- Map: `M`
- Main menu: `m`
- Ability screen: `Tab`
- Character sheet: `@`/`C`
- Options: `O`/`=`
- Prior messages: `^p`
- Redraw: `^r`
- Help: `?`

**Item actions**
- Use: `u`/`U`
- Drop: `d`
- Examine: `x`/`I`
- Throw: `t`/`v` (+ auto-target: `^t`/`^v`)
- Destroy: `k`
- Inscribe: `{`

**Meta**
- Save: `^s`
- Save and quit: `^x`
- Abort run: `Q`

## Gesture mapping (proposed)
### Core (must feel great)
- **1-finger swipe (8-dir)** → Move (dir)
- **1-finger flick (8-dir)** → Run (emit `.` then dir)
- **1-finger tap** → Wait (`z`)
- **1-finger double-tap** → Rest (`Z`)
- **2-finger tap** → `ESC` (universal cancel/back)
- **2-finger pan** → Scroll/pan viewport (when zoomed)
- **Pinch** → Zoom

### Interact / pickup
- **1-finger long-press then short nudge (8-dir)** → Interact-with-square (`/` or control + dir)
  - Rationale: reduces accidental “dig/open/disarm” while still quick.
- **2-finger swipe down** → Pick up (`g`) (canonical pickup command)

### Look / target (cursor mode)
- **1-finger long-press (hold ~350ms, no movement)** → Enter **Look Cursor Mode**
  - While in Look Cursor Mode:
    - **1-finger swipe** → move cursor (dir)
    - **1-finger tap** → confirm / describe / examine (likely `l`/`x` depending on what we choose)
    - **2-finger tap** → exit cursor mode (`ESC`)

### Navigation / reference
- **Left-edge swipe** → Prior messages (`^p`)
- **Right-edge swipe** → Help (`?`)

## Conflict rules (important)
- When the view is zoomed and the user is **two-finger panning**, we never treat it as movement.
- 1-finger pan gestures are interpreted as movement **only if**:
  - the swipe distance exceeds a threshold AND
  - the gesture begins on the terminal view AND
  - (optional) the user is not currently in a “scroll intent” state.

## Implementation notes (for `SilViewController`)
- All gestures should funnel into a single key-emission path that calls `Term_keypress()`.
- Keep a small state machine:
  - `Normal`
  - `LookCursorMode`
- Prefer `UISwipeGestureRecognizer` only for 4-dir; for 8-dir use `UIPanGestureRecognizer` and quantize the angle.

## Open questions
- **Rest variants:** do we want a distinct gesture for `z` (wait) vs `Z` (rest), or is tap/double-tap good enough?
- **Interact-with-square:** do we want a dedicated “interact mode” toggle instead of “long-press then nudge”?
- **Fire/throw auto-target:** should we add a safe gesture (e.g. long-press on monster) to trigger `^t`/`^v` or targeting `*`?
- **Keyboard coexistence:** should edge-swipe right open Help (`?`) or toggle the on-screen keyboard?
