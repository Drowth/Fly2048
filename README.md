# Fly2048

Fly2048 is a lightweight 2048 mini-game for World of Warcraft, designed for taxi flights, queues, and other downtime. It includes animated tiles, sound feedback, a once-per-game Divine Reset, automatic taxi-flight display, and a live guild leaderboard shared with other Fly2048 users.

## Supported clients

- WoW Retail: Midnight 12.1 (`Fly2048_Mainline.toc`, Interface `120100`)
- WoW Classic Anniversary: Burning Crusade Classic 2.5.6 (`Fly2048.toc`, Interface `20506`)

Both clients use the same guarded Lua implementation and SavedVariables schema so fixes do not drift between editions.

## Beta visual refresh

Version `1.1.0-beta.1` introduces the Arcane Flight interface:

- Curated Arcane and Ember colour palettes
- Adaptive tile text contrast and milestone styling
- Cleaner score cards and guild flightboard
- Merge-chain feedback and animated score gains
- Subtle board-pressure and leaderboard update effects
- Full and reduced-motion modes
- Saved window position and UI scale
- Retail AddOn Compartment support

This work is isolated on the `feature/dynamic-ui-retail` branch until it has completed in-game testing.

## Installation

Copy the `Fly2048` folder into the appropriate client directory:

- Retail: `World of Warcraft/_retail_/Interface/AddOns/`
- Classic Anniversary: `World of Warcraft/_anniversary_/Interface/AddOns/`

The resulting path must end in `Interface/AddOns/Fly2048/Fly2048.lua`. Fully restart the WoW client after changing TOC files; `/reload` alone does not refresh TOC selection.

## Controls

- Arrow keys or WASD: move tiles
- `R`: restart the game
- `Esc`: close the window
- Drag the outer frame: reposition it
- `/fly2048`: show or hide

## Commands

- `/fly2048 reset` — start a new game
- `/fly2048 mute` — toggle sound
- `/fly2048 auto` — toggle automatic taxi-flight display
- `/fly2048 theme` — cycle the colour theme
- `/fly2048 theme arcane|ember` — select a theme directly
- `/fly2048 motion full|reduced` — set animation intensity
- `/fly2048 scale 0.75-1.25` — resize the interface
- `/fly2048 center` — return the window to screen centre
- `/fly2048 demo` — load a visual palette and animation test board
- `/fly2048 test` and `/fly2048 testclear` — add or remove guild leaderboard test data
- `/fly2048 help` — show the command summary

On Retail, Fly2048 also appears in the AddOn Compartment. Left-click it to play or right-click it to change theme.

Retail Midnight can restrict add-on messaging inside instanced content. Fly2048 detects that state and skips guild score broadcasts until messaging is available again; the game itself remains fully functional.

## Beta verification checklist

Enable Lua errors with `/console scriptErrors 1`, restart the client, and verify:

1. The add-on loads without being marked out of date.
2. Movement and merging work with both keyboard layouts.
3. Rapid input queues only one follow-up direction and never duplicates tiles.
4. Theme, motion, sound, scale, position, best score, and auto-popup persist after `/reload`.
5. Divine Reset works once per game and resets on a new game.
6. `/fly2048 demo` displays every tile tier legibly in both themes.
7. `/fly2048 test` displays and animates guild ranking rows.
8. Taxi auto-popup opens and closes at the correct time.
9. Retail's AddOn Compartment click and tooltip actions work.
10. No new errors appear in BugSack/BugGrabber after a complete game.
