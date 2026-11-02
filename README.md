# Stubwell

Stubwell is for readers who finish a book and want one chosen line to come back on that month and day, after the copy is gone. It is a private shelf, not a catalog and not a rating site.

## Architecture

The board is a fold of day-key boards. Each board is a stub sum: Bare, Due, or Nailed. An empty well writes Blank. A well with no match today stays Bare.

That shape fits the product because the home verb is not "add a quote". The reader files a line once, when the volume closes, and the calendar brings it back. The phase is the whole screen. Quotes does not list records. It shows the fold for today and offers Nail or Peel.

Close on a held volume with a chosen slip writes FileMark, archives one anniversary stub keyed by that close date's month and day, and moves the volume to Closed. The match pass folds Bare to Due when today's month and day hits a waiting stub. If several stubs share that key, the oldest FileMark is the one that becomes due. Nail writes NailMark, seats that stub's slip by identity so the words stay in the volume's one quote-store, and folds Due to Nailed. Nail on Bare writes EarlyMark and leaves the board Bare. A second Nail on the same day key is refused until Peel. Peel drops NailMark, returns the stub to the well, and the match pass can fold the board to Due again. Close without a chosen slip writes HollowMark and leaves the volume held.

A volume has one quote-store. Reread is yes or no, with no stars. While held, progress is current page divided by total pages. Close freezes that fraction.

The in-memory StubArchive is the source of truth. BoardDesk publishes the folded face for the interface. StubStore is the only seam to UserDefaults and the atomic file under the key `swl.board.v1`.

## File, then nail

Filing and nailing are separate marks. Closing a book plants an anniversary. Nailing is allowed only when that anniversary is today and the board is Due. Peeling a mistaken nail puts the stub back so a later visit on the same month and day can seat it again.

## Look

Art direction is vaporwave and tactile, on a dark field with one acid accent (binance, void-moment, soft). Copperplate is the system face. No custom font file is bundled. Generated images are a later asset pass. No image prompt has been issued in this layer, so none is recorded here.

## How this differs

Same family of book quotes as other shelf apps, different persisted verb. Stubs are filed at close and nailed on the due date. This is not a hollow-spine tracker, a lemma triptych, a posy fan, or a cento pasted from neighboring volumes. There is no scan loop and no remote catalog.

## Build

```bash
cd apps/Stubwell
xcodegen generate
xcodebuild build-for-testing -scheme Stubwell -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

Signing flags and the derived-data path stay on the command line. The project does not set them.
