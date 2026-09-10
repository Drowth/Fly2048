"""Load Fly2048 in a strict mocked WoW runtime and exercise public flows."""

from pathlib import Path
import sys

try:
    from lupa import LuaRuntime
except ImportError:
    raise SystemExit("Install the test dependency with: python -m pip install lupa")


ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT / "tests" / "wow_stub.lua").read_text(encoding="utf-8"))
# Pre-seed a 1.1 saved theme so the faction migration path is exercised.
lua.execute('Fly2048DB = { theme = "arcane" }')
lua.execute((ROOT / "Fly2048" / "Fly2048.lua").read_text(encoding="utf-8"))

trigger_event = lua.globals().Fly2048_TestTriggerEvent
run_updates = lua.globals().Fly2048_TestRunUpdates
run_timers = lua.globals().Fly2048_TestRunTimers
slash = lua.globals().SlashCmdList["FLY2048"]

trigger_event("ADDON_LOADED", "Fly2048")
trigger_event("PLAYER_ENTERING_WORLD")
slash("")

db = lua.globals().Fly2048DB
assert db.theme == "horde", f"expected faction default theme, got {db.theme!r}"
assert db.schemaVersion == 3, f"expected schema 3, got {db.schemaVersion!r}"
assert "Fly2048Frame" in list(lua.globals().UISpecialFrames.values()), "frame not registered for Esc"

# Guild messages: class-tagged, legacy, and a request that triggers a reply.
trigger_event("CHAT_MSG_ADDON", "Fly2048", "SCORE:5000:MAGE", "GUILD", "Arthas-TestRealm")
trigger_event("CHAT_MSG_ADDON", "Fly2048", "SCORE:4000", "GUILD", "Thrall-TestRealm")
trigger_event("CHAT_MSG_ADDON", "Fly2048", "REQUEST", "GUILD", "Jaina-TestRealm")
run_timers(10)
assert db.guildScores["Arthas-TestRealm"] == 5000
assert db.guildClasses["Arthas-TestRealm"] == "MAGE"
assert db.guildScores["Thrall-TestRealm"] == 4000

frame = lua.globals().Fly2048Frame
for key in ("LEFT", "UP", "RIGHT", "DOWN", "A", "W", "D", "S"):
    frame.Trigger(frame, "OnKeyDown", key)
    run_updates(4, 0.05)

for command in (
    "theme alliance",
    "theme horde",
    "theme",
    "motion reduced",
    "motion full",
    "scale 0.90",
    "center",
    "demo",
    "reset",
    "test",
    "testclear",
    "mute",
    "auto",
    "help",
):
    slash(command)
    run_updates(3, 0.05)

# Hidden corner buttons: each sets its own flag, then that tune fires on the
# next first open of a session. Both toggle independently.
assert not db.lostAtSea and not db.paperBag
frame.Trigger(frame, "OnShow")
frame.Trigger(frame, "OnShow")
for cmd, flag in (("lostatsea", "lostAtSea"), ("paperbag", "paperBag")):
    slash(cmd); assert db[flag], f"{cmd} did not set {flag}"
    frame.Trigger(frame, "OnShow")
    slash(cmd); assert not db[flag], f"{cmd} did not clear {flag}"

lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", "LeftButton")
lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", lua.table_from({"buttonName": "RightButton"}))
lua.globals().Fly2048_OnAddonCompartmentEnter("Fly2048", frame)
lua.globals().Fly2048_OnAddonCompartmentLeave("Fly2048", frame)

print("Fly2048 mocked WoW smoke test OK")
