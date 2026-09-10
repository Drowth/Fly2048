-- Fly2048.lua
-- 2048 mini game for WoW Classic Anniversary and Retail.
-- Slash: /fly2048 help for controls and appearance commands.

Fly2048DB = Fly2048DB or {}

local ADDON_NAME = "Fly2048"

-- ==============================
-- Config
-- ==============================
local GRID = 4
local TILE_SIZE = 84
local TILE_PAD = 10
local HEADER_H = 92          -- header plate overhang + button row + status line
local FRAME_PAD = 24         -- 11px dialog-border inset + breathing room
local BOARD_INNER_W = GRID * TILE_SIZE + (GRID - 1) * TILE_PAD  -- 366
local LBOARD_GAP    = 14
local LBOARD_X      = FRAME_PAD + BOARD_INNER_W + LBOARD_GAP     -- 404
local SLOT_SCALE    = 1.30   -- UI-EmptySlot has transparent padding; tune 1.25-1.75 in-game

local ANIM_TIME = 0.10
local POP_TIME  = 0.12
local POP_SCALE = 1.12
local SPAWN_POP = 1.10
local SPAWN_TIME = 0.10

local FLASH_TIME = 0.08
local FLASH_ALPHA = 0.35

local SHAKE_DUR = 0.10
local SHAKE_AMP = 3

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- Blizzard art that ships in both Classic Anniversary (TBC) and Retail.
local TEX = {
  frameBg   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  frameEdge = "Interface\\DialogFrame\\UI-DialogBox-Border",
  header    = "Interface\\DialogFrame\\UI-DialogBox-Header",
  panelBg   = "Interface\\Tooltips\\UI-Tooltip-Background",
  panelEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
  slot      = "Interface\\Buttons\\UI-EmptySlot",
  glow      = "Interface\\Buttons\\UI-ActionButton-Border",
  star      = "Interface\\Cooldown\\star4",
  crown     = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
  dice      = "Interface\\Icons\\INV_Misc_Dice_02",
}
local BACKDROP_DIALOG = {
  bgFile = TEX.frameBg, edgeFile = TEX.frameEdge, tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
local BACKDROP_TOOLTIP = {
  bgFile = TEX.panelBg, edgeFile = TEX.panelEdge, tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Item quality colours (index = Enum.ItemQuality). ITEM_QUALITY_COLORS wins when present.
local QUALITY_COLORS = {
  [0] = { 0.62, 0.62, 0.62 }, [1] = { 1.00, 1.00, 1.00 }, [2] = { 0.12, 1.00, 0.00 },
  [3] = { 0.00, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
  [6] = { 0.90, 0.80, 0.50 }, [7] = { 0.00, 0.80, 1.00 },
}

-- Every tile is a piece of loot: an icon plus an item quality. Pairs of values
-- share a quality; the lower of each pair is drawn dimmed.
local ICON = "Interface\\Icons\\"
local TILE_LOOT = {
  [2]    = { icon = ICON .. "INV_Misc_Coin_05",           quality = 0, dim = false }, -- copper, Poor
  [4]    = { icon = ICON .. "INV_Misc_Coin_03",           quality = 1, dim = false }, -- silver, Common
  [8]    = { icon = ICON .. "INV_Misc_Coin_01",           quality = 2, dim = true  }, -- gold, Uncommon
  [16]   = { icon = ICON .. "INV_Misc_Gem_Emerald_02",    quality = 2, dim = false },
  [32]   = { icon = ICON .. "INV_Misc_Gem_Sapphire_02",   quality = 3, dim = true  }, -- Rare
  [64]   = { icon = ICON .. "INV_Misc_Orb_05",            quality = 3, dim = false },
  [128]  = { icon = ICON .. "INV_Misc_Gem_Amethyst_02",   quality = 4, dim = true  }, -- Epic
  [256]  = { icon = ICON .. "INV_Misc_QirajiCrystal_05",  quality = 4, dim = false },
  [512]  = { icon = ICON .. "INV_Hammer_Unique_Sulfuras", quality = 5, dim = true  }, -- Legendary
  [1024] = { icon = ICON .. "INV_Sword_39",               quality = 5, dim = false }, -- Thunderfury
  [2048] = { icon = ICON .. "INV_Staff_13",               quality = 6, dim = false }, -- Atiesh, Artifact
  [4096] = { icon = ICON .. "INV_Misc_Head_Dragon_01",    quality = 7, dim = true  }, -- Heirloom
  [8192] = { icon = ICON .. "INV_Misc_Head_Dragon_Black", quality = 7, dim = false },
}
local TILE_LOOT_DEFAULT = { icon = ICON .. "Spell_Fire_Fire", quality = 7, dim = false }

-- Faction themes tint the Blizzard textures. Keys accent/accentSoft/gold/text/
-- muted/danger/success are used by animations and text throughout.
local THEMES = {
  alliance = {
    name = "Alliance", subtitle = "FOR THE ALLIANCE!",
    crest = "Interface\\Timer\\Alliance-Logo",
    frameBg = { 0.55, 0.65, 1.00, 1 }, frameEdge = { 1, 1, 1, 1 },
    panel = { 0.16, 0.24, 0.48, 0.94 }, panelAlt = { 0.22, 0.32, 0.60, 0.94 }, board = { 0.07, 0.10, 0.22, 1 },
    border = { 0.85, 0.70, 0.30, 1 },
    cell = { 0.78, 0.86, 1.00, 1 },
    accent = { 0.40, 0.65, 1.00, 1 }, accentSoft = { 0.25, 0.40, 0.75, 0.45 },
    gold = { 1.00, 0.82, 0.00, 1 }, text = { 1, 1, 1, 1 }, muted = { 0.70, 0.76, 0.90, 1 },
    danger = { 1.00, 0.25, 0.25, 1 }, success = { 0.30, 0.95, 0.45, 1 },
  },
  horde = {
    name = "Horde", subtitle = "FOR THE HORDE!",
    crest = "Interface\\Timer\\Horde-Logo",
    frameBg = { 1.00, 0.45, 0.40, 1 }, frameEdge = { 1, 1, 1, 1 },
    panel = { 0.30, 0.08, 0.06, 0.94 }, panelAlt = { 0.42, 0.11, 0.08, 0.94 }, board = { 0.10, 0.03, 0.03, 1 },
    border = { 0.75, 0.25, 0.15, 1 },
    cell = { 1.00, 0.80, 0.75, 1 },
    accent = { 1.00, 0.35, 0.20, 1 }, accentSoft = { 0.65, 0.15, 0.10, 0.45 },
    gold = { 1.00, 0.82, 0.00, 1 }, text = { 1, 1, 1, 1 }, muted = { 0.85, 0.70, 0.65, 1 },
    danger = { 1.00, 0.20, 0.20, 1 }, success = { 0.55, 0.95, 0.30, 1 },
  },
}
local THEME_ORDER = { "alliance", "horde" }

local CLASS_COLORS_FALLBACK = {
  WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 }, HUNTER = { 0.67, 0.83, 0.45 },
  ROGUE = { 1.00, 0.96, 0.41 }, PRIEST = { 1.00, 1.00, 1.00 }, SHAMAN = { 0.00, 0.44, 0.87 },
  MAGE = { 0.25, 0.78, 0.92 }, WARLOCK = { 0.53, 0.53, 0.93 }, DRUID = { 1.00, 0.49, 0.04 },
  DEATHKNIGHT = { 0.77, 0.12, 0.23 }, MONK = { 0.00, 1.00, 0.59 }, DEMONHUNTER = { 0.64, 0.19, 0.79 },
  EVOKER = { 0.20, 0.58, 0.50 },
}

-- Custom Sound Path
local SOUND_PATH = "Interface\\AddOns\\Fly2048\\media\\sound\\"
local CHORDS = {
  SOUND_PATH .. "a4.ogg",
  SOUND_PATH .. "b4.ogg",
  SOUND_PATH .. "c4.ogg",
  SOUND_PATH .. "c5.ogg",
  SOUND_PATH .. "d4.ogg",
  SOUND_PATH .. "g4.ogg",
}

-- Blizzard sounds: SOUNDKIT name first, numeric kit id second, legacy file path last.
local SOUNDS = {
  click     = { kit = "IG_MAINMENU_OPTION_CHECKBOX_ON", id = 856,  file = "Sound\\Interface\\igMainMenuOptionCheckBoxOn.ogg" },
  levelUp   = { kit = "LEVEL_UP",                       id = 888,  file = "Sound\\Interface\\LevelUp.ogg" },
  gameOver  = { kit = "IG_QUEST_FAILED",                id = 846,  file = "Sound\\Interface\\igQuestFailed.ogg" },
  heartbeat = { kit = "IG_ABILITY_PAGE_TURN",           id = 836,  file = "Sound\\Interface\\iAbilitiesTurnPageA.ogg" },
  ping      = { kit = "MAP_PING",                       id = 3175, file = "Sound\\Interface\\MapPing.ogg" },
  warning   = { kit = "RAID_WARNING",                   id = 8959, file = "Sound\\Interface\\RaidWarning.ogg" },
}
local PRESSURE_BEAT_INTERVAL = 1.00

-- Hidden corner buttons, one in each bottom corner. Once pressed, that tune plays
-- on the first open of every session until it is switched off again.
local EGGS = {
  { id = "sea", file = SOUND_PATH .. "lost_at_sea.ogg", flag = "lostAtSea", command = "lostatsea", corner = "BOTTOMLEFT", x = 13 },
  { id = "bag", file = SOUND_PATH .. "paper_bag.ogg",   flag = "paperBag",  command = "paperbag",  corner = "BOTTOMRIGHT", x = -13 },
}

local MILESTONE_VALUES = { 512, 1024, 2048, 4096 }
local CURSE_URL = "https://www.curseforge.com/wow/addons/fly2048"

local KEYMAP = {
  ["UP"] = "up", ["DOWN"] = "down", ["LEFT"] = "left", ["RIGHT"] = "right",
  ["W"] = "up", ["S"] = "down", ["A"] = "left", ["D"] = "right",
}

-- Guild / score-animation config
local MSG_PREFIX            = "Fly2048"
local GUILD_PANEL_W         = 224
local GUILD_ROW_H           = 22
local GUILD_ROW_PAD         = 4
local GUILD_MAX_ROWS        = 10
local LBOARD_ROW_TOP        = 160  -- px below the outer frame padding (inside the flightboard panel)
local GUILD_PING_CD         = 30
local GUILD_BROADCAST_DELAY = 3
local GUILD_AUTO_INTERVAL   = 300  -- background re-ping every 5 minutes
local GUILD_JITTER_MAX      = 2.0
local DELTA_RISE_DIST       = 28
local DELTA_DURATION        = 0.80
local DELTA_STAGGER         = 0.10
local ROLLUP_DURATION       = 0.50
local LBOARD_SLIDE_DUR      = 0.30

-- ==============================
-- State
-- ==============================
local state = {
  grid = {}, tiles = {}, nextId = 1,
  score = 0, best = 0, over = false, inputLocked = false,
  queuedDir = nil, runStartBest = 0, newBestThisRun = false,
  divineUsed = false, milestonesHit = {},
  pressureBeatT = 0, autoShown = false,
  lastChordIndex = 0,
  combo = 0,
  scoreRollup = { active = false, fromVal = 0, toVal = 0, t = 0 },
  lboardLastRanks = {},
  guildPingCooldown = 0,
  eggPlayed = {},
}

local ui = {
  frame = nil, boardWrap = nil, board = nil,
  scoreText = nil, bestText = nil, statusText = nil, comboText = nil,
  gameOverOverlay = nil, playAgainBtn = nil, announceBtn = nil, curseBtn = nil,
  resetBtn = nil, themeBtn = nil, motionBtn = nil, soundBtn = nil,
  boardGlow = nil, boardGlowA = 0,
  pressureTex = nil, pressureBorder = nil, pressureA = 0, pressureT = 0,
  themeRefs = {}, cells = {}, statCards = {},
  shake = { active = false, t = 0 },
  anim = { active = false, t = 0, movers = {}, pops = {}, spawns = {}, popActive = false, popT = 0, spawnActive = false, spawnT = 0 },
  scoreDeltas = {},
  guildRows = {}, pingBtn = nil, guildSortCache = {},
}

-- ==============================
-- Helpers
-- ==============================
local function PlayChordProgressive()
  if Fly2048DB and Fly2048DB.mute then return end
  state.lastChordIndex = (state.lastChordIndex % #CHORDS) + 1
  PlaySoundFile(CHORDS[state.lastChordIndex], "SFX")
end

local function Clamp(n, a, b) return n < a and a or (n > b and b or n) end
local function Lerp(a, b, t) return a + (b - a) * t end
local function EaseOutCubic(t) local p = 1 - t return 1 - (p * p * p) end
local function CellXY(r, c) return (c - 1) * (TILE_SIZE + TILE_PAD), -((r - 1) * (TILE_SIZE + TILE_PAD)) end
local function RandomTileValue() return math.random() < 0.10 and 4 or 2 end

local function PlayerFaction()
  if not UnitFactionGroup then return nil end
  local faction = UnitFactionGroup("player")
  if faction == "Horde" or faction == "Alliance" then return faction end
  return nil
end

local function DefaultThemeKey()
  return PlayerFaction() == "Horde" and "horde" or "alliance"
end

local function GetTheme()
  local key = Fly2048DB and Fly2048DB.theme
  return THEMES[key] or THEMES[DefaultThemeKey()]
end

local function QualityColor(quality, dim)
  local live = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  local fallback = QUALITY_COLORS[quality] or QUALITY_COLORS[1]
  local r = live and live.r or fallback[1]
  local g = live and live.g or fallback[2]
  local b = live and live.b or fallback[3]
  if dim then r, g, b = r * 0.62, g * 0.62, b * 0.62 end
  return r, g, b
end

local function GetTileLoot(value) return TILE_LOOT[value] or TILE_LOOT_DEFAULT end

local function ClassColor(classFile)
  if not classFile then return nil end
  local live = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)
  live = live and live[classFile]
  if live and live.r then return { live.r, live.g, live.b, 1 } end
  local fallback = CLASS_COLORS_FALLBACK[classFile]
  if fallback then return { fallback[1], fallback[2], fallback[3], 1 } end
  return nil
end

local function LocalClassFile()
  if not UnitClass then return nil end
  local _, classFile = UnitClass("player")
  return classFile
end

local function SetTextureColor(texture, color, alpha)
  if not texture or not color then return end
  texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function SetTextColor(fontString, color, alpha)
  if not fontString or not color then return end
  fontString:SetTextColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function SetBackdrop(frame, background, border, backgroundAlpha, borderAlpha)
  if not frame then return end
  if background then frame:SetBackdropColor(background[1], background[2], background[3], backgroundAlpha or background[4] or 1) end
  if border then frame:SetBackdropBorderColor(border[1], border[2], border[3], borderAlpha or border[4] or 1) end
end

local function IsReducedMotion()
  return Fly2048DB and Fly2048DB.motion == "reduced"
end

local function MotionDuration(duration)
  return IsReducedMotion() and 0.01 or duration
end

local function FormatNumber(value)
  value = tonumber(value) or 0
  if value >= 1000000 then return ("%.1fm"):format(value / 1000000) end
  if value >= 10000 then return ("%.1fk"):format(value / 1000) end
  return tostring(math.floor(value))
end

local function PlayKit(key)
  if Fly2048DB and Fly2048DB.mute then return end
  local sound = SOUNDS[key]
  if not sound then return end
  local id = (SOUNDKIT and SOUNDKIT[sound.kit]) or sound.id
  if PlaySound and id then PlaySound(id, "SFX") else PlaySoundFile(sound.file, "SFX") end
end

local function PlayEgg(egg)
  if Fly2048DB and Fly2048DB.mute then return end
  state.eggPlayed[egg.id] = true
  PlaySoundFile(egg.file, "SFX")
end

local function After(delay, fn)
  if C_Timer and C_Timer.After then C_Timer.After(delay, fn) else fn() end
end

local function ClearGrid()
  state.grid = {}
  for r = 1, GRID do state.grid[r] = {} for c = 1, GRID do state.grid[r][c] = nil end end
end
ClearGrid()

local function GetEmptyCells()
  local cells = {}
  for r = 1, GRID do for c = 1, GRID do if not state.grid[r][c] then cells[#cells + 1] = { r = r, c = c } end end end
  return cells
end

local function HasMoves()
  if #GetEmptyCells() > 0 then return true end
  for r = 1, GRID do
    for c = 1, GRID do
      local t = state.grid[r][c]
      if t then
        if r < GRID then local b = state.grid[r + 1][c] if b and b.value == t.value then return true end end
        if c < GRID then local rr = state.grid[r][c + 1] if rr and rr.value == t.value then return true end end
      end
    end
  end
  return false
end

local function StopNonSlideAnims()
  if ui.anim.popActive then for _, t in ipairs(ui.anim.pops) do if t.frame then t.frame:SetScale(1) end end end
  if ui.anim.spawnActive then for _, t in ipairs(ui.anim.spawns) do if t.frame then t.frame:SetScale(1) end end end
  ui.anim.popActive, ui.anim.popT, ui.anim.pops = false, 0, {}
  ui.anim.spawnActive, ui.anim.spawnT, ui.anim.spawns = false, 0, {}
end

local function DestroyTile(tile)
  if not tile then return end
  if state.grid[tile.r] and state.grid[tile.r][tile.c] == tile then state.grid[tile.r][tile.c] = nil end
  state.tiles[tile.id] = nil
  if tile.frame then tile.frame:ClearAllPoints() tile.frame:Hide() tile.frame:SetParent(nil) end
end

-- The number is the thing you read, so it is sized to fill the tile rather than
-- inheriting a stock font size. Digit count, not value, decides how big it fits.
local function TileFontSize(value)
  local digits = #tostring(value)
  if digits <= 2 then return 38 elseif digits == 3 then return 32
  elseif digits == 4 then return 26 elseif digits == 5 then return 21 end
  return 18
end

local function TileBaseFont()
  return _G.GameFontNormalHuge or _G.GameFontHighlightHuge or _G.GameFontNormalLarge or _G.GameFontNormal
end

-- Tooltip-style inner panel (dark Blizzard backdrop, tinted per theme).
local function CreatePanel(parent, backgroundKey)
  local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  panel:SetBackdrop(BACKDROP_TOOLTIP)
  panel.themeBackgroundKey = backgroundKey or "panel"
  ui.themeRefs[#ui.themeRefs + 1] = panel
  return panel
end

-- Standard red Blizzard button. The template supplies SetText, hover, pressed,
-- disabled art and the click sound.
local function CreateWoWButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width or 72, height or 22)
  button:SetText(text)
  return button
end

local function ApplyPressureVisuals()
  if not ui.pressureTex then return end
  ui.pressureA = Clamp(((1 - (#GetEmptyCells() / (GRID * GRID))) - 0.50) / 0.50, 0, 1)
  local danger = GetTheme().danger
  SetTextureColor(ui.pressureTex, danger, ui.pressureA * 0.055)
  if ui.pressureBorder then SetBackdrop(ui.pressureBorder, nil, danger, nil, ui.pressureA * 0.55) end
end

local function MaybeHeartbeat(elapsed)
  if state.over or (Fly2048DB and Fly2048DB.mute) then return end
  if #GetEmptyCells() > 2 then state.pressureBeatT = 0 return end
  state.pressureBeatT = (state.pressureBeatT or 0) + elapsed
  if state.pressureBeatT >= PRESSURE_BEAT_INTERVAL then state.pressureBeatT = 0 PlayKit("heartbeat") end
end

local function TriggerBoardGlow(alpha)
  if not ui.boardGlow then return end
  ui.boardGlowA = math.max(ui.boardGlowA or 0, alpha or 0.55)
  SetTextureColor(ui.boardGlow, GetTheme().accent, ui.boardGlowA)
end

local function CheckMilestone(value)
  if not value or (state.milestonesHit and state.milestonesHit[value]) then return end
  for _, mVal in ipairs(MILESTONE_VALUES) do
    if value == mVal then
      state.milestonesHit[value] = true
      TriggerBoardGlow(0.55)
      if value == 512 then PlayKit("ping") elseif value >= 2048 then PlayKit("warning") end
      if ui.statusText then
        local mute = (Fly2048DB and Fly2048DB.mute) and "Muted" or "Sound on"
        ui.statusText:SetText(("Milestone reached: %d (%s)"):format(value, mute))
        After(1.2, function() if ui.statusText and not state.over then ui.statusText:SetText("Arrows or WASD. R restart. /fly2048 mute. (" .. mute .. ")") end end)
      end
      return
    end
  end
end

local function FindLowestTile()
  local lowest = nil
  for _, t in pairs(state.tiles) do if t and t.value and t.frame:IsShown() then if (not lowest) or (t.value < lowest.value) then lowest = t end end end
  return lowest
end

local function DoDivineReset()
  if state.over or state.inputLocked or ui.anim.active or state.divineUsed then return end
  local victim = FindLowestTile()
  if not victim then return end
  state.divineUsed = true
  PlayKit("click")
  TriggerBoardGlow(0.35)
  local vr, vc = victim.r, victim.c
  DestroyTile(victim)
  if ui.board and vr and vc then
    local f = CreateFrame("Frame", nil, ui.board) f:SetSize(TILE_SIZE, TILE_SIZE)
    local x, y = CellXY(vr, vc) f:SetPoint("TOPLEFT", ui.board, "TOPLEFT", x, y)
    local t = f:CreateTexture(nil, "OVERLAY") t:SetAllPoints(f) t:SetTexture(TEX.star) t:SetBlendMode("ADD") t:SetAlpha(0.0)
    local ag = t:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha") a1:SetFromAlpha(0) a1:SetToAlpha(0.85) a1:SetDuration(0.06) a1:SetOrder(1)
    local s1 = ag:CreateAnimation("Scale") s1:SetScaleFrom(0.8, 0.8) s1:SetScaleTo(1.5, 1.5) s1:SetDuration(0.18) s1:SetOrder(1)
    local a2 = ag:CreateAnimation("Alpha") a2:SetFromAlpha(0.85) a2:SetToAlpha(0) a2:SetDuration(0.18) a2:SetOrder(2)
    ag:SetScript("OnFinished", function() f:Hide() f:SetParent(nil) end) ag:Play()
  end
  ApplyPressureVisuals()
end

local function TriggerShake()
  if ui.boardWrap and not IsReducedMotion() then ui.shake.active, ui.shake.t = true, 0 end
end

local function ApplyShake(elapsed)
  if not ui.shake.active or not ui.boardWrap then return end
  ui.shake.t = ui.shake.t + elapsed
  local t = ui.shake.t / SHAKE_DUR
  if t >= 1 then
    ui.shake.active, ui.shake.t = false, 0
    ui.boardWrap:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H))
    return
  end
  local amp = (SHAKE_AMP + (1 - (#GetEmptyCells() / (GRID * GRID))) * 2.0) * (1 - t)
  ui.boardWrap:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", FRAME_PAD + (math.random()*2-1)*amp, -(FRAME_PAD + HEADER_H) + (math.random()*2-1)*amp)
end

local function SetTileVisual(tile)
  local loot = GetTileLoot(tile.value)
  local r, g, b = QualityColor(loot.quality, loot.dim)
  tile.icon:SetTexture(loot.icon)
  -- The icon is scenery behind the number, so it is held well below full brightness.
  local iconTint = loot.dim and 0.42 or 0.52
  tile.icon:SetVertexColor(iconTint, iconTint, iconTint, 1)
  if tile.frame.SetBackdropBorderColor then tile.frame:SetBackdropBorderColor(r, g, b, 1) end
  tile.border:SetVertexColor(r, g, b, 1)
  tile.border:SetAlpha(loot.quality >= 5 and 0.85 or (loot.quality >= 3 and 0.55 or 0.35))
  -- An even scrim over the whole icon: no band edge to read as a box.
  tile.vignette:SetColorTexture(0, 0, 0, 0.30)
  local fo = TileBaseFont()
  if fo then tile.text:SetFontObject(fo) end
  local font = tile.text:GetFont()
  if font then tile.text:SetFont(font, TileFontSize(tile.value), "THICKOUTLINE") end
  tile.text:SetText(tostring(tile.value))
  tile.text:SetTextColor(1, 1, 1, 1)
  tile.text:SetShadowColor(0, 0, 0, 1)
  tile.text:SetShadowOffset(2, -2)
end

local function ApplyTheme()
  local theme = GetTheme()
  if ui.frame then SetBackdrop(ui.frame, theme.frameBg, theme.frameEdge) end
  for _, ref in ipairs(ui.themeRefs) do
    if ref and ref.SetBackdropColor then
      local bg = theme[ref.themeBackgroundKey or "panel"] or theme.panel
      SetBackdrop(ref, bg, theme.border)
    end
  end
  for _, cell in ipairs(ui.cells) do cell:SetVertexColor(theme.cell[1], theme.cell[2], theme.cell[3], theme.cell[4] or 1) end
  if ui.board then SetBackdrop(ui.board, theme.board, theme.border) end
  if ui.crest then ui.crest:SetTexture(theme.crest) ui.crest:SetAlpha(0.14) end
  if ui.subtitleText then ui.subtitleText:SetText(theme.subtitle) SetTextColor(ui.subtitleText, theme.accent) end
  if ui.statusText then SetTextColor(ui.statusText, theme.muted) end
  if ui.rightTitle then SetTextColor(ui.rightTitle, theme.gold) end
  if ui.guildLabel then SetTextColor(ui.guildLabel, theme.muted) end
  if ui.comboText then SetTextColor(ui.comboText, theme.accent) end
  if ui.gameOverTitle then SetTextColor(ui.gameOverTitle, theme.gold) end
  if ui.gameOverScore then SetTextColor(ui.gameOverScore, theme.text) end
  for _, card in ipairs(ui.statCards) do
    SetBackdrop(card, theme.panelAlt, theme.border)
    if card.caption then SetTextColor(card.caption, theme.muted) end
    if card.value then SetTextColor(card.value, card.isBest and theme.gold or theme.text) end
  end
  for _, row in ipairs(ui.guildRows) do
    if row.background then SetTextureColor(row.background, theme.panelAlt, row.index % 2 == 0 and 0.62 or 0.34) end
    if row.highlight then SetTextureColor(row.highlight, theme.accent, row.pulseA or 0) end
  end
  for _, tile in pairs(state.tiles) do SetTileVisual(tile) end
  ApplyPressureVisuals()
  if ui.themeBtn then ui.themeBtn:SetText(theme.name) end
end

local function PlaceTileFrame(tile, r, c)
  local x, y = CellXY(r, c)
  tile.frame:ClearAllPoints()
  tile.frame:SetPoint("TOPLEFT", ui.board, "TOPLEFT", x, y)
end

local function TriggerFlash(tile) if tile then tile.flashA = FLASH_ALPHA tile.flash:SetColorTexture(1, 1, 1, tile.flashA) end end
local function TriggerSpark(tile)
  if not tile or IsReducedMotion() then return end
  tile.spark:Show() tile.sparkAG:Stop() tile.sparkAG:Play()
end

local function CreateTile(r, c, value, isSpawn)
  local id = state.nextId
  state.nextId = state.nextId + 1
  local f = CreateFrame("Frame", nil, ui.board, "BackdropTemplate") f:SetSize(TILE_SIZE, TILE_SIZE)
  f:SetBackdrop({ edgeFile = WHITE_TEXTURE, edgeSize = 2 })
  -- Item-slot stack: dark base, loot icon, vignette band for the number, quality glow.
  local base = f:CreateTexture(nil, "BACKGROUND") base:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1) base:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1) base:SetColorTexture(0.04, 0.04, 0.05, 1)
  local icon = f:CreateTexture(nil, "ARTWORK", nil, 0) icon:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3) icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3) icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local vignette = f:CreateTexture(nil, "ARTWORK", nil, 1) vignette:SetTexture(WHITE_TEXTURE) vignette:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3) vignette:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
  local border = f:CreateTexture(nil, "OVERLAY") border:SetTexture(TEX.glow) border:SetBlendMode("ADD") border:SetPoint("CENTER", f, "CENTER", 0, 0) border:SetSize(TILE_SIZE * 1.6, TILE_SIZE * 1.6) border:SetAlpha(0.35)
  local flash = f:CreateTexture(nil, "OVERLAY") flash:SetAllPoints(f) flash:SetColorTexture(1, 1, 1, 0)
  local spark = f:CreateTexture(nil, "OVERLAY") spark:SetTexture(TEX.star) spark:SetBlendMode("ADD") spark:SetPoint("CENTER", f, "CENTER", 0, 0) spark:SetSize(TILE_SIZE * 1.1, TILE_SIZE * 1.1) spark:SetAlpha(0) spark:Hide()
  local sparkAG = spark:CreateAnimationGroup()
  local a1 = sparkAG:CreateAnimation("Alpha") a1:SetFromAlpha(0) a1:SetToAlpha(0.85) a1:SetDuration(0.06) a1:SetOrder(1)
  local s1 = sparkAG:CreateAnimation("Scale") s1:SetScaleFrom(0.6, 0.6) s1:SetScaleTo(1.3, 1.3) s1:SetDuration(0.10) s1:SetOrder(1)
  local a2 = sparkAG:CreateAnimation("Alpha") a2:SetFromAlpha(0.85) a2:SetToAlpha(0) a2:SetDuration(0.12) a2:SetOrder(2)
  sparkAG:SetScript("OnFinished", function() spark:Hide() spark:SetAlpha(0) spark:SetScale(1) end)
  local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge") txt:SetPoint("CENTER", f, "CENTER", 0, 0)

  local tile = { id = id, frame = f, base = base, icon = icon, vignette = vignette, border = border, flash = flash, flashA = 0, spark = spark, sparkAG = sparkAG, text = txt, r = r, c = c, value = value, sx = 0, sy = 0, ex = 0, ey = 0, tr = r, tc = c, mergeInto = nil, mergedThisTurn = false, pop = false, spawnPop = false }
  SetTileVisual(tile)
  PlaceTileFrame(tile, r, c)
  state.tiles[id], state.grid[r][c] = tile, tile

  if isSpawn then
    tile.spawnPop = true
    tile.frame:SetScale(0.98)
    ui.anim.spawns[#ui.anim.spawns + 1] = tile
    TriggerSpark(tile)
    PlayChordProgressive()
  else
    tile.frame:SetScale(1)
  end
  return tile
end

local function AnnounceScoreToGuild()
  local msg = ("Fly2048: I just scored %d! Try to beat it at %s"):format(state.score or 0, CURSE_URL)
  if IsInGuild and IsInGuild() then
    if C_ChatInfo and C_ChatInfo.SendChatMessage then C_ChatInfo.SendChatMessage(msg, "GUILD")
    elseif SendChatMessage then SendChatMessage(msg, "GUILD") end
  else
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Fly2048: Not in a guild.") end
    if ChatFrame_OpenChat then ChatFrame_OpenChat(msg) end
  end
end

local function PutCurseLinkInChat() if ChatFrame_OpenChat then ChatFrame_OpenChat("Fly2048 addon: " .. CURSE_URL) end end

-- ==============================
-- Guild Messaging
-- ==============================
local function GetLocalKey()
  local name, realm = UnitName("player")
  realm = realm or (GetRealmName and GetRealmName()) or (GetNormalizedRealmName and GetNormalizedRealmName()) or "Unknown"
  return name .. "-" .. realm
end

local function GuildSyncRestricted()
  return C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()
end

local function BroadcastScore()
  if not (IsInGuild and IsInGuild()) then return end
  if GuildSyncRestricted() then return end
  if not state.best or state.best <= 0 then return end
  local function send(msg)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
      C_ChatInfo.SendAddonMessage(MSG_PREFIX, msg, "GUILD")
    elseif SendAddonMessage then
      SendAddonMessage(MSG_PREFIX, msg, "GUILD")
    end
  end
  -- Legacy form first so older Fly2048 clients still parse the score, then the
  -- class-tagged form used for class colours on the flightboard.
  send("SCORE:" .. state.best)
  local classFile = LocalClassFile()
  if classFile then send("SCORE:" .. state.best .. ":" .. classFile) end
end

local function BroadcastRequest()
  if not (IsInGuild and IsInGuild()) then return end
  if GuildSyncRestricted() then return end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(MSG_PREFIX, "REQUEST", "GUILD")
  elseif SendAddonMessage then
    SendAddonMessage(MSG_PREFIX, "REQUEST", "GUILD")
  end
end

local function AutoPing()
  if not (IsInGuild and IsInGuild()) then return end
  if state.guildPingCooldown > 0 then return end
  state.guildPingCooldown = GUILD_PING_CD + GUILD_BROADCAST_DELAY
  if ui.pingBtn then ui.pingBtn:Disable() end
  After(GUILD_BROADCAST_DELAY, function()
    BroadcastRequest()
    BroadcastScore()
  end)
  After(GUILD_PING_CD + GUILD_BROADCAST_DELAY, function()
    state.guildPingCooldown = 0
    if ui.pingBtn and IsInGuild and IsInGuild() then ui.pingBtn:Enable() end
  end)
end

local RefreshLeaderboard  -- forward declaration

local function HandleAddonMessage(prefix, msg, channel, senderFull)
  if prefix ~= MSG_PREFIX then return end
  if channel ~= "GUILD" then return end
  local sender = senderFull or ""
  if Ambiguate then sender = Ambiguate(senderFull, "none") end
  if not sender:find("%-") then
    local _, realm = UnitName("player")
    realm = realm or (GetRealmName and GetRealmName()) or ""
    sender = sender .. "-" .. realm
  end
  if sender == GetLocalKey() then return end
  local scoreStr, classFile = msg:match("^SCORE:(%d+):?(%u*)$")
  local score = tonumber(scoreStr)
  if score then
    Fly2048DB.guildScores = Fly2048DB.guildScores or {}
    Fly2048DB.guildClasses = Fly2048DB.guildClasses or {}
    local changed = false
    if classFile and classFile ~= "" and Fly2048DB.guildClasses[sender] ~= classFile then
      Fly2048DB.guildClasses[sender] = classFile
      changed = true
    end
    local existing = Fly2048DB.guildScores[sender] or 0
    if score > existing then
      Fly2048DB.guildScores[sender] = score
      changed = true
    end
    if changed then RefreshLeaderboard() end
  elseif msg == "REQUEST" then
    After(math.random() * GUILD_JITTER_MAX, BroadcastScore)
  end
end

local function BuildSortedGuild()
  local list = {}
  local localKey = GetLocalKey()
  Fly2048DB.guildScores = Fly2048DB.guildScores or {}
  local classes = Fly2048DB.guildClasses or {}
  for k, v in pairs(Fly2048DB.guildScores) do
    if k ~= localKey then
      list[#list + 1] = { name = k, score = v, isLocal = false, class = classes[k] }
    end
  end
  local displayScore = math.max(state.best or 0, state.score or 0)
  if displayScore > 0 then
    list[#list + 1] = { name = localKey, score = displayScore, isLocal = true, class = LocalClassFile() }
  end
  table.sort(list, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.name < b.name
  end)
  return list
end

local function GetRowTargetY(rank)
  return -(FRAME_PAD + LBOARD_ROW_TOP + (rank - 1) * (GUILD_ROW_H + GUILD_ROW_PAD))
end

local function UpdateLeaderboardRowPositions(elapsed)
  for _, row in ipairs(ui.guildRows) do
    if row.sliding then
      row.slideT = row.slideT + elapsed
      local p = math.min(1, row.slideT / MotionDuration(LBOARD_SLIDE_DUR))
      local y = Lerp(row.fromY, row.targetY, EaseOutCubic(p))
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", LBOARD_X, y)
      if p >= 1 then
        row.sliding = false
        row.fromY = row.targetY
      end
    end
  end
end

RefreshLeaderboard = function()
  if not ui.frame then return end
  local theme = GetTheme()
  local sorted = BuildSortedGuild()
  ui.guildSortCache = sorted
  local localKey = GetLocalKey()

  local newRanks = {}
  for i, entry in ipairs(sorted) do newRanks[entry.name] = i end
  local prevLocalRank = state.lboardLastRanks[localKey]

  local n = math.min(#sorted, GUILD_MAX_ROWS)
  for i = 1, #ui.guildRows do
    local row = ui.guildRows[i]
    if i <= n then
      local entry = sorted[i]
      local displayName = entry.name:match("^([^%-]+)") or entry.name
      if i == 1 then row.rankText:SetText("") if row.crown then row.crown:Show() end
      else row.rankText:SetText(tostring(i)) if row.crown then row.crown:Hide() end end
      row.nameText:SetText(displayName)
      row.scoreText:SetText(FormatNumber(entry.score))
      if row.lastName == entry.name and row.lastScore and entry.score > row.lastScore then row.pulseA = 0.62 end
      row.lastName, row.lastScore = entry.name, entry.score
      if entry.isLocal then
        SetTextColor(row.rankText, theme.gold)
        SetTextColor(row.nameText, theme.gold)
        SetTextColor(row.scoreText, theme.gold)
      else
        SetTextColor(row.rankText, theme.muted)
        SetTextColor(row.nameText, ClassColor(entry.class) or theme.text, 0.95)
        SetTextColor(row.scoreText, theme.text, 0.90)
      end
      local targetY = GetRowTargetY(i)
      if entry.isLocal and prevLocalRank and prevLocalRank ~= i then
        row.fromY = GetRowTargetY(prevLocalRank)
        row.targetY = targetY
        row.slideT = 0
        row.sliding = true
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", LBOARD_X, row.fromY)
      elseif not row.sliding then
        row.fromY = targetY
        row.targetY = targetY
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", LBOARD_X, targetY)
      end
      row:Show()
    else
      row:Hide()
      row.lastName, row.lastScore, row.pulseA = nil, nil, 0
    end
  end

  state.lboardLastRanks = newRanks

  if ui.pingBtn then
    if state.guildPingCooldown > 0 or not (IsInGuild and IsInGuild()) then
      ui.pingBtn:Disable()
    else
      ui.pingBtn:Enable()
    end
  end
end

-- ==============================
-- Score Animations
-- ==============================
local function SpawnScoreDelta(gain, combo)
  if not ui.frame or not ui.scoreText then return end
  local activeCount = #ui.scoreDeltas
  local label = ui.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  SetTextColor(label, combo and combo >= 2 and GetTheme().gold or GetTheme().success)
  label:SetText("+" .. gain .. ((combo and combo >= 2) and ("  x" .. combo) or ""))
  label:SetPoint("TOPLEFT", ui.scoreText, "TOPLEFT", 0, 0)
  label:SetAlpha(1)
  ui.scoreDeltas[#ui.scoreDeltas + 1] = {
    label = label,
    t = -(activeCount * DELTA_STAGGER),
    duration = MotionDuration(DELTA_DURATION),
  }
end

local function StartScoreRollup(fromVal, toVal)
  local r = state.scoreRollup
  if r.active then
    local p = math.min(1, r.t / ROLLUP_DURATION)
    r.fromVal = math.floor(Lerp(r.fromVal, r.toVal, EaseOutCubic(p)))
    r.toVal = toVal
    r.t = 0
  else
    r.fromVal = fromVal
    r.toVal = toVal
    r.t = 0
    r.active = true
  end
end

local UpdateUI

local function CycleTheme()
  local current = THEMES[Fly2048DB.theme] and Fly2048DB.theme or DefaultThemeKey()
  local nextIndex = 1
  for i, key in ipairs(THEME_ORDER) do if key == current then nextIndex = (i % #THEME_ORDER) + 1 break end end
  Fly2048DB.theme = THEME_ORDER[nextIndex]
  ApplyTheme()
  UpdateUI()
end

local function ToggleMotion()
  Fly2048DB.motion = IsReducedMotion() and "full" or "reduced"
  if IsReducedMotion() then
    ui.shake.active = false
    if ui.boardWrap then
      ui.boardWrap:ClearAllPoints()
      ui.boardWrap:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H))
    end
  end
  UpdateUI()
end

local function ToggleSound()
  Fly2048DB.mute = not Fly2048DB.mute
  UpdateUI()
end

local function AddTooltip(frame, title, body)
  frame:SetScript("OnEnter", function(self)
    local theme = GetTheme()
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(title, theme.gold[1], theme.gold[2], theme.gold[3])
    if body then GameTooltip:AddLine(body, theme.text[1], theme.text[2], theme.text[3], true) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

-- ==============================
-- Game Logic
-- ==============================
UpdateUI = function()
  if not ui.frame then return end
  if not state.scoreRollup.active then
    ui.scoreText:SetText(FormatNumber(state.score))
  end
  ui.bestText:SetText(FormatNumber(state.best))
  local mute = (Fly2048DB and Fly2048DB.mute) and "Muted" or "Sound on"
  if state.over then ui.statusText:SetText("Game Over. R restart. (" .. mute .. ")") ui.gameOverOverlay:Show() else ui.statusText:SetText("WASD/Arrows. R restart. (" .. mute .. ")") ui.gameOverOverlay:Hide() end
  if ui.comboText then
    if state.combo >= 2 then ui.comboText:SetText(("MERGE CHAIN  x%d"):format(state.combo)) ui.comboText:Show() else ui.comboText:Hide() end
  end
  if ui.resetBtn then if state.over or state.divineUsed then ui.resetBtn:Disable() else ui.resetBtn:Enable() end end
  if ui.soundBtn then ui.soundBtn:SetText(Fly2048DB.mute and "Sound off" or "Sound on") end
  if ui.motionBtn then ui.motionBtn:SetText(IsReducedMotion() and "Reduced" or "Motion") end
  if ui.themeBtn then ui.themeBtn:SetText(GetTheme().name) end
  RefreshLeaderboard()
end

local function SpawnRandomTile()
  local empties = GetEmptyCells()
  if #empties == 0 then return false end
  local pick = empties[math.random(1, #empties)]
  CreateTile(pick.r, pick.c, RandomTileValue(), true)
  return true
end

local function ResetGame()
  for _, tile in pairs(state.tiles) do tile.frame:Hide() tile.frame:SetParent(nil) end
  state.tiles, state.nextId, state.score, state.over, state.inputLocked, state.queuedDir, state.divineUsed, state.milestonesHit, state.lastChordIndex, state.combo = {}, 1, 0, false, false, nil, false, {}, 0, 0
  state.best = tonumber(Fly2048DB.best) or 0
  state.runStartBest, state.newBestThisRun = state.best, false
  state.scoreRollup = { active = false, fromVal = 0, toVal = 0, t = 0 }
  state.lboardLastRanks = {}
  ClearGrid()
  ui.anim.active, ui.anim.t, ui.anim.movers, ui.anim.pops, ui.anim.spawns, ui.anim.popActive, ui.anim.spawnActive, ui.shake.active, ui.boardGlowA, ui.pressureA, ui.pressureT = false, 0, {}, {}, {}, false, false, false, 0, 0, 0
  if ui.boardGlow then SetTextureColor(ui.boardGlow, GetTheme().accent, 0) end
  if ui.pressureTex then SetTextureColor(ui.pressureTex, GetTheme().danger, 0) end
  if ui.pressureBorder then SetBackdrop(ui.pressureBorder, nil, GetTheme().danger, nil, 0) end
  for i = #ui.scoreDeltas, 1, -1 do
    local d = ui.scoreDeltas[i]
    if d.label then d.label:Hide() d.label:SetParent(nil) end
    table.remove(ui.scoreDeltas, i)
  end
  SpawnRandomTile() SpawnRandomTile()
  if #ui.anim.spawns > 0 then ui.anim.spawnActive, ui.anim.spawnT = true, 0 end
  ApplyPressureVisuals() UpdateUI()
end

local function LoadVisualDemo()
  for _, tile in pairs(state.tiles) do if tile.frame then tile.frame:Hide() tile.frame:SetParent(nil) end end
  state.tiles, state.nextId, state.score, state.over, state.inputLocked, state.queuedDir, state.combo, state.divineUsed = {}, 1, 14336, false, false, nil, 4, false
  state._plannedGrid, state._plannedScoreGain = nil, nil
  state.scoreRollup = { active = false, fromVal = 0, toVal = 0, t = 0 }
  ui.anim.active, ui.anim.t, ui.anim.movers, ui.anim.pops, ui.anim.spawns, ui.anim.popActive, ui.anim.spawnActive = false, 0, {}, {}, {}, false, false
  ui.shake.active = false
  if ui.boardWrap then ui.boardWrap:ClearAllPoints() ui.boardWrap:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H)) end
  for i = #ui.scoreDeltas, 1, -1 do
    local delta = ui.scoreDeltas[i]
    if delta.label then delta.label:Hide() delta.label:SetParent(nil) end
    table.remove(ui.scoreDeltas, i)
  end
  ClearGrid()
  local values = {
    { 2, 4, 8, 16 },
    { 32, 64, 128, 256 },
    { 512, 1024, 2048, 4096 },
    { 8192, 16384, 2, nil },
  }
  for r = 1, GRID do for c = 1, GRID do if values[r][c] then CreateTile(r, c, values[r][c], false) end end end
  ApplyPressureVisuals() UpdateUI()
end

local function LineCells(dir, index)
  local cells = {}
  if dir == "left" then for c = 1, GRID do cells[#cells + 1] = { r = index, c = c } end
  elseif dir == "right" then for c = GRID, 1, -1 do cells[#cells + 1] = { r = index, c = c } end
  elseif dir == "up" then for r = 1, GRID do cells[#cells + 1] = { r = r, c = index } end
  elseif dir == "down" then for r = GRID, 1, -1 do cells[#cells + 1] = { r = r, c = index } end end
  return cells
end

local function ApplyMovePlan(dir)
  if state.over or state.inputLocked then return false end
  StopNonSlideAnims()
  for _, t in pairs(state.tiles) do t.mergeInto, t.mergedThisTurn, t.pop, t.spawnPop = nil, false, false, false end
  local movers, moved, scoreGain, newGrid = {}, false, 0, {}
  for r = 1, GRID do newGrid[r] = {} end
  for line = 1, GRID do
    local cells = LineCells(dir, line)
    local tilesInLine = {}
    for i = 1, #cells do local t = state.grid[cells[i].r][cells[i].c] if t then tilesInLine[#tilesInLine + 1] = t end end
    local slot, last = 1, nil
    for i = 1, #tilesInLine do
      local t, targetCell = tilesInLine[i], cells[slot]
      if last and (not last.mergedThisTurn) and last.value == t.value then
        local mCell = cells[slot - 1]
        t.tr, t.tc, t.mergeInto, last.mergedThisTurn, last.pop, scoreGain, moved = mCell.r, mCell.c, last, true, true, scoreGain + (last.value * 2), true
        movers[#movers + 1] = t
      else
        t.tr, t.tc, last, moved, slot = targetCell.r, targetCell.c, t, moved or (t.r ~= targetCell.r) or (t.c ~= targetCell.c), slot + 1
        movers[#movers + 1] = t
      end
    end
    slot = 1
    for i = 1, #tilesInLine do if not tilesInLine[i].mergeInto then local cell = cells[slot] newGrid[cell.r][cell.c], slot = tilesInLine[i], slot + 1 end end
  end
  if not moved then return false end
  state.inputLocked, ui.anim.active, ui.anim.t, ui.anim.movers, ui.anim.pops, ui.anim.spawns = true, true, 0, movers, {}, {}
  for _, t in ipairs(movers) do t.sx, t.sy = CellXY(t.r, t.c) t.ex, t.ey = CellXY(t.tr, t.tc) end
  local pops = {}
  for _, t in pairs(state.tiles) do if t.pop and not t.mergeInto then pops[#pops + 1] = t end end
  ui.anim.pops, state._plannedGrid, state._plannedScoreGain = pops, newGrid, scoreGain
  return true
end

local function CommitMove()
  local newGrid, scoreGain = state._plannedGrid, state._plannedScoreGain or 0
  state._plannedGrid, state._plannedScoreGain = nil, nil
  ClearGrid()
  for r = 1, GRID do for c = 1, GRID do local t = newGrid[r][c] if t then t.r, t.c = r, c state.grid[r][c] = t PlaceTileFrame(t, r, c) t.frame:SetScale(1) end end end
  local toDestroy, toUpgrade = {}, {}
  for _, t in pairs(state.tiles) do if t.mergeInto then toDestroy[#toDestroy + 1] = t if state.tiles[t.mergeInto.id] then toUpgrade[t.mergeInto.id] = t.mergeInto end end end
  local mergeCount = 0
  for _, survivor in pairs(toUpgrade) do
    mergeCount = mergeCount + 1
    survivor.value = survivor.value * 2
    CheckMilestone(survivor.value)
    SetTileVisual(survivor) survivor.frame:SetScale(1) TriggerFlash(survivor) TriggerSpark(survivor)
  end
  if mergeCount > 0 then
    TriggerShake()
    for i = 1, mergeCount do
      After((i - 1) * 0.05, function() PlayChordProgressive() end)
    end
  end
  for _, t in ipairs(toDestroy) do DestroyTile(t) end
  if scoreGain > 0 then
    state.combo = (state.combo or 0) + 1
    local oldScore = state.score
    state.score = state.score + scoreGain
    if state.score > state.best then
      state.best, Fly2048DB.best, state.newBestThisRun = state.score, state.score, true
      BroadcastScore()
    end
    SpawnScoreDelta(scoreGain, state.combo)
    StartScoreRollup(oldScore, state.score)
    if state.combo >= 2 then TriggerBoardGlow(Clamp(0.22 + state.combo * 0.06, 0.22, 0.62)) end
  else
    state.combo = 0
  end
  SpawnRandomTile() ApplyPressureVisuals()
  if not HasMoves() then state.over = true if state.newBestThisRun then PlayKit("levelUp") else PlayKit("gameOver") end end
  UpdateUI() state.inputLocked = false
end

-- ==============================
-- Main UI
-- ==============================
local function BuildUI()
  if ui.frame then return end
  local w = LBOARD_X + GUILD_PANEL_W + FRAME_PAD
  local h = FRAME_PAD*2 + HEADER_H + BOARD_INNER_W
  local f = CreateFrame("Frame", "Fly2048Frame", UIParent, "BackdropTemplate")
  ui.frame = f
  f:SetSize(w, h)
  if Fly2048DB.position and Fly2048DB.position.point then
    f:SetPoint(Fly2048DB.position.point, UIParent, Fly2048DB.position.relativePoint or Fly2048DB.position.point, Fly2048DB.position.x or 0, Fly2048DB.position.y or 0)
  else
    f:SetPoint("CENTER")
  end
  f:SetScale(Fly2048DB.uiScale or 1)
  f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton") f:SetClampedToScreen(true)
  f:SetBackdrop(BACKDROP_DIALOG)
  if UISpecialFrames then table.insert(UISpecialFrames, "Fly2048Frame") end
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    Fly2048DB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
  end)
  f:EnableKeyboard(true) f:SetPropagateKeyboardInput(false)

  -- Header plate with the title, Blizzard dialog style.
  ui.headerTex = f:CreateTexture(nil, "ARTWORK")
  ui.headerTex:SetTexture(TEX.header) ui.headerTex:SetSize(256, 64) ui.headerTex:SetPoint("TOP", f, "TOP", 0, 12)
  ui.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.titleText:SetPoint("TOP", ui.headerTex, "TOP", 0, -14)
  ui.titleText:SetText("Fly2048")
  ui.emblem = f:CreateTexture(nil, "ARTWORK")
  ui.emblem:SetTexture(TEX.dice) ui.emblem:SetTexCoord(0.07, 0.93, 0.07, 0.93) ui.emblem:SetSize(26, 26)
  ui.emblem:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PAD - 4, -(FRAME_PAD - 6))
  ui.subtitleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.subtitleText:SetPoint("LEFT", ui.emblem, "RIGHT", 6, 0)
  ui.subtitleText:SetText("FOR THE ALLIANCE!")
  ui.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.statusText:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H - 20))

  ui.soundBtn = CreateWoWButton(f, "Sound on", 72, 22)
  ui.soundBtn:SetPoint("TOPRIGHT", f, "TOPLEFT", FRAME_PAD + BOARD_INNER_W, -(FRAME_PAD + 34))
  ui.soundBtn:SetScript("OnClick", ToggleSound)
  AddTooltip(ui.soundBtn, "Sound", "Mute or enable Fly2048 sound effects.")
  ui.motionBtn = CreateWoWButton(f, "Motion", 72, 22)
  ui.motionBtn:SetPoint("RIGHT", ui.soundBtn, "LEFT", -4, 0)
  ui.motionBtn:SetScript("OnClick", ToggleMotion)
  AddTooltip(ui.motionBtn, "Motion", "Toggle full and reduced animation modes.")
  ui.themeBtn = CreateWoWButton(f, "Alliance", 72, 22)
  ui.themeBtn:SetPoint("RIGHT", ui.motionBtn, "LEFT", -4, 0)
  ui.themeBtn:SetScript("OnClick", CycleTheme)
  AddTooltip(ui.themeBtn, "Faction colours", "Switch between Alliance and Horde colours.")

  ui.comboText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.comboText:SetPoint("TOPRIGHT", f, "TOPLEFT", FRAME_PAD + BOARD_INNER_W, -(FRAME_PAD + HEADER_H - 20))
  ui.comboText:Hide()
  CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -4, -4)

  ui.eggBtns = {}
  for _, egg in ipairs(EGGS) do
    local button = CreateFrame("Button", nil, f)
    button:SetSize(10, 10) button:SetPoint(egg.corner, f, egg.corner, egg.x, 13)
    button.tex = button:CreateTexture(nil, "OVERLAY") button.tex:SetAllPoints() button.tex:SetColorTexture(1, 1, 1, 0.05)
    button:SetScript("OnClick", function() Fly2048DB[egg.flag] = true PlayEgg(egg) end)
    ui.eggBtns[egg.id] = button
  end

  ui.rightTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.rightTitle:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 2))
  ui.rightTitle:SetText("Guild Flightboard")

  local function CreateStatCard(caption, isBest)
    local card = CreatePanel(f, "panelAlt")
    card:SetSize((GUILD_PANEL_W - 6) / 2, 48)
    card.caption = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.caption:SetPoint("TOPLEFT", 8, -6) card.caption:SetText(caption)
    card.value = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    card.value:SetPoint("BOTTOMLEFT", 8, 6)
    card.isBest = isBest
    ui.statCards[#ui.statCards + 1] = card
    return card
  end
  local scoreCard = CreateStatCard("SCORE", false)
  scoreCard:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 30))
  local bestCard = CreateStatCard("BEST", true)
  bestCard:SetPoint("LEFT", scoreCard, "RIGHT", 6, 0)
  ui.scoreText, ui.bestText = scoreCard.value, bestCard.value

  ui.resetBtn = CreateWoWButton(f, "Divine Reset", GUILD_PANEL_W, 22)
  ui.resetBtn:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 86))
  ui.resetBtn:SetScript("OnClick", function() DoDivineReset() UpdateUI() end)
  AddTooltip(ui.resetBtn, "Divine Reset", "Once per game, remove the lowest-value tile.")

  -- Leaderboard panel with the faction crest as a watermark.
  ui.lboardPanel = CreatePanel(f, "panel")
  ui.lboardPanel:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 118))
  ui.lboardPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", LBOARD_X + GUILD_PANEL_W, FRAME_PAD + 30)
  ui.lboardPanel:SetFrameLevel(f:GetFrameLevel() + 1)
  ui.crest = ui.lboardPanel:CreateTexture(nil, "BACKGROUND", nil, 1)
  ui.crest:SetSize(176, 176) ui.crest:SetPoint("CENTER", ui.lboardPanel, "CENTER", 0, -8)

  ui.guildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.guildLabel:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X + 8, -(FRAME_PAD + 126))
  ui.guildLabel:SetText("GUILD RANKING")

  ui.pingBtn = CreateWoWButton(f, "Refresh guild scores", GUILD_PANEL_W, 22)
  ui.pingBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LBOARD_X, FRAME_PAD)
  ui.pingBtn:SetScript("OnClick", function() if state.guildPingCooldown <= 0 then AutoPing() end end)
  AddTooltip(ui.pingBtn, "Guild scores", "Ask online guild members running Fly2048 for their best score.")

  ui.guildRows = {}
  for i = 1, GUILD_MAX_ROWS do
    local row = CreateFrame("Frame", nil, f)
    row.index, row.pulseA = i, 0
    row:SetSize(GUILD_PANEL_W - 12, GUILD_ROW_H)
    row:SetFrameLevel(ui.lboardPanel:GetFrameLevel() + 2)
    local ty = GetRowTargetY(i)
    row:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X + 6, ty)
    row.fromY, row.targetY, row.sliding, row.slideT = ty, ty, false, 0
    row.background = row:CreateTexture(nil, "BACKGROUND") row.background:SetAllPoints()
    row.highlight = row:CreateTexture(nil, "ARTWORK") row.highlight:SetAllPoints() row.highlight:SetBlendMode("ADD")
    row.crown = row:CreateTexture(nil, "OVERLAY") row.crown:SetTexture(TEX.crown) row.crown:SetSize(16, 16) row.crown:SetPoint("LEFT", 5, 0) row.crown:Hide()
    row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rankText:SetPoint("LEFT", 6, 0) row.rankText:SetWidth(20) row.rankText:SetJustifyH("LEFT")
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row.rankText, "RIGHT", 3, 0) row.nameText:SetWidth(110) row.nameText:SetJustifyH("LEFT")
    row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.scoreText:SetPoint("RIGHT", row, "RIGHT", -6, 0) row.scoreText:SetWidth(62) row.scoreText:SetJustifyH("RIGHT")
    row:Hide()
    ui.guildRows[i] = row
  end

  -- The board is a 4x4 bag: each cell is an empty item slot.
  ui.boardWrap = CreateFrame("Frame", nil, f)
  ui.boardWrap:SetPoint("TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H))
  ui.boardWrap:SetSize(BOARD_INNER_W, BOARD_INNER_W)
  ui.board = CreatePanel(ui.boardWrap, "board") ui.board:SetAllPoints()
  ui.pressureTex = ui.board:CreateTexture(nil, "OVERLAY") ui.pressureTex:SetAllPoints() ui.pressureTex:SetBlendMode("ADD")
  ui.boardGlow = ui.board:CreateTexture(nil, "OVERLAY") ui.boardGlow:SetAllPoints() ui.boardGlow:SetBlendMode("ADD")
  ui.pressureBorder = CreateFrame("Frame", nil, ui.board, "BackdropTemplate")
  ui.pressureBorder:SetAllPoints() ui.pressureBorder:SetFrameLevel(ui.board:GetFrameLevel() + 8)
  ui.pressureBorder:SetBackdrop({ edgeFile = WHITE_TEXTURE, edgeSize = 3 })
  for r = 1, GRID do
    for c = 1, GRID do
      local cell = CreateFrame("Frame", nil, ui.board)
      cell:SetSize(TILE_SIZE, TILE_SIZE)
      local x, y = CellXY(r, c) cell:SetPoint("TOPLEFT", x, y)
      local slot = cell:CreateTexture(nil, "BACKGROUND")
      slot:SetTexture(TEX.slot) slot:SetSize(TILE_SIZE * SLOT_SCALE, TILE_SIZE * SLOT_SCALE) slot:SetPoint("CENTER", cell, "CENTER", 0, 0)
      ui.cells[#ui.cells + 1] = slot
    end
  end

  ui.gameOverOverlay = CreateFrame("Frame", nil, ui.board)
  ui.gameOverOverlay:SetAllPoints() ui.gameOverOverlay:SetFrameStrata("DIALOG") ui.gameOverOverlay:SetFrameLevel(ui.board:GetFrameLevel() + 10) ui.gameOverOverlay:Hide()
  ui.gameOverDim = ui.gameOverOverlay:CreateTexture(nil, "BACKGROUND") ui.gameOverDim:SetAllPoints() ui.gameOverDim:SetColorTexture(0.01, 0.015, 0.02, 0.88)
  local panel = CreatePanel(ui.gameOverOverlay, "panel") panel:SetPoint("CENTER") panel:SetSize(286, 224)
  local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge") hdr:SetPoint("TOP", 0, -18) hdr:SetText("Flight Ended")
  local scoreLine = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight") scoreLine:SetPoint("TOP", hdr, "BOTTOM", 0, -12)
  ui.gameOverTitle, ui.gameOverScore = hdr, scoreLine
  ui.gameOverOverlay:SetScript("OnShow", function() scoreLine:SetText("Final score  " .. FormatNumber(state.score or 0)) end)
  ui.playAgainBtn = CreateWoWButton(panel, "Play again", 224, 24) ui.playAgainBtn:SetPoint("BOTTOM", 0, 88) ui.playAgainBtn:SetScript("OnClick", ResetGame)
  ui.announceBtn = CreateWoWButton(panel, "Brag to Guild", 224, 24) ui.announceBtn:SetPoint("BOTTOM", 0, 54) ui.announceBtn:SetScript("OnClick", AnnounceScoreToGuild)
  ui.curseBtn = CreateWoWButton(panel, "CurseForge link", 224, 24) ui.curseBtn:SetPoint("BOTTOM", 0, 20) ui.curseBtn:SetScript("OnClick", PutCurseLinkInChat)

  f:SetScript("OnKeyDown", function(self, key)
    if ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() and ChatEdit_GetActiveWindow():IsShown() then return end
    if key == "ESCAPE" then f:Hide() return elseif key == "R" then ResetGame() return end
    local dir = KEYMAP[key] if not dir or state.over then return end
    if state.inputLocked or ui.anim.active then state.queuedDir = dir return end
    ApplyMovePlan(dir)
  end)
  f:SetScript("OnShow", function()
    f:SetFrameStrata("DIALOG") f:SetFrameLevel(100) ApplyPressureVisuals() UpdateUI()
    for _, egg in ipairs(EGGS) do
      if Fly2048DB[egg.flag] and not state.eggPlayed[egg.id] then PlayEgg(egg) break end
    end
  end)
  f:SetScript("OnUpdate", function(_, elapsed)
    ApplyShake(elapsed) MaybeHeartbeat(elapsed)
    if state.scoreRollup.active then
      state.scoreRollup.t = state.scoreRollup.t + elapsed
      local rp = math.min(1, state.scoreRollup.t / MotionDuration(ROLLUP_DURATION))
      local displayed = math.floor(Lerp(state.scoreRollup.fromVal, state.scoreRollup.toVal, EaseOutCubic(rp)))
      if ui.scoreText then ui.scoreText:SetText(FormatNumber(displayed)) end
      if rp >= 1 then
        state.scoreRollup.active = false
        if ui.scoreText then ui.scoreText:SetText(FormatNumber(state.score)) end
      end
    end
    if ui.boardGlowA > 0 then
      ui.boardGlowA = math.max(0, ui.boardGlowA - elapsed * (IsReducedMotion() and 5 or 1.7))
      SetTextureColor(ui.boardGlow, GetTheme().accent, ui.boardGlowA)
    end
    if ui.pressureA > 0 then
      ui.pressureT = ui.pressureT + elapsed
      local pulse = IsReducedMotion() and 0.72 or (0.62 + math.sin(ui.pressureT * 5) * 0.20)
      SetBackdrop(ui.pressureBorder, nil, GetTheme().danger, nil, ui.pressureA * pulse)
    end
    for _, t in pairs(state.tiles) do if t.flashA > 0 then t.flashA = math.max(0, t.flashA - (elapsed / FLASH_TIME) * FLASH_ALPHA) t.flash:SetColorTexture(1, 1, 1, t.flashA) end end
    if ui.anim.active then
      ui.anim.t = ui.anim.t + elapsed
      local t = math.min(1, ui.anim.t / MotionDuration(ANIM_TIME))
      for _, mover in ipairs(ui.anim.movers) do if mover.frame and mover.ex then mover.frame:SetPoint("TOPLEFT", ui.board, "TOPLEFT", Lerp(mover.sx, mover.ex, EaseOutCubic(t)), Lerp(mover.sy, mover.ey, EaseOutCubic(t))) end end
      if t >= 1 then ui.anim.active, ui.anim.t = false, 0 CommitMove() if #ui.anim.pops > 0 then ui.anim.popActive, ui.anim.popT = true, 0 end if #ui.anim.spawns > 0 then ui.anim.spawnActive, ui.anim.spawnT = true, 0 end end
    end
    if ui.anim.popActive then
      ui.anim.popT = ui.anim.popT + elapsed
      local t = math.min(1, ui.anim.popT / MotionDuration(POP_TIME))
      local s = t < 0.5 and Lerp(1, POP_SCALE, t/0.5) or Lerp(POP_SCALE, 1, (t-0.5)/0.5)
      for _, tObj in ipairs(ui.anim.pops) do if tObj.frame then tObj.frame:SetScale(s) end end
      if t >= 1 then ui.anim.popActive, ui.anim.popT, ui.anim.pops = false, 0, {} end
    end
    if ui.anim.spawnActive then
      ui.anim.spawnT = ui.anim.spawnT + elapsed
      local t = math.min(1, ui.anim.spawnT / MotionDuration(SPAWN_TIME))
      for _, tObj in ipairs(ui.anim.spawns) do if tObj.frame then tObj.frame:SetScale(Lerp(0.98, SPAWN_POP, EaseOutCubic(t))) end end
      if t >= 1 then for _, tObj in ipairs(ui.anim.spawns) do if tObj.frame then tObj.frame:SetScale(1) end end ui.anim.spawnActive, ui.anim.spawnT, ui.anim.spawns = false, 0, {} end
    end
    -- Score delta floats (+N rise above score)
    for i = #ui.scoreDeltas, 1, -1 do
      local d = ui.scoreDeltas[i]
      d.t = d.t + elapsed
      if d.t < 0 then
        d.label:SetAlpha(0)
      elseif d.t >= d.duration then
        d.label:Hide() d.label:SetParent(nil)
        table.remove(ui.scoreDeltas, i)
      else
        local prog = d.t / d.duration
        d.label:ClearAllPoints()
        d.label:SetPoint("TOPLEFT", ui.scoreText, "TOPLEFT", 0, (IsReducedMotion() and 4 or DELTA_RISE_DIST) * EaseOutCubic(prog))
        d.label:SetAlpha(1 - EaseOutCubic(prog))
      end
    end
    for _, row in ipairs(ui.guildRows) do
      if row.pulseA and row.pulseA > 0 then
        row.pulseA = math.max(0, row.pulseA - elapsed * 1.7)
        SetTextureColor(row.highlight, GetTheme().accent, row.pulseA)
      end
    end
    UpdateLeaderboardRowPositions(elapsed)
    if not state.over and not state.inputLocked and not ui.anim.active and state.queuedDir then local d = state.queuedDir state.queuedDir = nil ApplyMovePlan(d) end
  end)
  ApplyTheme()
  f:Hide()
end

local function Toggle() BuildUI() if ui.frame:IsShown() then ui.frame:Hide() state.autoShown = false else if not next(state.tiles) then ResetGame() end ui.frame:Show() end end

local function PrintMessage(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff59d9e8Fly2048|r  " .. message) end
end

local function PrintHelp()
  PrintMessage("/fly2048 - show or hide")
  PrintMessage("reset | mute | auto | theme [alliance/horde] | motion [full/reduced]")
  PrintMessage("scale [0.75-1.25] | center | demo | test | testclear")
end

SLASH_FLY20481 = "/fly2048"
SlashCmdList["FLY2048"] = function(msg)
  local command, argument = (msg or ""):lower():match("^(%S*)%s*(.-)$")
  for _, egg in ipairs(EGGS) do  -- undocumented: switch a corner-button tune off or on again
    if command == egg.command then
      Fly2048DB[egg.flag] = not Fly2048DB[egg.flag]
      PrintMessage(Fly2048DB[egg.flag] and "Aye." or "Nay.")
      return
    end
  end
  if command == "" then Toggle() return
  elseif command == "reset" or command == "r" then BuildUI() ResetGame() ui.frame:Show() state.autoShown = false return
  elseif command == "mute" or command == "sound" then ToggleSound() PrintMessage(Fly2048DB.mute and "Sound muted." or "Sound enabled.") return
  elseif command == "auto" then Fly2048DB.autopopup = (Fly2048DB.autopopup ~= true) UpdateUI() PrintMessage("Taxi auto-popup " .. (Fly2048DB.autopopup and "enabled." or "disabled.")) return
  elseif command == "theme" then
    if THEMES[argument] then Fly2048DB.theme = argument ApplyTheme() UpdateUI() else CycleTheme() end
    PrintMessage("Theme: " .. GetTheme().name .. ".")
    return
  elseif command == "motion" then
    if argument == "full" or argument == "reduced" then Fly2048DB.motion = argument UpdateUI() else ToggleMotion() end
    PrintMessage("Motion: " .. (IsReducedMotion() and "reduced." or "full."))
    return
  elseif command == "scale" then
    local scale = tonumber(argument)
    if not scale then PrintMessage(("Scale is %.2f. Use /fly2048 scale 0.75-1.25."):format(Fly2048DB.uiScale or 1)) return end
    Fly2048DB.uiScale = Clamp(scale, 0.75, 1.25)
    BuildUI() ui.frame:SetScale(Fly2048DB.uiScale)
    PrintMessage(("Scale set to %.2f."):format(Fly2048DB.uiScale))
    return
  elseif command == "center" then
    Fly2048DB.position = nil
    BuildUI() ui.frame:ClearAllPoints() ui.frame:SetPoint("CENTER")
    PrintMessage("Window centred.")
    return
  elseif command == "demo" then
    BuildUI() LoadVisualDemo() ui.frame:Show()
    PrintMessage("Visual demo loaded. Use /fly2048 reset to return to a normal game.")
    return
  elseif command == "help" then PrintHelp() return
  elseif command == "test" then
    BuildUI()
    local realm = (GetRealmName and GetRealmName()) or "Test"
    local fakes = { {"Arthas", 8192}, {"Sylvanas", 4096}, {"Thrall", 2048}, {"Jaina", 1024}, {"Garrosh", 512} }
    Fly2048DB.guildScores = Fly2048DB.guildScores or {}
    for _, pair in ipairs(fakes) do Fly2048DB.guildScores[pair[1] .. "-" .. realm] = pair[2] end
    RefreshLeaderboard()
    ui.frame:Show()
    PrintMessage("Test scores added. Use /fly2048 testclear to remove them.")
    return
  elseif command == "testclear" then
    Fly2048DB.guildScores = {}
    if ui.frame then RefreshLeaderboard() end
    PrintMessage("Test scores cleared.")
    return
  end
  PrintHelp()
end

-- Retail's AddOn Compartment calls these globals by name from the Mainline TOC.
function Fly2048_OnAddonCompartmentClick(_, buttonInfo)
  local buttonName = type(buttonInfo) == "table" and buttonInfo.buttonName or buttonInfo
  if buttonName == "RightButton" then CycleTheme() else Toggle() end
end

function Fly2048_OnAddonCompartmentEnter(_, menuButton)
  if not GameTooltip or not menuButton then return end
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip:SetText("Fly2048")
  GameTooltip:AddLine("Left-click to play. Right-click to switch faction colours.", 1, 1, 1, true)
  GameTooltip:Show()
end

function Fly2048_OnAddonCompartmentLeave()
  if GameTooltip then GameTooltip:Hide() end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    Fly2048DB.best, Fly2048DB.mute, Fly2048DB.autopopup = tonumber(Fly2048DB.best) or 0, (Fly2048DB.mute == true), (Fly2048DB.autopopup ~= false)
    Fly2048DB.guildScores = Fly2048DB.guildScores or {}
    Fly2048DB.guildClasses = Fly2048DB.guildClasses or {}
    -- Old "arcane"/"ember" (or missing) themes become the player's faction. Only
    -- store a key once the faction is known; GetTheme() copes with nil meanwhile.
    if not THEMES[Fly2048DB.theme] then Fly2048DB.theme = PlayerFaction() and DefaultThemeKey() or nil end
    if Fly2048DB.motion ~= "reduced" then Fly2048DB.motion = "full" end
    Fly2048DB.uiScale = Clamp(tonumber(Fly2048DB.uiScale) or 1, 0.75, 1.25)
    Fly2048DB.schemaVersion = 3
    state.best = Fly2048DB.best
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(MSG_PREFIX)
    elseif RegisterAddonMessagePrefix then
      RegisterAddonMessagePrefix(MSG_PREFIX)
    end
    BuildUI()
    self:RegisterEvent("PLAYER_CONTROL_LOST") self:RegisterEvent("PLAYER_CONTROL_GAINED") self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_ADDON")
    AutoPing()
    if C_Timer and C_Timer.NewTicker then
      C_Timer.NewTicker(GUILD_AUTO_INTERVAL, function() AutoPing() end)
    else
      local function scheduleNext() After(GUILD_AUTO_INTERVAL, function() AutoPing() scheduleNext() end) end
      scheduleNext()
    end
    return
  end
  if event == "CHAT_MSG_ADDON" then
    HandleAddonMessage(arg1, arg2, arg3, arg4)
    return
  end
  if event == "PLAYER_ENTERING_WORLD" and Fly2048DB and not THEMES[Fly2048DB.theme] and PlayerFaction() then
    -- Faction was unknown at ADDON_LOADED; settle the default now.
    Fly2048DB.theme = DefaultThemeKey() ApplyTheme() UpdateUI()
  end
  if not Fly2048DB or Fly2048DB.autopopup ~= true then return end
  if event == "PLAYER_CONTROL_LOST" then After(0.20, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true end end)
  elseif event == "PLAYER_CONTROL_GAINED" then After(0.10, function() if not (UnitOnTaxi and UnitOnTaxi("player")) and state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end)
  elseif event == "PLAYER_ENTERING_WORLD" then AutoPing() After(0.50, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true else if state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end end) end
end)
