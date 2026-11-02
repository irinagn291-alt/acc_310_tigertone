# Stubwell — Build Specification

> Portfolio app 384, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Close finished books with one saved quote that comes back on the same date every year.

| Field | Value |
| --- | --- |
| Product name | Stubwell |
| Bundle identifier | `com.stubwell.board` |
| Domain | https://stubwell-board.store |
| Contact URL | https://stubwell-board.store/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone (portrait, landscape left, landscape right) and iPad (all orientations) |
| Interface style | Dark |
| Asset prefix | `swl_` |
| User-Agent | `Stubwell/1.0 (iOS; +https://stubwell-board.store)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Stubwell -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A reader closes a finished volume by filing one saved slip onto an anniversary stub, then nails that excerpt to today's board when the same month-and-day returns.

### 2.1 User flow

1. On Quotes home, tap Nail to seat today's due stub excerpt on the board
2. Open Shelf, pick a held volume, capture or select a slip, and Close to file its anniversary stub
3. From Quotes, peel a mistaken nail and return the stub to the well for a future due day
4. Open Shelf to add a new held volume and write slips at the current page while reading
5. Open Dashboard to see the next due stubs, filed count, and nails logged this year
6. From Settings, export the stub well and reset local data

### 2.2 Essential behaviour

- Shelf of held and closed volumes with spine progress while held
- Slip capture pinned to current page per volume
- Close-and-file chooses one slip and writes an MMDD-keyed anniversary stub into the well
- Quotes board fold Bare | Due | Nailed with Nail and Peel as the home verbs
- Dashboard of upcoming MMDD matches and nail history by daykey
- UserDefaults+Codable local archive with simulator seed that leaves today Due so Nail is live

---

## 3. Uniqueness assignment for Stubwell

| Axis | Assigned value |
| --- | --- |
| Architecture | **Stub ADT fold (Bare | Due | Nailed); the board is a fold over daykey Boards; Close on a Held Volume with a chosen Slip writes FileMark, archives an anniversary Stub keyed by MMDD, and moves the Volume to Closed; when today's MMDD matches a waiting Stub the board folds Bare to Due; Nail writes NailMark, seats the Stub's Slip on the Board, and folds Due to Nailed; Nail on Bare writes EarlyMark; a second Nail on the same daykey while Nailed is refused until Peel; Peel drops NailMark and folds Nailed to Bare while returning the Stub to the Well; Close on Held without a chosen Slip writes HollowMark; empty board writes Blank** |
| UI approach | **SwiftUI UIKit mix via UIViewRepresentable · dc5b22bf99** |
| Naming convention | **Ex libris / anniversary-stub lexicon (Volume, Slip, Stub, Well, Board, FileMark, NailMark, EarlyMark, HollowMark, Peel, Blank)** |
| File organization | **By stub role (Volume, Slip, Stub, Well, Board, FileMark, NailMark, EarlyMark, HollowMark, Peel, Blank) · dc5b22bf99** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **binance · void-moment · soft** |
| Typography | **Copperplate** |
| Navigation pattern | **Stub-locked chrome (today's due stub card and nailed excerpt never leave; Shelf and Dashboard arrive as sheets; close-and-file and nail fuse on Quotes; Settings as a sheet; no tab bar)** |
| AI art style | **Vaporwave · tactile** |
| Functional twist | **File-then-nail (Close files an MMDD Stub; Nail on Due seats the excerpt; Nail on Bare refused with EarlyMark; second Nail same daykey refused until Peel)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — book_quotes

**Core** — A reader closes a finished volume by filing one saved slip onto an anniversary stub, then nails that excerpt to today's board when the same month-and-day returns.

**Audience** — Readers who finish books and want one chosen line to resurface on a calendar rhythm after the copy is gone—not live marginalia, not a daily cento, not a lemma puzzle, and not a three-card fan.

**User flow**

1. On Quotes home, tap Nail to seat today's due stub excerpt on the board
2. Open Shelf, pick a held volume, capture or select a slip, and Close to file its anniversary stub
3. From Quotes, peel a mistaken nail and return the stub to the well for a future due day
4. Open Shelf to add a new held volume and write slips at the current page while reading
5. Open Dashboard to see the next due stubs, filed count, and nails logged this year
6. From Settings, export the stub well and reset local data

**Essential features**

- Shelf of held and closed volumes with spine progress while held
- Slip capture pinned to current page per volume
- Close-and-file chooses one slip and writes an MMDD-keyed anniversary stub into the well
- Quotes board fold Bare | Due | Nailed with Nail and Peel as the home verbs
- Dashboard of upcoming MMDD matches and nail history by daykey
- UserDefaults+Codable local archive with simulator seed that leaves today Due so Nail is live

**Twist** — File-then-nail fold. Phases

**Why this is not a repeat** — Same family as Margent, Refrain, Posy, and Pastedown but a different persisted verb: calendar anniversary stubs filed at close and nailed on the due date, not mark-gone hollow spines, lemma triptychs, posy fan rituals, or adjacent-volume cento paste. Uses uniqueness-graph axis placeholders (bookquotes UI suffix, binance void-moment soft, typographic gradient mesh) without copying Margent's Volume ADT, spine tabs, or Open Library scan loop.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Shelf of spines. Drill shelf → book → margin.
- Invariant: One quote-store per book. Verdict is reread / not — no stars. progressFraction = currentPage/totalPages.
- Never: Not a store catalog crate.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

The board is a fold over daykey Boards with phases Bare | Due | Nailed, where an empty board writes Blank and a well with no match today stays Bare. A Volume is Held or Closed, keeps one quote-store of Slips, stores a reread verdict as yes or no with no stars, and exposes progressFraction as currentPage divided by totalPages while Held, freezing that fraction once the Volume is Closed, and unit tests lock those three rules. Close on a Held Volume with a chosen Slip writes FileMark, archives one anniversary Stub in the Well keyed by that close date's MMDD, and moves the Volume to Closed. When today's MMDD matches a waiting Stub, the board folds Bare to Due before the first frame, and if several Stubs share that MMDD the oldest FileMark is the one that becomes due. Nail writes NailMark, seats that Stub's Slip on the Board by identity so the line lives only in the volume quote-store, and folds Due to Nailed for that daykey. Nail on Bare writes EarlyMark and the board stays Bare, a second Nail on the same daykey while Nailed is refused until Peel, Peel drops NailMark and folds Nailed to Bare while returning the Stub to the Well so the match pass can fold the board back to Due, and Close on Held without a chosen Slip writes HollowMark.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

The only UIKit surface is BoardPlateView, a UIViewRepresentable on Quotes that hosts the excerpt plate. Every sheet, list, and settings screen is stock SwiftUI. The live metric is progressFraction, current page divided by total pages, drawn with a numeric content transition, contentTransition(.numericText()), on Text(value, format: .number.precision(.fractionLength(0...1))), so the figure ticks in place when the reader changes the page, and the same transition updates the due slip's page numeral when Nail seats an excerpt. The one haptic is a single impact from UIImpactFeedbackGenerator when Nail commits. Peel, Close book, sheet navigation, and every refused mark stay silent. The one gesture is a vertical pan on that plate while the board is Nailed: the excerpt follows the finger and fades as the drag grows, release past half the plate height commits Peel, and a shorter release snaps back. Reduce Motion keeps the fade and drops the travel. Nail's pressed state uses press scale 0.97 for 140 to 180 milliseconds ease-out, and sheets scale from 0.96 to 1 with a fade. Reduce Motion uses opacity only.

### 3.3 Naming contract

Convention: Ex libris / anniversary-stub lexicon (Volume, Slip, Stub, Well, Board, FileMark, NailMark, EarlyMark, HollowMark, Peel, Blank).

Examples to follow: `Volume`, `Stub`, `nailDue(_:)`, `BoardPlateView`

### 3.4 Dependency contract

Zero external dependencies. No Swift Package Manager entry, no CocoaPods, and no vendored source. Linked system frameworks are SwiftUI, Foundation, UIKit, and Core Graphics. UIKit exists for the one BoardPlateView representable, and Core Graphics is limited to that plate's hairline relief. Do not import AVFoundation or Vision. This product does not use the camera. Do not call URLSession against an external catalog or Open Food Facts. Lines are typed on the device. There is no analytics SDK and no web view. Copperplate is built into iOS, so the app bundles no font file.

### 3.5 Navigation contract

Stub-locked chrome with no TabView. Quotes stays on screen: the due stub card, and after Nail the excerpt, never leave the root. Shelf and Dashboard are sheets. Settings is a sheet. Close book lives on the held-volume page presented over Quotes, and Nail and Peel live on the Quotes root, so the two commits share one session. The root has no back button. Sheets dismiss with Close on their own stack. Icon-only controls for Shelf, Dashboard, and Settings sit inside the button label with contentShape and a 44 point minimum, each with a VoiceOver label. The primary Nail control is full width at the bottom of the void. Onboarding Next and Continue are full width at the bottom. Review keys are launch arguments, not destinations in a tab bar.

### 3.6 Screen composition contract

Stub-root fused quotes (Quotes holds the due stub card and fused nail and peel; Shelf and Dashboard arrive as sheets; Settings as sheet; maps family Shelf|Quotes|Dashboard|Settings with Quotes home; no TabView). Physical screens are Onboarding, Quotes, Shelf, the held-volume page, the closed-volume page, Dashboard, and Settings. Onboarding is three pages, full-width Next or Continue at the bottom, and the Simulator seed marks it complete so the first frame is Quotes. Quotes is the root and the mechanic: one excerpt plate, one phase caption, and Nail plus Peel. It has no back button, and the navigation title is never the product name. Shelf, Dashboard, and Settings are sheets over that root and dismiss with Close on their own stack. On a held volume the reader changes the current page, writes a Slip pinned to that page, sets reread to yes or no, and taps Close book. Filing a stub whose month and day is today updates the Quotes board under the sheet, so close-and-file and Nail belong to one Quotes session. A closed volume shows the frozen fraction and its lines and accepts no new slip. Dashboard puts the next due stub in one hero, then a different list of later dates, then nails grouped by day. It does not use three equal cards. Settings holds export of the stub well, a reset confirm that names deletion of every local book and line, the contact link https://stubwell-board.store/contact-us, and replay of onboarding. Status copy is short. Due. Nail this line. Nailed. Line is up. Bare. Next line is later. No line chosen. Pick one, then close the book. Not due. This line waits. Already up. Lift it first. Empty Shelf fills the page with max height infinity: headline The shelf is empty, line Set down your first book, and leave a thought in the margins, button Add a book. Empty Quotes, when nothing is filed, fills the page the same way: Nothing is due. File a finished book, and one line comes back on its date. Button Add a book. The seeded home is the Due plate with Nail enabled, not that empty page. On iPad the plate and the shelf rows use the full width, edge to edge, and the background fills the safe area. Read ProcessInfo arguments once after onboarding. Launch keys, each a different frame, are today for Quotes Due, log for Dashboard, goals for Shelf, volume for a held volume, file for Close book with a slip chosen, closed for a finished volume, nailed for Quotes with the excerpt up and Peel available, and settings for Settings. Those keys are not tabs.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By stub role (Volume, Slip, Stub, Well, Board, FileMark, NailMark, EarlyMark, HollowMark, Peel, Blank) · dc5b22bf99**

```
Stubwell/
  StubwellApp.swift
  Volume/Volume.swift
  Slip/Slip.swift
  Stub/Stub.swift
  Well/Well.swift
  Stub/FileMark.swift
  Board/Board.swift
  Board/BoardFold.swift
  Board/NailMark.swift
  Board/EarlyMark.swift
  Board/HollowMark.swift
  Board/Peel.swift
  Board/Blank.swift
  Board/BoardPlateView.swift
  Quotes/QuotesView.swift
  Shelf/ShelfView.swift
  Shelf/VolumePage.swift
  Dashboard/DashboardView.swift
  Settings/SettingsView.swift
  Archive/StubArchive.swift
  Archive/DayKey.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Shelf
A first-class screen for **Shelf**. Must render empty, populated and error states.

### 5.3 Quotes
A first-class screen for **Quotes**. Must render empty, populated and error states.

### 5.4 Dashboard
A first-class screen for **Dashboard**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Book** — named per this app's convention.
- **Quote** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **binance · void-moment · soft**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#182211` | Screen background |
| `surface` | `#222F18` | Cards, rows, sheets |
| `ink` | `#EFF2ED` | Primary text and icons |
| `accent` | `#93E25A` | Primary action, key figure, progress fill |
| `muted` | `#9BB389` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Stubwell/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Copperplate**

Copperplate is the assigned face, reached through one accessor that wraps UIFont in UIFontMetrics so sizes track Dynamic Type. The type move on Quotes is one display size, then caption, with no third weight on that screen. The excerpt on the plate is the display step: Copperplate, wide tracking, short and wide, usually one or two lines and never more than four. It keeps its height with vertical fixedSize or an internal scroll so a flexible sibling cannot compress it. Text is never passed through a clip. The phase word Due, Nailed, or Bare is the only caption under that display. Sheets may use the rest of a six-step scale behind the same accessor: display, title, headline, body, caption, and micro. Body stays near 17 points, and no step goes under 12 points. Long lines and sizes above accessibility-1 fall back to New York so Copperplate does not clip. Page numbers, progressFraction, filed counts, and nail totals use Text(value, format: .number.precision(.fractionLength(0...1))) with monospaced digits, never NumberFormatter or String(format:). Day edges use Calendar.current.startOfDay, then an Int in YYYYMMDD form. The anniversary key is that integer modulo 10000, and the reader sees a date format rather than the raw integer.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **12pt** for cards, sheets and primary surfaces; **8pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI UIKit mix via UIViewRepresentable · dc5b22bf99**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI UIKit mix via UIViewRepresentable · dc5b22bf99** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **agency** (High-end agency: huge type, air, one accent, hairline depth.)

Reference system: **binance** — steal rhythm and restraint, not their colours or logos.

Mood: **Crypto exchange. Bold yellow accent on monochrome, trading-floor urgency.**.

Home rhythm (`void-moment`, comfortable): A calm void and one jewel. Almost no chrome.

High-end agency: huge type, air, one accent, hairline depth. Layout `void-moment`, density comfortable. Kit 12/8, material, bordered prominent. Palette recipe `soft`. Press scale 0.97, 140-180ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion: opacity only. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: One display size, then caption. No third weight on home. Reference type feel: agency.

Motion (`snap`): Press scale 0.97, 140-180ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion: opacity only.

Voice (`tactical`): Status-first. Noun plus state. 'Scan failed. Try again.'

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- iPhone allows portrait, landscape left, and landscape right. iPad allows all
  four orientations. Keep both lists in the Info settings, and let a rotated
  screen scroll instead of clipping.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Every headline, amount, and button title is fully visible. Do not give display
  type a fixed height shorter than the font, and do not let a sibling with
  `maxHeight: .infinity` compress it. When the column is taller than the screen,
  scroll it. `.clipped()` frames an image cell; it never wraps text.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Spacing uses a base of 4: 4, 8, 12, 16, 20, 24, 32, 40, 48, in one `Spacing`
  enum next to `DesignTokens`. No other values.

**Keyboard**

- Decimal fields use `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with a `FormatStyle`, never `NumberFormatter` or
  `String(format:)`. Example:
  `Text(value, format: .number.precision(.fractionLength(0...1)))`.
  Group separators and decimal separators follow the locale.
- Whole units show no decimals. Measured values show at most one decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown values render as a dash or the word "unknown", never as 0.
- A changing metric uses `.contentTransition(.numericText(value:))` with the
  shared spring, on the same value the text shows.
- A custom drag, magnification, or rotation shows its in-flight value through
  `@GestureState` and `.updating`. The committed value changes in `.onEnded`.
- Loading rows use `.redacted(reason: .placeholder)` at the size they will have
  when the data arrives.
- A form with more than one field chains focus with an `@FocusState` enum.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- State changes use one shared spring token. A `PhaseAnimator` or
  `KeyframeAnimator` is only the single signature moment on a view, triggered
  by a value, never a loop on appear.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- The root screen has no back button. `.navigationTitle` is a screen name, never
  the product name. A back control titled with the app name is a defect: it
  reads as a button that returns to this same app.
- A sheet dismisses with Close and owns its stack. Do not push it onto a stack
  whose title is the product name.
- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- A ring or a gauge uses the same `lineWidth` for the track and the fill.
- Display type does not use `.minimumScaleFactor`. Adapt with `ViewThatFits`
  or `dynamicTypeSize.isAccessibilitySize`, and scroll the column.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.
- An actor method re-checks its state after every `await`. Do not force-unwrap
  a lookup that happened before the await. The value may be gone.
- Filter `CancellationError` out before showing error UI or retrying.
  Cancellation is a normal end, not a failure.
- Build streams with `AsyncStream.makeStream(of:)` or the throwing variant.
  Pass a bounded `bufferingPolicy`, and set `onTermination` so the producer
  stops when the consumer does.
- CPU work uses `@concurrent`. Do not run it on `@MainActor`. The scaffold does
  not turn on default main-actor isolation, so UI types still need an explicit
  `@MainActor`.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

Persistence is UserDefaults plus Codable. One root record, StubArchive, is JSON-encoded under the single key swl.board.v1 and holds Volumes, the Slips in each volume's quote-store, the Well of anniversary Stubs, daykey Boards, and FileMark, NailMark, EarlyMark, and HollowMark values. A debounced save runs after each mark, and the archive flushes when scenePhase becomes inactive or background and immediately after reset. schemaVersion starts at 1. A decode failure keeps the previous good archive, shows a plain error with reset as the path forward, and does not crash. The in-memory archive is the source of truth. Views talk to a repository and never touch UserDefaults. resetAllData is reachable from Settings and from tests. Export shares that same encoded archive. The Simulator seed runs once behind swl.demo.v1, only under targetEnvironment(simulator), writes four held volumes with slips at different pages and three closed volumes, one Stub whose MMDD matches today and two Stubs on later month-days, sets today's board to Due so the home verb Nail is enabled, marks onboarding complete, and never runs on a device. A day key is an Int in YYYYMMDD form taken from Calendar.current.startOfDay. The stub anniversary key is that integer modulo 10000.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Stubwell/1.0 (iOS; +https://stubwell-board.store)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.
No scanner and no remote catalog in this product. Do not import AVFoundation or Vision for capture, do not add a camera usage description, and do not call a search endpoint. Ignore a leftover scanner or search axis.


---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- iPhone: portrait, landscape left, landscape right. iPad: all four orientations (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: File-then-nail (Close files an MMDD Stub; Nail on Due seats the excerpt; Nail on Bare refused with EarlyMark; second Nail same daykey refused until Peel)

The home verb is Nail, and the Simulator seed leaves it enabled on the first frame by filing one Stub for today's MMDD and setting that daykey Board to Due. Nail on Due seats the excerpt and folds Due to Nailed. Unit tests must refuse Nail on Bare, which writes EarlyMark and leaves the board Bare. The same tests refuse a second Nail on that daykey while Nailed until Peel, and they refuse Close without a chosen Slip, which writes HollowMark and leaves the Volume Held. After Peel the Stub is back in the Well, and the seed itself does not open on Bare or on Nailed.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Vaporwave · tactile**


Base prompt, reused and extended for every asset:

```
Vaporwave still life, tactile and physical. Ridged relief, ribbed paper, a short metal fastener, and a closed book block, presented as a quiet product sample. Grain, fiber, and fingerprint-scale texture stay visible. One solid opaque subject occupies the center. All four corners stay empty. No hollow frame, no wire outline, no glass box, no lettering, no logo, no painted color recipe.
```

All 7 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `swl_` prefix.

### 13.1 App icon

Do not generate an app icon. Do not create an AppIcon image set and do not
paint icon artwork. The factory installs the icon later. Leave the empty
AppIcon.appiconset from the scaffold untouched.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `swl_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 2 | `swl_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 3 | `swl_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 4 | `swl_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 5 | `swl_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'File-then-nail (Close files an MMDD Stub; Nail on Due seats the excerpt; Nail on Bare refused with EarlyMark; second Nail same daykey refused until Peel)' feature screen. |
| 6 | `swl_WellStack` | 1024x1024 | **required cutout** | A solid stack of thick paper stubs, each card heavy and opaque, centered, tactile vaporwave still life |
| 7 | `swl_SpineBlock` | 1024x1024 | **required cutout** | One solid book block standing upright with a thick opaque paper slip emerging from the pages, centered, tactile |

### Prompt per asset

**`swl_Onboarding1`** — 1024x1536

```
A person holding one closed book with a single thick paper slip tucked at the page edge, tactile vaporwave still life, solid opaque subject in the center

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_Onboarding2`** — 1024x1536

```
A hand pressing a short metal fastener through one paper slip onto a flat board, mid gesture, tactile and solid, opaque subject in the center

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_Onboarding3`** — 1024x1536

```
A small row of closed books with several thick paper slips standing in front, the later moment when lines have accumulated, solid opaque subjects in the center

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_EmptyHome`** — 1024x1024

```
A solid closed wooden box with a folded cloth on its lid, waiting, fully opaque wood and cloth, calm, not glass, subject filling the center

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_TwistHero`** — 1024x1024

```
One thick paper slip pierced by a single short metal fastener, the signature object, solid and opaque in the center

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_WellStack`** — 1024x1024

```
A solid stack of thick paper stubs, each card heavy and opaque, centered, tactile vaporwave still life

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`swl_SpineBlock`** — 1024x1024

```
One solid book block standing upright with a thick opaque paper slip emerging from the pages, centered, tactile

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`swl.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.
- `AnyView`, or a `View.if` helper that applies modifiers conditionally.
- `Binding(get:set:)` built inline inside `body`.
- `GeometryReader` inside a lazy stack or a lazy grid.
- `@AppStorage` on an `@Observable` class. `@Query` outside a `View`.
- `MagnificationGesture` or `RotationGesture`. Use `MagnifyGesture` and
  `RotateGesture`.
- `String(format:)` or `NumberFormatter` for a number the UI shows. Use a
  `FormatStyle` on `Text`.


---

## 17. Tests

Add a unit test target `StubwellTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Stubwell/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Stubwell -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.
- [ ] Do not add a watchOS app target. Apple Watch store images are fitted from the iPhone screenshots.

**Uniqueness**
- [ ] Architecture matches **Stub ADT fold (Bare | Due | Nailed); the board is a fold over daykey Boards; Close on a Held Volume with a chosen Slip writes FileMark, archives an anniversary Stub keyed by MMDD, and moves the Volume to Closed; when today's MMDD matches a waiting Stub the board folds Bare to Due; Nail writes NailMark, seats the Stub's Slip on the Board, and folds Due to Nailed; Nail on Bare writes EarlyMark; a second Nail on the same daykey while Nailed is refused until Peel; Peel drops NailMark and folds Nailed to Bare while returning the Stub to the Well; Close on Held without a chosen Slip writes HollowMark; empty board writes Blank** with no leakage across layers.
- [ ] UI approach matches **SwiftUI UIKit mix via UIViewRepresentable · dc5b22bf99**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Stub-locked chrome (today's due stub card and nailed excerpt never leave; Shelf and Dashboard arrive as sheets; close-and-file and nail fuse on Quotes; Settings as a sheet; no tab bar)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Copperplate** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Stubwell
xcodegen generate
xcodebuild build-for-testing -scheme Stubwell -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling_factory/.artifacts/genesis/com.stubwell.board/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Stubwell -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling_factory/.artifacts/genesis/com.stubwell.board/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Stubwell -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling_factory/.artifacts/genesis/com.stubwell.board/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
