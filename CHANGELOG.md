# Changelog

## 1.2.0-beta.1

- Rebuilt the interface with Blizzard art: dialog-box frame and header plate, tooltip-style panels, and standard red UI buttons.
- The board is now a 4x4 bag of empty item slots; tiles are loot icons with item-quality borders (Poor through Heirloom) and outlined numbers.
- Replaced the Arcane and Ember themes with Alliance and Horde. The theme defaults to your faction and old saved themes migrate automatically (schema 3).
- Added the faction crest as a watermark behind the guild flightboard.
- Rank 1 on the flightboard wears the leader crown and guild names show in class colours. Score broadcasts now carry the class (older clients still receive the legacy message).
- Esc closes the window through UISpecialFrames.
- Blizzard sound effects now use PlaySound with SoundKit ids, so they are audible on Retail as well as Classic.

## 1.1.0-beta.1

- Added Retail Midnight 12.1 support through `Fly2048_Mainline.toc`.
- Added Retail AddOn Compartment controls.
- Added Arcane and Ember themes with value-specific tile palettes.
- Reworked the frame, score presentation, board, buttons, leaderboard, and game-over panel.
- Added adaptive tile text contrast and high-value milestone treatments.
- Added merge-chain feedback, score-card rollups, leaderboard pulses, and restrained pressure effects.
- Added reduced-motion mode, UI scaling, and saved window position.
- Preserved the existing best score, guild scores, mute setting, and taxi auto-popup setting.
