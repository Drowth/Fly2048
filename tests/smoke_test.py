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
# Also seed the removed hidden-tune flags so their cleanup is exercised.
# and a pre-1.2.1 flat guild table, which must fold into the current guild.
lua.execute('Fly2048DB = { theme = "arcane", lostAtSea = true, paperBag = true, guildScores = { ["Old-TestRealm"] = 777 } }')
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
guild = db.guilds["Test Guild-TestRealm"]
assert db.guildScores is None, "flat legacy table was not migrated"
assert guild.scores["Old-TestRealm"] == 777, "legacy scores not folded into the current guild"
assert guild.scores["Arthas-TestRealm"] == 5000
assert guild.classes["Arthas-TestRealm"] == "MAGE"
assert guild.scores["Thrall-TestRealm"] == 4000

# The player's own broadcast arrives with the normalised realm ("TestRealm")
# while GetRealmName() returns "Test Realm". It must be recognised as local.
trigger_event("CHAT_MSG_ADDON", "Fly2048", "SCORE:9999:MAGE", "GUILD", "TestPilot-TestRealm")
assert guild.scores["TestPilot-TestRealm"] is None, "own score was stored as another guild member"

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

assert db.lostAtSea is None and db.paperBag is None, "removed tune flags were not cleared"
assert slash("lostatsea") is None  # falls through to the normal command handler

# Background sync: a REQUEST from a guildmate gets an invisible SCORE reply.
sent = lua.globals().Fly2048_TestSent
before = len(sent)
lua.globals().Fly2048_TestSendResult = 0
trigger_event("PLAYER_ENTERING_WORLD")
run_timers(50)
msgs = [sent[i] for i in range(before + 1, len(sent) + 1)]
assert any(m.startswith("Fly2048|REQUEST|GUILD") for m in msgs), f"no background REQUEST on login: {msgs}"

# Per-guild boards: an alt in another guild starts empty, and scores heard
# before the guild name loads land in that guild once it does.
lua.globals().Fly2048_TestGuild = "Other Guild"
trigger_event("PLAYER_GUILD_UPDATE")
assert db.guilds["Other Guild-TestRealm"] is not None
assert db.guilds["Other Guild-TestRealm"].scores["Arthas-TestRealm"] is None, "guild boards leaked"
lua.execute("GetGuildInfo = function() return nil end")
trigger_event("CHAT_MSG_ADDON", "Fly2048", "SCORE:1234", "GUILD", "Uther-TestRealm")
lua.execute('GetGuildInfo = function() return "Other Guild", "Member", 3, nil end')
trigger_event("PLAYER_GUILD_UPDATE")
assert db.guilds["Other Guild-TestRealm"].scores["Uther-TestRealm"] == 1234, "pending scores not settled"
assert db.guilds["_pending"] is None

# A refused send (non-zero result) queues one silent retry instead of erroring.
lua.globals().Fly2048_TestSendResult = 11
slash("sync")
run_timers(5)
lua.globals().Fly2048_TestSendResult = 0

lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", "LeftButton")
lua.globals().Fly2048_OnAddonCompartmentClick("Fly2048", lua.table_from({"buttonName": "RightButton"}))
lua.globals().Fly2048_OnAddonCompartmentEnter("Fly2048", frame)
lua.globals().Fly2048_OnAddonCompartmentLeave("Fly2048", frame)

print("Fly2048 mocked WoW smoke test OK")
