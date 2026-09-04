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
local HEADER_H = 78
local FRAME_PAD = 16
local BOARD_INNER_W = GRID * TILE_SIZE + (GRID - 1) * TILE_PAD  -- 366
local LBOARD_GAP    = 12
local LBOARD_X      = FRAME_PAD + BOARD_INNER_W + LBOARD_GAP

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

-- All visual decisions live here so a theme can be changed without touching
-- gameplay code. Values are RGBA in the same 0..1 range used by the WoW API.
local THEMES = {
  arcane = {
    name = "Arcane",
    frame = { 0.035, 0.059, 0.090, 0.98 },
    panel = { 0.055, 0.098, 0.140, 0.96 },
    panelAlt = { 0.075, 0.128, 0.174, 0.92 },
    board = { 0.025, 0.047, 0.070, 1.00 },
    cell = { 0.105, 0.165, 0.210, 0.72 },
    border = { 0.170, 0.300, 0.390, 0.90 },
    accent = { 0.350, 0.850, 0.910, 1.00 },
    accentSoft = { 0.180, 0.480, 0.560, 0.45 },
    gold = { 0.960, 0.750, 0.250, 1.00 },
    text = { 0.925, 0.960, 0.980, 1.00 },
    muted = { 0.520, 0.640, 0.710, 1.00 },
    danger = { 0.960, 0.300, 0.360, 1.00 },
    success = { 0.350, 0.920, 0.650, 1.00 },
    tiles = {
      [2] = { 0.150, 0.285, 0.410, 1 }, [4] = { 0.145, 0.390, 0.500, 1 },
      [8] = { 0.105, 0.500, 0.520, 1 }, [16] = { 0.140, 0.600, 0.430, 1 },
      [32] = { 0.390, 0.660, 0.300, 1 }, [64] = { 0.700, 0.640, 0.210, 1 },
      [128] = { 0.820, 0.480, 0.190, 1 }, [256] = { 0.830, 0.285, 0.180, 1 },
      [512] = { 0.720, 0.190, 0.330, 1 }, [1024] = { 0.490, 0.250, 0.700, 1 },
      [2048] = { 0.920, 0.680, 0.150, 1 }, [4096] = { 0.780, 0.780, 0.900, 1 },
    },
  },
  ember = {
    name = "Ember",
    frame = { 0.080, 0.045, 0.035, 0.98 },
    panel = { 0.135, 0.070, 0.045, 0.96 },
    panelAlt = { 0.180, 0.095, 0.055, 0.92 },
    board = { 0.055, 0.030, 0.025, 1.00 },
    cell = { 0.220, 0.120, 0.075, 0.68 },
    border = { 0.420, 0.205, 0.105, 0.90 },
    accent = { 1.000, 0.500, 0.190, 1.00 },
    accentSoft = { 0.650, 0.250, 0.080, 0.38 },
    gold = { 1.000, 0.780, 0.260, 1.00 },
    text = { 1.000, 0.945, 0.875, 1.00 },
    muted = { 0.720, 0.560, 0.440, 1.00 },
    danger = { 1.000, 0.220, 0.180, 1.00 },
    success = { 0.620, 0.900, 0.360, 1.00 },
    tiles = {
      [2] = { 0.270, 0.180, 0.130, 1 }, [4] = { 0.390, 0.235, 0.135, 1 },
      [8] = { 0.550, 0.300, 0.120, 1 }, [16] = { 0.700, 0.350, 0.100, 1 },
      [32] = { 0.820, 0.310, 0.100, 1 }, [64] = { 0.900, 0.220, 0.100, 1 },
      [128] = { 0.780, 0.160, 0.160, 1 }, [256] = { 0.650, 0.130, 0.260, 1 },
      [512] = { 0.550, 0.190, 0.430, 1 }, [1024] = { 0.450, 0.250, 0.620, 1 },
      [2048] = { 0.950, 0.650, 0.120, 1 }, [4096] = { 0.980, 0.820, 0.330, 1 },
    },
  },
}
local THEME_ORDER = { "arcane", "ember" }

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

local LEVELUP_SFX  = "Sound\\Interface\\LevelUp.ogg"
local GAMEOVER_SFX = "Sound\\Interface\\igQuestFailed.ogg"
local PRESSURE_HEARTBEAT_SFX = "Sound\\Interface\\iAbilitiesTurnPageA.ogg"
local PRESSURE_BEAT_INTERVAL = 1.00

local MILESTONE_VALUES = { 512, 1024, 2048, 4096 }
local MILESTONE_SFX_512  = "Sound\\Interface\\MapPing.ogg"
local MILESTONE_SFX_2048 = "Sound\\Interface\\RaidWarning.ogg"

local DIVINE_RESET_SFX = "Sound\\Interface\\igMainMenuOptionCheckBoxOn.ogg"
local CURSE_URL = "https://www.curseforge.com/wow/addons/fly2048"

local TEX_BORDER_GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
local TEX_STAR        = "Interface\\Cooldown\\star4"

local KEYMAP = {
  ["UP"] = "up", ["DOWN"] = "down", ["LEFT"] = "left", ["RIGHT"] = "right",
  ["W"] = "up", ["S"] = "down", ["A"] = "left", ["D"] = "right",
}

-- Guild / score-animation config
local MSG_PREFIX            = "Fly2048"
local GUILD_PANEL_W         = 224
local GUILD_ROW_H           = 22
local GUILD_ROW_PAD         = 5
local GUILD_MAX_ROWS        = 10
local LBOARD_ROW_TOP        = 152  -- px below the outer frame padding
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
local function Log2(x) return math.log(x) / math.log(2) end
local function RandomTileValue() return math.random() < 0.10 and 4 or 2 end

local function GetTheme()
  local key = Fly2048DB and Fly2048DB.theme or "arcane"
  return THEMES[key] or THEMES.arcane
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

local function PlaySFX(path, channel)
  if Fly2048DB and Fly2048DB.mute then return end
  PlaySoundFile(path, channel or "SFX")
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

local function TileColor(v)
  local theme = GetTheme()
  local color = theme.tiles[v]
  if color then return color[1], color[2], color[3], color[4] end

  -- Values above the authored palette become increasingly luminous legendary
  -- tiles instead of falling back to an unrelated procedural rainbow.
  local t = Clamp((Log2(v) - 12) / 5, 0, 1)
  return Lerp(theme.gold[1], theme.text[1], t),
         Lerp(theme.gold[2], theme.text[2], t),
         Lerp(theme.gold[3], theme.text[3], t), 1
end

local function GetFontForValue(v)
  local fLarge, fMid = _G.GameFontNormalLarge or _G.GameFontHighlightLarge or _G.GameFontNormal, _G.GameFontNormal or _G.GameFontHighlight
  local fSmall = _G.GameFontNormalSmall or _G.GameFontHighlightSmall or fMid
  if v >= 16384 then return fSmall elseif v >= 1024 then return fMid end
  return fLarge
end

local function CreatePanel(parent, backgroundKey)
  local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  panel:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
  panel.themeBackgroundKey = backgroundKey or "panel"
  ui.themeRefs[#ui.themeRefs + 1] = panel
  return panel
end

local function CreateThemedButton(parent, text)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
  button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  button.label:SetPoint("CENTER", 0, 0)
  button.SetText = function(self, value) self.label:SetText(value) end
  button:SetText(text)
  button.themeBackgroundKey = "panelAlt"
  button.isThemedButton = true
  button:SetScript("OnEnter", function(self)
    local theme = GetTheme()
    SetBackdrop(self, theme.accentSoft, theme.accent, 0.72, 0.95)
    SetTextColor(self.label, theme.text)
  end)
  button:SetScript("OnLeave", function(self)
    local theme = GetTheme()
    SetBackdrop(self, theme.panelAlt, theme.border)
    SetTextColor(self.label, theme.text)
  end)
  button:SetScript("OnDisable", function(self)
    local theme = GetTheme()
    SetBackdrop(self, theme.panel, theme.border, 0.55, 0.38)
    SetTextColor(self.label, theme.muted, 0.52)
  end)
  button:SetScript("OnEnable", function(self)
    local theme = GetTheme()
    SetBackdrop(self, theme.panelAlt, theme.border)
    SetTextColor(self.label, theme.text)
  end)
  button:SetScript("OnMouseDown", function(self) if self:IsEnabled() then self.label:ClearAllPoints() self.label:SetPoint("CENTER", 0, -1) end end)
  button:SetScript("OnMouseUp", function(self) self.label:ClearAllPoints() self.label:SetPoint("CENTER", 0, 0) end)
  ui.themeRefs[#ui.themeRefs + 1] = button
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
  if state.pressureBeatT >= PRESSURE_BEAT_INTERVAL then state.pressureBeatT = 0 PlaySoundFile(PRESSURE_HEARTBEAT_SFX, "SFX") end
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
      if value == 512 then PlaySFX(MILESTONE_SFX_512) elseif value >= 2048 then PlaySFX(MILESTONE_SFX_2048) end
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
  PlaySFX(DIVINE_RESET_SFX)
  TriggerBoardGlow(0.35)
  local vr, vc = victim.r, victim.c
  DestroyTile(victim)
  if ui.board and vr and vc then
    local f = CreateFrame("Frame", nil, ui.board) f:SetSize(TILE_SIZE, TILE_SIZE)
    local x, y = CellXY(vr, vc) f:SetPoint("TOPLEFT", ui.board, "TOPLEFT", x, y)
    local t = f:CreateTexture(nil, "OVERLAY") t:SetAllPoints(f) t:SetTexture(TEX_STAR) t:SetBlendMode("ADD") t:SetAlpha(0.0)
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
  local r, g, b, a = TileColor(tile.value)
  tile.bg:SetColorTexture(r, g, b, a)
  if tile.frame.SetBackdropBorderColor then
    local lift = tile.value >= 512 and 0.24 or 0.12
    tile.frame:SetBackdropBorderColor(Clamp(r + lift, 0, 1), Clamp(g + lift, 0, 1), Clamp(b + lift, 0, 1), tile.value >= 512 and 0.95 or 0.62)
  end
  local fo = GetFontForValue(tile.value)
  if fo then tile.text:SetFontObject(fo) end
  local font, size = tile.text:GetFont()
  if font then tile.text:SetFont(font, size or 18, "OUTLINE") end
  tile.text:SetText(tostring(tile.value))
  local luminance = (r * 0.2126) + (g * 0.7152) + (b * 0.0722)
  if luminance > 0.62 then
    tile.text:SetTextColor(0.055, 0.070, 0.085, 1)
    tile.text:SetShadowColor(1, 1, 1, 0.14)
  else
    tile.text:SetTextColor(0.965, 0.980, 1.000, 1)
    tile.text:SetShadowColor(0, 0, 0, 0.52)
  end
  tile.text:SetShadowOffset(1.2, -1.2)
  tile.border:SetAlpha(tile.value >= 2048 and 0.38 or (tile.value >= 512 and 0.18 or 0))
end

local function ApplyTheme()
  local theme = GetTheme()
  if ui.frame then SetBackdrop(ui.frame, theme.frame, theme.border) end
  for _, ref in ipairs(ui.themeRefs) do
    if ref and ref.SetBackdropColor then
      local bg = theme[ref.themeBackgroundKey or "panel"] or theme.panel
      SetBackdrop(ref, bg, theme.border)
      if ref.isThemedButton and ref.label then SetTextColor(ref.label, theme.text) end
    end
  end
  for _, cell in ipairs(ui.cells) do SetTextureColor(cell, theme.cell) end
  if ui.board then SetBackdrop(ui.board, theme.board, theme.border) end
  if ui.titleText then SetTextColor(ui.titleText, theme.text) end
  if ui.subtitleText then ui.subtitleText:SetText(theme.name:upper() .. " FLIGHT EDITION") SetTextColor(ui.subtitleText, theme.accent) end
  if ui.statusText then SetTextColor(ui.statusText, theme.muted) end
  if ui.rightTitle then SetTextColor(ui.rightTitle, theme.text) end
  if ui.guildLabel then SetTextColor(ui.guildLabel, theme.muted) end
  if ui.comboText then SetTextColor(ui.comboText, theme.accent) end
  if ui.gameOverTitle then SetTextColor(ui.gameOverTitle, theme.text) end
  if ui.gameOverScore then SetTextColor(ui.gameOverScore, theme.gold) end
  if ui.headerLine then SetTextureColor(ui.headerLine, theme.accentSoft) end
  if ui.separator then SetTextureColor(ui.separator, theme.border, 0.70) end
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
  f:SetBackdrop({ edgeFile = WHITE_TEXTURE, edgeSize = 1 })
  local shadow = f:CreateTexture(nil, "BACKGROUND") shadow:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3) shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3) shadow:SetColorTexture(0, 0, 0, 0.24)
  local bg = f:CreateTexture(nil, "BACKGROUND") bg:SetAllPoints(f)
  local gloss = f:CreateTexture(nil, "ARTWORK") gloss:SetTexture(WHITE_TEXTURE) gloss:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2) gloss:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2) gloss:SetHeight(TILE_SIZE * 0.42) gloss:SetColorTexture(1, 1, 1, 0.035)
  local border = f:CreateTexture(nil, "OVERLAY") border:SetTexture(TEX_BORDER_GLOW) border:SetBlendMode("ADD") border:SetPoint("CENTER", f, "CENTER", 0, 0) border:SetSize(TILE_SIZE * 1.6, TILE_SIZE * 1.6) border:SetAlpha(0.22)
  local flash = f:CreateTexture(nil, "OVERLAY") flash:SetAllPoints(f) flash:SetColorTexture(1, 1, 1, 0)
  local spark = f:CreateTexture(nil, "OVERLAY") spark:SetTexture(TEX_STAR) spark:SetBlendMode("ADD") spark:SetPoint("CENTER", f, "CENTER", 0, 0) spark:SetSize(TILE_SIZE * 1.1, TILE_SIZE * 1.1) spark:SetAlpha(0) spark:Hide()
  local sparkAG = spark:CreateAnimationGroup()
  local a1 = sparkAG:CreateAnimation("Alpha") a1:SetFromAlpha(0) a1:SetToAlpha(0.85) a1:SetDuration(0.06) a1:SetOrder(1)
  local s1 = sparkAG:CreateAnimation("Scale") s1:SetScaleFrom(0.6, 0.6) s1:SetScaleTo(1.3, 1.3) s1:SetDuration(0.10) s1:SetOrder(1)
  local a2 = sparkAG:CreateAnimation("Alpha") a2:SetFromAlpha(0.85) a2:SetToAlpha(0) a2:SetDuration(0.12) a2:SetOrder(2)
  sparkAG:SetScript("OnFinished", function() spark:Hide() spark:SetAlpha(0) spark:SetScale(1) end)
  local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") txt:SetPoint("CENTER", f, "CENTER", 0, 0)

  local tile = { id = id, frame = f, bg = bg, shadow = shadow, gloss = gloss, border = border, flash = flash, flashA = 0, spark = spark, sparkAG = sparkAG, text = txt, r = r, c = c, value = value, sx = 0, sy = 0, ex = 0, ey = 0, tr = r, tc = c, mergeInto = nil, mergedThisTurn = false, pop = false, spawnPop = false }
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
  local msg = "SCORE:" .. state.best
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(MSG_PREFIX, msg, "GUILD")
  elseif SendAddonMessage then
    SendAddonMessage(MSG_PREFIX, msg, "GUILD")
  end
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
  local score = tonumber(msg:match("^SCORE:(%d+)$"))
  if score then
    Fly2048DB.guildScores = Fly2048DB.guildScores or {}
    local existing = Fly2048DB.guildScores[sender] or 0
    if score > existing then
      Fly2048DB.guildScores[sender] = score
      RefreshLeaderboard()
    end
  elseif msg == "REQUEST" then
    After(math.random() * GUILD_JITTER_MAX, BroadcastScore)
  end
end

local function BuildSortedGuild()
  local list = {}
  local localKey = GetLocalKey()
  Fly2048DB.guildScores = Fly2048DB.guildScores or {}
  for k, v in pairs(Fly2048DB.guildScores) do
    if k ~= localKey then
      list[#list + 1] = { name = k, score = v, isLocal = false }
    end
  end
  local displayScore = math.max(state.best or 0, state.score or 0)
  if displayScore > 0 then
    list[#list + 1] = { name = localKey, score = displayScore, isLocal = true }
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
      row.rankText:SetText(tostring(i))
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
        SetTextColor(row.nameText, theme.text, 0.90)
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
  local current = Fly2048DB.theme or "arcane"
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
    if self.isThemedButton then SetBackdrop(self, theme.accentSoft, theme.accent, 0.72, 0.95) end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(title, theme.accent[1], theme.accent[2], theme.accent[3])
    if body then GameTooltip:AddLine(body, theme.text[1], theme.text[2], theme.text[3], true) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function(self)
    local theme = GetTheme()
    if self.isThemedButton then
      if self.IsEnabled and self:IsEnabled() then SetBackdrop(self, theme.panelAlt, theme.border) else SetBackdrop(self, theme.panel, theme.border, 0.55, 0.38) end
    end
    if GameTooltip then GameTooltip:Hide() end
  end)
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
  if not HasMoves() then state.over = true if state.newBestThisRun then PlaySFX(LEVELUP_SFX) else PlaySFX(GAMEOVER_SFX) end end
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
  f:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    Fly2048DB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
  end)
  f:EnableKeyboard(true) f:SetPropagateKeyboardInput(false)

  ui.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.titleText:SetPoint("TOPLEFT", FRAME_PAD, -FRAME_PAD)
  ui.titleText:SetText("Fly2048")
  ui.subtitleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.subtitleText:SetPoint("TOPLEFT", ui.titleText, "BOTTOMLEFT", 0, -2)
  ui.subtitleText:SetText("ARCANE FLIGHT EDITION")
  ui.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.statusText:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + 48))

  ui.themeBtn = CreateThemedButton(f, "Arcane")
  ui.themeBtn:SetSize(66, 24) ui.themeBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 166, -18)
  ui.themeBtn:SetScript("OnClick", CycleTheme)
  AddTooltip(ui.themeBtn, "Colour theme", "Switch between the Arcane and Ember palettes.")
  ui.motionBtn = CreateThemedButton(f, "Motion")
  ui.motionBtn:SetSize(66, 24) ui.motionBtn:SetPoint("LEFT", ui.themeBtn, "RIGHT", 5, 0)
  ui.motionBtn:SetScript("OnClick", ToggleMotion)
  AddTooltip(ui.motionBtn, "Motion", "Toggle full and reduced animation modes.")
  ui.soundBtn = CreateThemedButton(f, "Sound on")
  ui.soundBtn:SetSize(66, 24) ui.soundBtn:SetPoint("LEFT", ui.motionBtn, "RIGHT", 5, 0)
  ui.soundBtn:SetScript("OnClick", ToggleSound)
  AddTooltip(ui.soundBtn, "Sound", "Mute or enable Fly2048 sound effects.")

  ui.comboText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.comboText:SetPoint("TOPRIGHT", f, "TOPLEFT", FRAME_PAD + BOARD_INNER_W, -(FRAME_PAD + 51))
  ui.comboText:Hide()
  ui.headerLine = f:CreateTexture(nil, "ARTWORK")
  ui.headerLine:SetHeight(1) ui.headerLine:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H - 6)) ui.headerLine:SetPoint("TOPRIGHT", f, "TOPLEFT", FRAME_PAD + BOARD_INNER_W, -(FRAME_PAD + HEADER_H - 6))
  CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -3, -3)

  ui.separator = f:CreateTexture(nil, "BACKGROUND")
  ui.separator:SetWidth(1) ui.separator:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X - LBOARD_GAP/2, -FRAME_PAD) ui.separator:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LBOARD_X - LBOARD_GAP/2, FRAME_PAD)

  ui.rightTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.rightTitle:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -FRAME_PAD)
  ui.rightTitle:SetText("Flightboard")

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

  ui.resetBtn = CreateThemedButton(f, "Divine Reset")
  ui.resetBtn:SetSize(GUILD_PANEL_W, 26) ui.resetBtn:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 84))
  ui.resetBtn:SetScript("OnClick", function() DoDivineReset() UpdateUI() end)
  AddTooltip(ui.resetBtn, "Divine Reset", "Once per game, remove the lowest-value tile.")

  ui.guildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.guildLabel:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, -(FRAME_PAD + 122))
  ui.guildLabel:SetText("GUILD RANKING")

  ui.pingBtn = CreateThemedButton(f, "Refresh guild scores")
  ui.pingBtn:SetSize(GUILD_PANEL_W, 26)
  ui.pingBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LBOARD_X, FRAME_PAD)
  ui.pingBtn:SetScript("OnClick", function() if state.guildPingCooldown <= 0 then AutoPing() end end)
  AddTooltip(ui.pingBtn, "Guild scores", "Ask online guild members running Fly2048 for their best score.")

  ui.guildRows = {}
  for i = 1, GUILD_MAX_ROWS do
    local row = CreateFrame("Frame", nil, f)
    row.index, row.pulseA = i, 0
    row:SetSize(GUILD_PANEL_W, GUILD_ROW_H)
    local ty = GetRowTargetY(i)
    row:SetPoint("TOPLEFT", f, "TOPLEFT", LBOARD_X, ty)
    row.fromY, row.targetY, row.sliding, row.slideT = ty, ty, false, 0
    row.background = row:CreateTexture(nil, "BACKGROUND") row.background:SetAllPoints()
    row.highlight = row:CreateTexture(nil, "ARTWORK") row.highlight:SetAllPoints() row.highlight:SetBlendMode("ADD")
    row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rankText:SetPoint("LEFT", 6, 0) row.rankText:SetWidth(20) row.rankText:SetJustifyH("LEFT")
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row.rankText, "RIGHT", 3, 0) row.nameText:SetWidth(118) row.nameText:SetJustifyH("LEFT")
    row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.scoreText:SetPoint("RIGHT", row, "RIGHT", -6, 0) row.scoreText:SetWidth(62) row.scoreText:SetJustifyH("RIGHT")
    row:Hide()
    ui.guildRows[i] = row
  end

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
      local texture = cell:CreateTexture(nil, "BACKGROUND") texture:SetAllPoints()
      ui.cells[#ui.cells + 1] = texture
    end
  end

  ui.gameOverOverlay = CreateFrame("Frame", nil, ui.board)
  ui.gameOverOverlay:SetAllPoints() ui.gameOverOverlay:SetFrameStrata("DIALOG") ui.gameOverOverlay:SetFrameLevel(ui.board:GetFrameLevel() + 10) ui.gameOverOverlay:Hide()
  ui.gameOverDim = ui.gameOverOverlay:CreateTexture(nil, "BACKGROUND") ui.gameOverDim:SetAllPoints() ui.gameOverDim:SetColorTexture(0.01, 0.015, 0.02, 0.88)
  local panel = CreatePanel(ui.gameOverOverlay, "panel") panel:SetPoint("CENTER") panel:SetSize(286, 224)
  local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") hdr:SetPoint("TOP", 0, -18) hdr:SetText("Flight ended")
  local scoreLine = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight") scoreLine:SetPoint("TOP", hdr, "BOTTOM", 0, -12)
  ui.gameOverTitle, ui.gameOverScore = hdr, scoreLine
  ui.gameOverOverlay:SetScript("OnShow", function() scoreLine:SetText("Final score  " .. FormatNumber(state.score or 0)) end)
  ui.playAgainBtn = CreateThemedButton(panel, "Play again") ui.playAgainBtn:SetSize(224, 28) ui.playAgainBtn:SetPoint("BOTTOM", 0, 88) ui.playAgainBtn:SetScript("OnClick", ResetGame)
  ui.announceBtn = CreateThemedButton(panel, "Brag to Guild") ui.announceBtn:SetSize(224, 28) ui.announceBtn:SetPoint("BOTTOM", 0, 54) ui.announceBtn:SetScript("OnClick", AnnounceScoreToGuild)
  ui.curseBtn = CreateThemedButton(panel, "CurseForge link") ui.curseBtn:SetSize(224, 28) ui.curseBtn:SetPoint("BOTTOM", 0, 20) ui.curseBtn:SetScript("OnClick", PutCurseLinkInChat)

  f:SetScript("OnKeyDown", function(self, key)
    if ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() and ChatEdit_GetActiveWindow():IsShown() then return end
    if key == "ESCAPE" then f:Hide() return elseif key == "R" then ResetGame() return end
    local dir = KEYMAP[key] if not dir or state.over then return end
    if state.inputLocked or ui.anim.active then state.queuedDir = dir return end
    ApplyMovePlan(dir)
  end)
  f:SetScript("OnShow", function() f:SetFrameStrata("DIALOG") f:SetFrameLevel(100) ApplyPressureVisuals() UpdateUI() end)
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
  PrintMessage("reset | mute | auto | theme [arcane/ember] | motion [full/reduced]")
  PrintMessage("scale [0.75-1.25] | center | demo | test | testclear")
end

SLASH_FLY20481 = "/fly2048"
SlashCmdList["FLY2048"] = function(msg)
  local command, argument = (msg or ""):lower():match("^(%S*)%s*(.-)$")
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
  GameTooltip:AddLine("Left-click to play. Right-click to change theme.", 1, 1, 1, true)
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
    if not THEMES[Fly2048DB.theme] then Fly2048DB.theme = "arcane" end
    if Fly2048DB.motion ~= "reduced" then Fly2048DB.motion = "full" end
    Fly2048DB.uiScale = Clamp(tonumber(Fly2048DB.uiScale) or 1, 0.75, 1.25)
    Fly2048DB.schemaVersion = 2
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
  if not Fly2048DB or Fly2048DB.autopopup ~= true then return end
  if event == "PLAYER_CONTROL_LOST" then After(0.20, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true end end)
  elseif event == "PLAYER_CONTROL_GAINED" then After(0.10, function() if not (UnitOnTaxi and UnitOnTaxi("player")) and state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end)
  elseif event == "PLAYER_ENTERING_WORLD" then AutoPing() After(0.50, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true else if state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end end) end
end)
