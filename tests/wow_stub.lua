-- Minimal, deliberately strict WoW UI stub for Fly2048 smoke tests.
-- Unknown widget methods remain nil so the test fails on accidental API use.

local frames = {}
local timers = {}
local Methods = {}
local Object = { __index = Methods }

local function NewObject(kind)
  return setmetatable({ kind = kind, shown = true, enabled = true, scripts = {}, events = {}, frameLevel = 1 }, Object)
end

local function Noop() end

function Methods:SetSize() end
function Methods:SetAllPoints() end
function Methods:SetParent(parent) self.parent = parent end
function Methods:SetScale(scale) self.scale = scale end
function Methods:Show() self.shown = true if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Methods:Hide() self.shown = false end
function Methods:IsShown() return self.shown end
function Methods:ClearAllPoints() self.point = nil end
function Methods:SetBackdrop() end
function Methods:SetBackdropColor() end
function Methods:SetBackdropBorderColor() end
function Methods:SetColorTexture() end
function Methods:SetTexture() end
function Methods:SetBlendMode() end
function Methods:SetAlpha() end
function Methods:SetWidth() end
function Methods:SetHeight() end
function Methods:SetMovable() end
function Methods:EnableMouse() end
function Methods:RegisterForDrag() end
function Methods:SetClampedToScreen() end
function Methods:EnableKeyboard() end
function Methods:SetPropagateKeyboardInput() end
function Methods:SetFrameStrata() end
function Methods:SetFrameLevel(level) self.frameLevel = level end
function Methods:GetFrameLevel() return self.frameLevel end
function Methods:SetText(text) self.text = text end
function Methods:SetTextColor() end
function Methods:SetShadowColor() end
function Methods:SetShadowOffset() end
function Methods:SetFontObject() end
function Methods:SetFont() end
function Methods:GetFont() return nil end
function Methods:SetJustifyH() end
function Methods:SetOwner() end
function Methods:AddLine() end
function Methods:StartMoving() end
function Methods:StopMovingOrSizing() end
function Methods:Disable() self.enabled = false if self.scripts.OnDisable then self.scripts.OnDisable(self) end end
function Methods:Enable() self.enabled = true if self.scripts.OnEnable then self.scripts.OnEnable(self) end end
function Methods:IsEnabled() return self.enabled end
function Methods:SetDuration() end
function Methods:SetOrder() end
function Methods:SetFromAlpha() end
function Methods:SetToAlpha() end
function Methods:SetScaleFrom() end
function Methods:SetScaleTo() end
function Methods:Play() end
function Methods:Stop() end

function Methods:SetPoint(point, relativeTo, relativePoint, x, y)
  self.point = { point or "CENTER", relativeTo, relativePoint or point or "CENTER", x or 0, y or 0 }
end

function Methods:GetPoint()
  local p = self.point or { "CENTER", UIParent, "CENTER", 0, 0 }
  return p[1], p[2], p[3], p[4], p[5]
end

function Methods:SetScript(name, callback) self.scripts[name] = callback end
function Methods:RegisterEvent(name) self.events[name] = true end
function Methods:UnregisterEvent(name) self.events[name] = nil end
function Methods:CreateTexture() return NewObject("Texture") end
function Methods:CreateFontString() return NewObject("FontString") end
function Methods:CreateAnimationGroup() return NewObject("AnimationGroup") end
function Methods:CreateAnimation() return NewObject("Animation") end

function Methods:Trigger(name, ...)
  if self.scripts[name] then return self.scripts[name](self, ...) end
end

UIParent = NewObject("UIParent")
GameTooltip = NewObject("GameTooltip")
GameFontNormalLarge = NewObject("Font")
GameFontHighlightLarge = GameFontNormalLarge
GameFontNormal = NewObject("Font")
GameFontHighlight = GameFontNormal
GameFontNormalSmall = NewObject("Font")
GameFontHighlightSmall = GameFontNormalSmall

function CreateFrame(kind, name, parent, template)
  local frame = NewObject(kind)
  frame.name, frame.parent, frame.template = name, parent, template
  frames[#frames + 1] = frame
  if name then _G[name] = frame end
  return frame
end

function Fly2048_TestTriggerEvent(event, ...)
  local count = #frames
  for i = 1, count do
    local frame = frames[i]
    if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
  end
end

function Fly2048_TestRunUpdates(iterations, elapsed)
  for _ = 1, iterations do
    local count = #frames
    for i = 1, count do
      local frame = frames[i]
      if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, elapsed) end
    end
  end
end

function Fly2048_TestRunTimers(limit)
  local runs = 0
  while #timers > 0 and runs < limit do
    runs = runs + 1
    local callback = table.remove(timers, 1)
    callback()
  end
end

C_Timer = {
  After = function(_, callback) timers[#timers + 1] = callback end,
  NewTicker = function() return { Cancel = Noop } end,
}

C_ChatInfo = {
  RegisterAddonMessagePrefix = function() return true end,
  SendAddonMessage = Noop,
  SendChatMessage = Noop,
  AreOutgoingAddonChatMessagesRestricted = function() return false end,
}

DEFAULT_CHAT_FRAME = { AddMessage = Noop }
SlashCmdList = {}
function PlaySoundFile() end
function IsInGuild() return true end
function UnitName() return "TestPilot", "TestRealm" end
function GetRealmName() return "TestRealm" end
function GetNormalizedRealmName() return "TestRealm" end
function Ambiguate(name) return name end
function UnitOnTaxi() return false end
function ChatFrame_OpenChat() end
