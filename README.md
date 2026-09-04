# Fly2048

Fly2048 is a lightweight 2048 mini-game for World of Warcraft, designed for taxi flights, queues, and other downtime. It includes animated tiles, sound feedback, a once-per-game Divine Reset, automatic taxi-flight display, and a live guild leaderboard shared with other Fly2048 users.

## Supported clients

- WoW Retail: Midnight 12.1 (`Fly2048_Mainline.toc`, Interface `120100`)
- WoW Classic Anniversary: Burning Crusade Classic 2.5.6 (`Fly2048.toc`, Interface `20506`)

Both clients use the same guarded Lua implementation and SavedVariables schema so fixes do not drift between editions.

## Warcraft loot interface

Version `1.2.0-beta.1` rebuilds the look with Blizzard's own art:

- Dialog-box frame, header plate, tooltip-style panels and standard red buttons
- The board is a 4x4 bag of item slots; tiles are loot icons with item-quality borders, from Poor copper up to Heirloom dragon heads
- Alliance and Horde themes, defaulting to your faction, with the faction crest behind the guild flightboard
- Leader crown for rank 1 and class-coloured guild names on the flightboard
- Merge-chain feedback, animated score gains, board-pressure and leaderboard effects
- Full and reduced-motion modes, saved window position and UI scale
- Esc closes the window; Retail AddOn Compartment support

Saved `arcane` or `ember` themes from earlier betas migrate to your faction's theme on first load.

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
- `/fly2048 theme` — switch between Alliance and Horde colours
- `/fly2048 theme alliance|horde` — select a faction theme directly
- `/fly2048 motion full|reduced` — set animation intensity
- `/fly2048 scale 0.75-1.25` — resize the interface
- `/fly2048 center` — return the window to screen centre
- `/fly2048 demo` — load a visual palette and animation test board
- `/fly2048 test` and `/fly2048 testclear` — add or remove guild leaderboard test data
- `/fly2048 help` — show the command summary

On Retail, Fly2048 also appears in the AddOn Compartment. Left-click it to play or right-click it to switch faction colours.

Retail Midnight can restrict add-on messaging inside instanced content. Fly2048 detects that state and skips guild score broadcasts until messaging is available again; the game itself remains fully functional.

## Beta verification checklist

Enable Lua errors with `/console scriptErrors 1`, restart the client, and verify:

1. The add-on loads without being marked out of date.
2. Movement and merging work with both keyboard layouts.
3. Rapid input queues only one follow-up direction and never duplicates tiles.
4. Theme, motion, sound, scale, position, best score, and auto-popup persist after `/reload`.
5. Divine Reset works once per game and resets on a new game.
6. `/fly2048 demo` displays every tile tier with the right loot icon, quality border and a legible number in both factions, and no bag slot shows as a green square.
7. `/fly2048 test` displays and animates guild ranking rows, with the crown on rank 1.
8. Taxi auto-popup opens and closes at the correct time.
9. Retail's AddOn Compartment click and tooltip actions work.
10. No new errors appear in BugSack/BugGrabber after a complete game.
