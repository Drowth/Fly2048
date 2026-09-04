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
lua.execute((ROOT / "Fly2048" / "Fly2048.lua").read_text(encoding="utf-8"))

trigger_event = lua.globals().Fly2048_TestTriggerEvent
run_updates = lua.globals().Fly2048_TestRunUpdates
slash = lua.globals().SlashCmdList["FLY2048"]

trigger_event("ADDON_LOADED", "Fly2048")
trigger_event("PLAYER_ENTERING_WORLD")
slash("")

frame = lua.globals().Fly2048Frame
for key in ("LEFT", "UP", "RIGHT", "DOWN", "A", "W", "D", "S"):
    frame.Trigger(frame, "OnKeyDown", key)
    run_updates(4, 0.05)

for command in (
    "theme ember",
    "theme arcane",
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

lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", "LeftButton")
lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", lua.table_from({"buttonName": "RightButton"}))
lua.globals().Fly2048_OnAddonCompartmentEnter("Fly2048", frame)
lua.globals().Fly2048_OnAddonCompartmentLeave("Fly2048", frame)

print("Fly2048 mocked WoW smoke test OK")
