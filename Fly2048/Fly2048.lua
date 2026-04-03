-- Fly2048.lua
-- 2048 mini game for WoW Classic (TBC Classic / Anniversary compatible)
-- Slash: /fly2048 (toggle), /fly2048 reset, /fly2048 mute, /fly2048 auto

Fly2048DB = Fly2048DB or {}

local ADDON_NAME = "Fly2048"

-- ==============================
-- Config
-- ==============================
local GRID = 4
local TILE_SIZE = 84
local TILE_PAD = 10
local HEADER_H = 66
local FRAME_PAD = 14

local ANIM_TIME = 0.10
local POP_TIME  = 0.12
local POP_SCALE = 1.12
local SPAWN_POP = 1.10
local SPAWN_TIME = 0.10

local FLASH_TIME = 0.08
local FLASH_ALPHA = 0.35

local SHAKE_DUR = 0.10
local SHAKE_AMP = 3

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

local TEX_DIALOG_BG   = "Interface\\DialogFrame\\UI-DialogBox-Background"
local TEX_DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local TEX_PARCHMENT   = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
local TEX_GLOSS       = "Interface\\Buttons\\UI-ActionButton-Gloss"
local TEX_BORDER_GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
local TEX_STAR        = "Interface\\Cooldown\\star4"

local KEYMAP = {
  ["UP"] = "up", ["DOWN"] = "down", ["LEFT"] = "left", ["RIGHT"] = "right",
  ["W"] = "up", ["S"] = "down", ["A"] = "left", ["D"] = "right",
}

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
}

local ui = {
  frame = nil, boardWrap = nil, board = nil,
  scoreText = nil, bestText = nil, statusText = nil,
  gameOverOverlay = nil, announceBtn = nil, curseBtn = nil,
  resetBtn = nil, boardGlow = nil, boardGlowA = 0,
  pressureTex = nil, pressureA = 0,
  shake = { active = false, t = 0 },
  anim = { active = false, t = 0, movers = {}, pops = {}, spawns = {}, popActive = false, popT = 0, spawnActive = false, spawnT = 0 },
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

local function HSVtoRGB(h, s, v)
  h = h % 1
  local i = math.floor(h * 6)
  local f = (h * 6) - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then return v, t, p 
  elseif i == 1 then return q, v, p 
  elseif i == 2 then return p, v, t 
  elseif i == 3 then return p, q, v 
  elseif i == 4 then return t, p, v end
  return v, p, q
end

local function TileColor(v)
  if v == 0 then return 0.10, 0.10, 0.10, 0.75 end
  local t = Clamp(Log2(v) / 12, 0, 1)
  local h = Lerp(0.56, 0.10, t) + math.sin(t * 3.14159) * 0.06
  local r, g, b = HSVtoRGB(h, Lerp(0.92, 0.72, t), Clamp(Lerp(0.42, 0.98, t), 0, 1))
  if t > 0.70 then r, g, b = Clamp(r * 1.04 + 0.02, 0, 1), Clamp(g * 1.01, 0, 1), Clamp(b * 0.98, 0, 1) end
  return r, g, b, 0.95
end

local function GetFontForValue(v)
  local fLarge, fMid = _G.GameFontNormalLarge or _G.GameFontHighlightLarge or _G.GameFontNormal, _G.GameFontNormal or _G.GameFontHighlight
  local fSmall = _G.GameFontNormalSmall or _G.GameFontHighlightSmall or fMid
  if v >= 16384 then return fSmall elseif v >= 1024 then return fMid end
  return fLarge
end

local function ApplyPressureVisuals()
  if not ui.pressureTex then return end
  ui.pressureA = Clamp(((1 - (#GetEmptyCells() / (GRID * GRID))) - 0.40) / 0.60, 0, 1) * 0.35
  ui.pressureTex:SetColorTexture(0.85, 0.10, 0.10, ui.pressureA)
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
  ui.boardGlow:SetColorTexture(1, 1, 1, ui.boardGlowA)
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

local function TriggerShake() if ui.boardWrap then ui.shake.active, ui.shake.t = true, 0 end end

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
  local fo = GetFontForValue(tile.value)
  if fo then tile.text:SetFontObject(fo) end
  local font, size = tile.text:GetFont()
  if font then tile.text:SetFont(font, size or 18, "OUTLINE") end
  tile.text:SetText(tostring(tile.value))
  tile.text:SetTextColor(0.96, 0.96, 0.96, 1)
  tile.text:SetShadowColor(0, 0, 0, 0.65)
  tile.text:SetShadowOffset(1.5, -1.5)
end

local function PlaceTileFrame(tile, r, c)
  local x, y = CellXY(r, c)
  tile.frame:ClearAllPoints()
  tile.frame:SetPoint("TOPLEFT", ui.board, "TOPLEFT", x, y)
end

local function TriggerFlash(tile) if tile then tile.flashA = FLASH_ALPHA tile.flash:SetColorTexture(1, 1, 1, tile.flashA) end end
local function TriggerSpark(tile) if tile then tile.spark:Show() tile.sparkAG:Stop() tile.sparkAG:Play() end end

local function CreateTile(r, c, value, isSpawn)
  local id = state.nextId
  state.nextId = state.nextId + 1
  local f = CreateFrame("Frame", nil, ui.board) f:SetSize(TILE_SIZE, TILE_SIZE)
  local bg = f:CreateTexture(nil, "BACKGROUND") bg:SetAllPoints(f)
  local shadow = f:CreateTexture(nil, "BORDER") shadow:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2) shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2) shadow:SetColorTexture(0, 0, 0, 0.18)
  local gloss = f:CreateTexture(nil, "ARTWORK") gloss:SetTexture(TEX_GLOSS) gloss:SetBlendMode("ADD") gloss:SetPoint("TOPLEFT", f, "TOPLEFT", -6, 6) gloss:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 6, -6) gloss:SetAlpha(0.20)
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
    SendChatMessage(msg, "GUILD") 
  else 
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Fly2048: Not in a guild.") end 
    if ChatFrame_OpenChat then ChatFrame_OpenChat(msg) end 
  end
end

local function PutCurseLinkInChat() if ChatFrame_OpenChat then ChatFrame_OpenChat("Fly2048 addon: " .. CURSE_URL) end end

local function UpdateUI()
  if not ui.frame then return end
  ui.scoreText:SetText(("Score: %d"):format(state.score))
  ui.bestText:SetText(("Best: %d"):format(state.best))
  local mute, auto = (Fly2048DB and Fly2048DB.mute) and "Muted" or "Sound on", (Fly2048DB and Fly2048DB.autopopup) and "Auto on" or "Auto off"
  if state.over then ui.statusText:SetText("Game Over. R restart. (" .. mute .. ")") ui.gameOverOverlay:Show() else ui.statusText:SetText("WASD/Arrows. R restart. (" .. mute .. ")") ui.gameOverOverlay:Hide() end
  if ui.resetBtn then if state.over or state.divineUsed then ui.resetBtn:Disable() else ui.resetBtn:Enable() end end
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
  state.tiles, state.nextId, state.score, state.over, state.inputLocked, state.queuedDir, state.divineUsed, state.milestonesHit, state.lastChordIndex = {}, 1, 0, false, false, nil, false, {}, 0
  state.best = tonumber(Fly2048DB.best) or 0
  state.runStartBest, state.newBestThisRun = state.best, false
  ClearGrid()
  ui.anim.active, ui.anim.t, ui.anim.movers, ui.anim.pops, ui.anim.spawns, ui.anim.popActive, ui.anim.spawnActive, ui.shake.active, ui.boardGlowA, ui.pressureA = false, 0, {}, {}, {}, false, false, false, 0, 0
  if ui.boardGlow then ui.boardGlow:SetColorTexture(1, 1, 1, 0) end
  if ui.pressureTex then ui.pressureTex:SetColorTexture(0.85, 0.10, 0.10, 0) end
  SpawnRandomTile() SpawnRandomTile() ApplyPressureVisuals() UpdateUI()
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
    state.score = state.score + scoreGain
    if state.score > state.best then state.best, Fly2048DB.best, state.newBestThisRun = state.score, state.score, true end
  end
  SpawnRandomTile() ApplyPressureVisuals()
  if not HasMoves() then state.over = true if state.newBestThisRun then PlaySFX(LEVELUP_SFX) else PlaySFX(GAMEOVER_SFX) end end
  UpdateUI() state.inputLocked = false
end

local function BuildUI()
  if ui.frame then return end
  local w, h = FRAME_PAD*2 + (GRID*TILE_SIZE) + ((GRID-1)*TILE_PAD), FRAME_PAD*2 + HEADER_H + (GRID*TILE_SIZE) + ((GRID-1)*TILE_PAD)
  local f = CreateFrame("Frame", "Fly2048Frame", UIParent, "BackdropTemplate")
  ui.frame = f f:SetSize(w, h) f:SetPoint("CENTER") f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton") f:SetScript("OnDragStart", f.StartMoving) f:SetScript("OnDragStop", f.StopMovingOrSizing) f:SetClampedToScreen(true)
  f:SetBackdrop({ bgFile = TEX_DIALOG_BG, edgeFile = TEX_DIALOG_EDGE, tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
  f:SetBackdropColor(1, 1, 1, 0.95)
  local dark = f:CreateTexture(nil, "BACKGROUND") dark:SetAllPoints(f) dark:SetColorTexture(0, 0, 0, 0.25)
  f:EnableKeyboard(true) f:SetPropagateKeyboardInput(false)
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") title:SetPoint("TOPLEFT", FRAME_PAD, -FRAME_PAD) title:SetText("Fly2048")
  CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -2, -2)
  ui.scoreText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight") ui.scoreText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  ui.bestText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight") ui.bestText:SetPoint("LEFT", ui.scoreText, "RIGHT", 18, 0)
  ui.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontDisable") ui.statusText:SetPoint("TOPLEFT", ui.scoreText, "BOTTOMLEFT", 0, -8)
  ui.resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate") ui.resetBtn:SetSize(120, 22) ui.resetBtn:SetPoint("TOPRIGHT", -34, -38) ui.resetBtn:SetText("Divine Reset") ui.resetBtn:SetScript("OnClick", function() DoDivineReset() UpdateUI() end)
  ui.boardWrap = CreateFrame("Frame", nil, f) ui.boardWrap:SetPoint("TOPLEFT", FRAME_PAD, -(FRAME_PAD + HEADER_H)) ui.boardWrap:SetSize((GRID*TILE_SIZE)+((GRID-1)*TILE_PAD), (GRID*TILE_SIZE)+((GRID-1)*TILE_PAD))
  ui.board = CreateFrame("Frame", nil, ui.boardWrap, "BackdropTemplate") ui.board:SetAllPoints() ui.board:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" }) ui.board:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
  local p = ui.board:CreateTexture(nil, "BACKGROUND") p:SetTexture(TEX_PARCHMENT) p:SetAllPoints() p:SetAlpha(0.18)
  ui.pressureTex = ui.board:CreateTexture(nil, "OVERLAY") ui.pressureTex:SetAllPoints() ui.pressureTex:SetBlendMode("ADD") ui.pressureTex:SetColorTexture(0.85, 0.10, 0.10, 0)
  ui.boardGlow = ui.board:CreateTexture(nil, "OVERLAY") ui.boardGlow:SetAllPoints() ui.boardGlow:SetBlendMode("ADD") ui.boardGlow:SetColorTexture(1, 1, 1, 0)
  for r = 1, GRID do for c = 1, GRID do local cell = CreateFrame("Frame", nil, ui.board) cell:SetSize(TILE_SIZE, TILE_SIZE) local x, y = CellXY(r, c) cell:SetPoint("TOPLEFT", x, y) cell:CreateTexture(nil, "BACKGROUND"):SetAllPoints() cell:GetRegions():SetColorTexture(0.10, 0.11, 0.12, 0.62) end end
  
  -- Game Over Overlay (Modified for Dull Effect and Brag Button)
  ui.gameOverOverlay = CreateFrame("Frame", nil, ui.board, "BackdropTemplate") ui.gameOverOverlay:SetAllPoints() ui.gameOverOverlay:SetFrameStrata("DIALOG") ui.gameOverOverlay:SetFrameLevel(ui.board:GetFrameLevel() + 10) ui.gameOverOverlay:Hide()
  ui.gameOverOverlay:CreateTexture(nil, "BACKGROUND"):SetAllPoints() ui.gameOverOverlay:GetRegions():SetColorTexture(0, 0, 0, 0.82) -- Darker alpha for dulling
  local panel = CreateFrame("Frame", nil, ui.gameOverOverlay, "BackdropTemplate") panel:SetPoint("CENTER") panel:SetSize(280, 170) panel:SetBackdrop({ bgFile = TEX_DIALOG_BG, edgeFile = TEX_DIALOG_EDGE, tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
  local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") hdr:SetPoint("TOP", 0, -16) hdr:SetText("Game Over")
  local scoreLine = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight") scoreLine:SetPoint("TOP", hdr, "BOTTOM", 0, -20)
  ui.gameOverOverlay:SetScript("OnShow", function() scoreLine:SetText(("Final score: %d"):format(state.score or 0)) end)
  ui.announceBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate") ui.announceBtn:SetSize(220, 22) ui.announceBtn:SetPoint("BOTTOM", 0, 50) ui.announceBtn:SetText("Brag to Guild") ui.announceBtn:SetScript("OnClick", AnnounceScoreToGuild)
  ui.curseBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate") ui.curseBtn:SetSize(220, 22) ui.curseBtn:SetPoint("BOTTOM", 0, 22) ui.curseBtn:SetText("Curse Page Link") ui.curseBtn:SetScript("OnClick", PutCurseLinkInChat)
  
  f:SetScript("OnKeyDown", function(self, key)
    if (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() and ChatEdit_GetActiveWindow():IsShown()) or (GetCurrentKeyBoardFocus() and GetCurrentKeyBoardFocus() ~= f) then return end
    if key == "ESCAPE" then f:Hide() return elseif key == "R" then ResetGame() return end
    local dir = KEYMAP[key] if not dir or state.over then return end
    if state.inputLocked or ui.anim.active then state.queuedDir = dir return end
    ApplyMovePlan(dir)
  end)
  f:SetScript("OnShow", function() f:SetFrameStrata("DIALOG") f:SetFrameLevel(100) ApplyPressureVisuals() UpdateUI() end)
  f:SetScript("OnUpdate", function(_, elapsed)
    ApplyShake(elapsed) MaybeHeartbeat(elapsed)
    if ui.boardGlowA > 0 then ui.boardGlowA = math.max(0, ui.boardGlowA - elapsed * 1.6) ui.boardGlow:SetColorTexture(1, 1, 1, ui.boardGlowA) end
    for _, t in pairs(state.tiles) do if t.flashA > 0 then t.flashA = math.max(0, t.flashA - (elapsed / FLASH_TIME) * FLASH_ALPHA) t.flash:SetColorTexture(1, 1, 1, t.flashA) end end
    if ui.anim.active then
      ui.anim.t = ui.anim.t + elapsed
      local t = math.min(1, ui.anim.t / ANIM_TIME)
      for _, mover in ipairs(ui.anim.movers) do if mover.frame and mover.ex then mover.frame:SetPoint("TOPLEFT", ui.board, "TOPLEFT", Lerp(mover.sx, mover.ex, EaseOutCubic(t)), Lerp(mover.sy, mover.ey, EaseOutCubic(t))) end end
      if t >= 1 then ui.anim.active, ui.anim.t = false, 0 CommitMove() if #ui.anim.pops > 0 then ui.anim.popActive, ui.anim.popT = true, 0 end if #ui.anim.spawns > 0 then ui.anim.spawnActive, ui.anim.spawnT = true, 0 end end
    end
    if ui.anim.popActive then
      ui.anim.popT = ui.anim.popT + elapsed
      local t = math.min(1, ui.anim.popT / POP_TIME)
      local s = t < 0.5 and Lerp(1, POP_SCALE, t/0.5) or Lerp(POP_SCALE, 1, (t-0.5)/0.5)
      for _, tObj in ipairs(ui.anim.pops) do if tObj.frame then tObj.frame:SetScale(s) end end
      if t >= 1 then ui.anim.popActive, ui.anim.popT, ui.anim.pops = false, 0, {} end
    end
    if ui.anim.spawnActive then
      ui.anim.spawnT = ui.anim.spawnT + elapsed
      local t = math.min(1, ui.anim.spawnT / SPAWN_TIME)
      for _, tObj in ipairs(ui.anim.spawns) do if tObj.frame then tObj.frame:SetScale(Lerp(0.98, SPAWN_POP, EaseOutCubic(t))) end end
      if t >= 1 then for _, tObj in ipairs(ui.anim.spawns) do if tObj.frame then tObj.frame:SetScale(1) end end ui.anim.spawnActive, ui.anim.spawnT, ui.anim.spawns = false, 0, {} end
    end
    if not state.over and not state.inputLocked and not ui.anim.active and state.queuedDir then local d = state.queuedDir state.queuedDir = nil ApplyMovePlan(d) end
  end)
  f:Hide()
end

local function Toggle() BuildUI() if ui.frame:IsShown() then ui.frame:Hide() state.autoShown = false else if not next(state.tiles) then ResetGame() end ui.frame:Show() end end

SLASH_FLY20481 = "/fly2048"
SlashCmdList["FLY2048"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "reset" or msg == "r" then BuildUI() ResetGame() ui.frame:Show() state.autoShown = false return
  elseif msg == "mute" then Fly2048DB.mute = not Fly2048DB.mute UpdateUI() return
  elseif msg == "auto" then Fly2048DB.autopopup = (Fly2048DB.autopopup ~= true) UpdateUI() return end
  Toggle()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" and name == ADDON_NAME then
    Fly2048DB.best, Fly2048DB.mute, Fly2048DB.autopopup = tonumber(Fly2048DB.best) or 0, (Fly2048DB.mute == true), (Fly2048DB.autopopup ~= false)
    state.best = Fly2048DB.best
    BuildUI()
    self:RegisterEvent("PLAYER_CONTROL_LOST") self:RegisterEvent("PLAYER_CONTROL_GAINED") self:RegisterEvent("PLAYER_ENTERING_WORLD")
    return
  end
  if not Fly2048DB or Fly2048DB.autopopup ~= true then return end
  if event == "PLAYER_CONTROL_LOST" then After(0.20, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true end end)
  elseif event == "PLAYER_CONTROL_GAINED" then After(0.10, function() if not (UnitOnTaxi and UnitOnTaxi("player")) and state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end)
  elseif event == "PLAYER_ENTERING_WORLD" then After(0.50, function() if UnitOnTaxi and UnitOnTaxi("player") then if not ui.frame:IsShown() then if not next(state.tiles) then ResetGame() end ui.frame:Show() end state.autoShown = true else if state.autoShown then if ui.frame then ui.frame:Hide() end state.autoShown = false end end end) end
end)