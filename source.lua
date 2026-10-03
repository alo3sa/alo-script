local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
if getgenv then
local env = getgenv()
if env.__HUB_UNLOAD then pcall(env.__HUB_UNLOAD) end
end
local S = {
Aimbot = false,
HoldToAim = true,
Speed = 30,
TargetPart = "Head",
Priority = "Crosshair",
Sticky = true,
UseFOV = true,
ShowFOV = true,
FOV = 200,
WallCheck = false,
TeamCheck = false,
WalkSpeedOn = false,
SpeedMode = "CFrame",
WalkSpeed = 50,
Targets = {},
ESPPlayers = false,
ESPNPCs = false,
ESPIslands = false,
ESPDist = 1500,
ESPMax = 40,
ESPHighlight = false,
NPCNames = {},
TPEnabled = true,
TPKey = Enum.KeyCode.T,
WaterWalk = false,
InfJump = false,
Noclip = false,
NoclipKey = Enum.KeyCode.N,
PvpHitbox = false,
PvpHitboxSize = 15,
PvpHitboxAll = false,
}
local alive = true
local conns = {}
local function track(c) table.insert(conns, c) return c end
local inject = {t = 0}
local npcCache = {}
local function scanNPCs()
local found, seen, roots = {}, {}, {}
for _, n in ipairs({"Enemies", "NPCs"}) do
local f = Workspace:FindFirstChild(n)
if f then table.insert(roots, f) end
end
if #roots == 0 then roots[1] = Workspace end
for _, root in ipairs(roots) do
for _, d in ipairs(root:GetDescendants()) do
if d:IsA("Humanoid") then
local m = d.Parent
if m and m:IsA("Model") and not seen[m] and m ~= LP.Character
and not Players:GetPlayerFromCharacter(m) then
seen[m] = true
found[#found + 1] = m
end
end
end
end
npcCache = found
end
local function needNPC()
return S.ESPNPCs or next(S.NPCNames) ~= nil
end
local C = {
bg = Color3.fromRGB(18, 18, 26),
title = Color3.fromRGB(26, 26, 38),
panel = Color3.fromRGB(32, 32, 46),
item = Color3.fromRGB(40, 40, 58),
accent = Color3.fromRGB(90, 120, 255),
off = Color3.fromRGB(70, 70, 90),
text = Color3.fromRGB(235, 235, 245),
sub = Color3.fromRGB(160, 160, 180),
}
local function new(class, props, parent)
local o = Instance.new(class)
for k, v in pairs(props or {}) do o[k] = v end
if parent then o.Parent = parent end
return o
end
local function corner(o, r)
new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o)
end
local function label(parent, text, size, pos, props)
local p = {
Text = text, Size = size, Position = pos or UDim2.new(),
BackgroundTransparency = 1, TextColor3 = C.text,
Font = Enum.Font.Gotham, TextSize = 14,
TextXAlignment = Enum.TextXAlignment.Left,
}
for k, v in pairs(props or {}) do p[k] = v end
return new("TextLabel", p, parent)
end
local function getParent()
local ok, ui = pcall(function() return gethui and gethui() end)
if ok and ui then return ui end
ok, ui = pcall(function() return game:GetService("CoreGui") end)
if ok and ui then return ui end
return LP:WaitForChild("PlayerGui")
end
local gui = new("ScreenGui", {
Name = "BloodlinesUI", ResetOnSpawn = false, IgnoreGuiInset = true,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local espFolder = new("Folder", {Name = "BloodlinesESP"})
do
local parent = getParent()
local ok = pcall(function() gui.Parent = parent; espFolder.Parent = parent end)
if not ok then
gui.Parent = LP:WaitForChild("PlayerGui")
espFolder.Parent = LP:WaitForChild("PlayerGui")
end
end
local normalSize = UDim2.fromOffset(540, 350)
local normalPos = UDim2.new(0.5, -270, 0.5, -175)
local state = {minimized = false, full = false}
local main = new("Frame", {
Name = "Main", Size = normalSize, Position = normalPos,
BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
corner(main, 10)
local titleBar = new("Frame", {
Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.title, BorderSizePixel = 0,
}, main)
label(titleBar, "  BLOODLINES  |  PVP, ESP & TELEPORT", UDim2.new(1, -120, 1, 0), nil,
{Font = Enum.Font.GothamBold, TextSize = 15})
local function winButton(text, offset, color)
local b = new("TextButton", {
Text = text, Size = UDim2.fromOffset(30, 24),
Position = UDim2.new(1, offset, 0.5, -12),
BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1),
Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = true,
}, titleBar)
corner(b, 6)
return b
end
local btnClose = winButton("X", -36, Color3.fromRGB(200, 60, 70))
local btnMax = winButton("▢", -70, C.item)
local btnMin = winButton("-", -104, C.item)
local body = new("Frame", {
Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(0, 0, 0, 34),
BackgroundTransparency = 1,
}, main)
local tabBar = new("Frame", {
Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = C.title, BorderSizePixel = 0,
}, body)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, tabBar)
local content = new("Frame", {
Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 110, 0, 0),
BackgroundTransparency = 1,
}, body)
local function applyLayout()
local size = state.full and UDim2.new(1, 0, 1, 0) or normalSize
if state.minimized then
body.Visible = false
main.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 34)
else
body.Visible = true
main.Size = size
end
main.Position = state.full and UDim2.new(0, 0, 0, 0) or normalPos
end
btnMin.MouseButton1Click:Connect(function()
state.minimized = not state.minimized
applyLayout()
end)
btnMax.MouseButton1Click:Connect(function()
state.full = not state.full
state.minimized = false
applyLayout()
end)
do
local dragging, startInput, startPos
titleBar.InputBegan:Connect(function(input)
if state.full then return end
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
startInput = input.Position
startPos = main.Position
end
end)
track(UIS.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch) then
local d = input.Position - startInput
normalPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
startPos.Y.Scale, startPos.Y.Offset + d.Y)
main.Position = normalPos
end
end))
track(UIS.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = false
end
end))
end
local hubBtn = new("TextButton", {
Name = "HubButton", Text = "BL", Size = UDim2.fromOffset(52, 52),
Position = UDim2.new(1, -66, 0.5, -26), BackgroundColor3 = C.accent,
TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15,
ZIndex = 10,
}, gui)
corner(hubBtn, 26)
hubBtn.MouseButton1Click:Connect(function()
if main.Visible and not state.minimized then
main.Visible = false
else
main.Visible = true
state.minimized = false
applyLayout()
end
end)
local function makeSwitch(parent, init, cb)
local on = init and true or false
local btn = new("TextButton", {
Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(40, 20),
Position = UDim2.new(1, -48, 0.5, -10),
BackgroundColor3 = on and C.accent or C.off,
}, parent)
corner(btn, 10)
local knob = new("Frame", {
Size = UDim2.fromOffset(16, 16),
Position = on and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
BackgroundColor3 = Color3.new(1, 1, 1),
}, btn)
corner(knob, 8)
local function set(v, silent)
on = v
TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = v and C.accent or C.off}):Play()
TweenService:Create(knob, TweenInfo.new(0.15), {Position = v and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)}):Play()
if not silent then cb(v) end
end
btn.MouseButton1Click:Connect(function() set(not on) end)
return {Set = set}
end
local function makeToggle(parent, text, init, cb)
local row = new("Frame", {Size = UDim2.new(1, -8, 0, 36), BackgroundColor3 = C.panel}, parent)
corner(row, 8)
label(row, "  " .. text, UDim2.new(1, -60, 1, 0))
return makeSwitch(row, init, cb)
end
local function makeSlider(parent, text, min, max, default, cb)
local row = new("Frame", {Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = C.panel}, parent)
corner(row, 8)
local lbl = label(row, "  " .. text .. ": " .. default, UDim2.new(1, 0, 0, 26))
local bar = new("Frame", {
Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 34),
BackgroundColor3 = C.off,
}, row)
corner(bar, 4)
local a0 = (default - min) / (max - min)
local fill = new("Frame", {Size = UDim2.new(a0, 0, 1, 0), BackgroundColor3 = C.accent}, bar)
corner(fill, 4)
local hit = new("TextButton", {
Text = "", BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 26),
}, row)
local dragging = false
local function setFrom(x)
local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
local v = math.floor(min + (max - min) * a + 0.5)
fill.Size = UDim2.new(a, 0, 1, 0)
lbl.Text = "  " .. text .. ": " .. v
cb(v)
end
hit.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
setFrom(input.Position.X)
end
end)
track(UIS.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch) then
setFrom(input.Position.X)
end
end))
track(UIS.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = false
end
end))
end
local function makeButton(parent, text, cb)
local b = new("TextButton", {
Text = text, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = C.item,
TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 14,
}, parent)
corner(b, 8)
b.MouseButton1Click:Connect(cb)
return b
end
local function makeCycle(parent, text, options, default, cb)
local idx = table.find(options, default) or 1
local b = new("TextButton", {
Text = text .. ": " .. options[idx] .. "  ›", Size = UDim2.new(1, -8, 0, 36),
BackgroundColor3 = C.panel, TextColor3 = C.text,
Font = Enum.Font.Gotham, TextSize = 14,
}, parent)
corner(b, 8)
b.MouseButton1Click:Connect(function()
idx = idx % #options + 1
b.Text = text .. ": " .. options[idx] .. "  ›"
cb(options[idx])
end)
return {
Set = function(v)
local i = table.find(options, v)
if i then
idx = i
b.Text = text .. ": " .. v .. "  ›"
cb(v)
end
end,
}
end
local function header(parent, text)
return label(parent, text, UDim2.new(1, -8, 0, 20), nil,
{Font = Enum.Font.GothamBold, TextColor3 = C.sub, TextSize = 12})
end
local pages, tabButtons = {}, {}
local function selectTab(name)
for n, p in pairs(pages) do
p.Visible = (n == name)
tabButtons[n].BackgroundColor3 = (n == name) and C.accent or C.panel
end
end
local function newPage(name, order)
local page = new("ScrollingFrame", {
Size = UDim2.new(1, -12, 1, -12), Position = UDim2.new(0, 6, 0, 6),
BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
Visible = false,
}, content)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, page)
pages[name] = page
local tb = new("TextButton", {
Text = name, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.panel,
TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 13, LayoutOrder = order,
}, tabBar)
corner(tb, 8)
tabButtons[name] = tb
tb.MouseButton1Click:Connect(function() selectTab(name) end)
return page
end
local pvpPage = newPage("PVP", 1)
local plrPage = newPage("Players", 2)
local visPage = newPage("ESP", 3)
local tpPage = newPage("Teleport", 4)
local miscPage = newPage("Misc", 5)
local perfPage = newPage("Performance", 6)
local devPage = newPage("Remote Log", 7)
header(pvpPage, "AIMBOT")
makeToggle(pvpPage, "Aimbot", false, function(v) S.Aimbot = v end)
makeToggle(pvpPage, "Hold right-click to aim", true, function(v) S.HoldToAim = v end)
makeSlider(pvpPage, "Aim speed", 1, 100, S.Speed, function(v) S.Speed = v end)
local fovCircle = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(S.FOV * 2, S.FOV * 2), BackgroundTransparency = 1,
Visible = false, ZIndex = 5,
}, gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
new("UIStroke", {Color = C.accent, Thickness = 1.5}, fovCircle)
header(pvpPage, "AIM SELECTION")
makeCycle(pvpPage, "Aim at", {"Head", "Torso", "Root", "Closest"}, S.TargetPart, function(v) S.TargetPart = v end)
makeCycle(pvpPage, "Priority", {"Crosshair", "Distance", "Lowest HP"}, S.Priority, function(v) S.Priority = v end)
makeToggle(pvpPage, "Sticky lock (stay on target)", S.Sticky, function(v) S.Sticky = v end)
makeToggle(pvpPage, "Use FOV limit", S.UseFOV, function(v) S.UseFOV = v end)
makeToggle(pvpPage, "Show FOV circle", S.ShowFOV, function(v) S.ShowFOV = v end)
makeSlider(pvpPage, "FOV size", 50, 600, S.FOV, function(v)
S.FOV = v
fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
makeToggle(pvpPage, "Wall check", S.WallCheck, function(v) S.WallCheck = v end)
makeToggle(pvpPage, "Skip teammates", S.TeamCheck, function(v) S.TeamCheck = v end)
header(pvpPage, "TARGETS")
local pvpCount = label(pvpPage, "  Selected: 0", UDim2.new(1, -8, 0, 22), nil, {TextColor3 = C.sub, TextSize = 13})
makeButton(pvpPage, "Pick players to aim at  ›", function() selectTab("Players") end)
header(pvpPage, "HITBOX")
local pvpHb = setmetatable({}, {__mode = "k"})
local function pvpSet(plr, on)
local ch = plr.Character
local r = ch and ch:FindFirstChild("HumanoidRootPart")
if not r then return end
if on then
if not pvpHb[r] then pvpHb[r] = {r.Size, r.Transparency, r.CanCollide} end
local s = S.PvpHitboxSize
if r.Size.X ~= s then r.Size = Vector3.new(s, s, s) end
r.Transparency = 0.8
r.CanCollide = false
else
local o = pvpHb[r]
if o then
r.Size, r.Transparency, r.CanCollide = o[1], o[2], o[3]
pvpHb[r] = nil
end
end
end
local function pvpRestoreAll()
for r, o in pairs(pvpHb) do
pcall(function() r.Size, r.Transparency, r.CanCollide = o[1], o[2], o[3] end)
pvpHb[r] = nil
end
end
makeToggle(pvpPage, "Bigger hitbox (PVP)", false, function(v)
S.PvpHitbox = v
if not v then pvpRestoreAll() end
end)
makeSlider(pvpPage, "Hitbox size", 2, 60, S.PvpHitboxSize, function(v) S.PvpHitboxSize = v end)
makeToggle(pvpPage, "Apply to everyone (not just picked)", false, function(v) S.PvpHitboxAll = v end)
task.spawn(function()
while alive do
task.wait(0.2)
if S.PvpHitbox then
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP then pcall(pvpSet, p, S.PvpHitboxAll or S.Targets[p] == true) end
end
end
end
end)
header(plrPage, "PLAYERS IN YOUR SERVER - TAP TO PICK")
local plrCount = label(plrPage, "  Selected: 0 / 0", UDim2.new(1, -8, 0, 22), nil, {TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 13})
local search = new("TextBox", {
Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = C.panel, TextColor3 = C.text,
PlaceholderText = "Search player...", PlaceholderColor3 = C.sub, Text = "",
Font = Enum.Font.Gotham, TextSize = 14, ClearTextOnFocus = false,
}, plrPage)
corner(search, 8)
local btnRow = new("Frame", {Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1}, plrPage)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, btnRow)
local function rowButton(text, cb)
local b = new("TextButton", {
Text = text, Size = UDim2.new(0.333, -4, 1, 0), BackgroundColor3 = C.item,
TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 13,
}, btnRow)
corner(b, 8)
b.MouseButton1Click:Connect(cb)
end
local list = new("Frame", {
Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
}, plrPage)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name}, list)
local rows = {}
local SEL_COLOR = Color3.fromRGB(55, 75, 150)
local function updateCount()
local sel, total = 0, 0
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP then
total += 1
if S.Targets[p] then sel += 1 end
end
end
plrCount.Text = "  Selected: " .. sel .. " / " .. total
local npcSel = 0
for _ in pairs(S.NPCNames) do npcSel += 1 end
pvpCount.Text = "  Players: " .. sel .. "  |  NPC types: " .. npcSel
end
local function applyFilter()
local q = search.Text:lower()
for p, r in pairs(rows) do
r.Visible = q == "" or p.Name:lower():find(q, 1, true) ~= nil
or p.DisplayName:lower():find(q, 1, true) ~= nil
end
end
local function refreshPlayers()
for _, r in pairs(rows) do r:Destroy() end
rows = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP then
local row = new("TextButton", {
Name = p.Name:lower(), Text = "", AutoButtonColor = false,
Size = UDim2.new(1, 0, 0, 38),
BackgroundColor3 = S.Targets[p] and SEL_COLOR or C.item,
}, list)
corner(row, 8)
label(row, "  " .. p.DisplayName .. "  (@" .. p.Name .. ")", UDim2.new(1, -60, 1, 0), nil,
{TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd})
local sw = makeSwitch(row, S.Targets[p] == true, function(v)
S.Targets[p] = v or nil
row.BackgroundColor3 = v and SEL_COLOR or C.item
updateCount()
end)
row.MouseButton1Click:Connect(function() sw.Set(not S.Targets[p]) end)
rows[p] = row
end
end
applyFilter()
updateCount()
end
rowButton("Select all", function()
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then S.Targets[p] = true end end
refreshPlayers()
end)
rowButton("Clear", function()
S.Targets = {}
refreshPlayers()
end)
rowButton("Refresh", refreshPlayers)
search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
track(Players.PlayerAdded:Connect(function() task.delay(0.2, refreshPlayers) end))
track(Players.PlayerRemoving:Connect(function(p)
S.Targets[p] = nil
task.delay(0.2, refreshPlayers)
end))
refreshPlayers()
header(plrPage, "NPCs - PICK WHICH ONES THE AIMBOT TARGETS")
local npcCount = label(plrPage, "  Selected NPC types: 0", UDim2.new(1, -8, 0, 22), nil,
{TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 13})
local npcBtnRow = new("Frame", {Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1}, plrPage)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, npcBtnRow)
local npcList = new("Frame", {
Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
}, plrPage)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name}, npcList)
local npcRows = {}
local function refreshNPCs(skipScan)
if not skipScan then scanNPCs() end
for _, r in pairs(npcRows) do r:Destroy() end
npcRows = {}
local counts = {}
for _, m in ipairs(npcCache) do counts[m.Name] = (counts[m.Name] or 0) + 1 end
for name in pairs(S.NPCNames) do counts[name] = counts[name] or 0 end
for name, n in pairs(counts) do
local row = new("TextButton", {
Name = name, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36),
BackgroundColor3 = S.NPCNames[name] and SEL_COLOR or C.item,
}, npcList)
corner(row, 8)
label(row, "  " .. name .. "   (x" .. n .. ")", UDim2.new(1, -60, 1, 0), nil,
{TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd})
local sw = makeSwitch(row, S.NPCNames[name] == true, function(v)
S.NPCNames[name] = v or nil
row.BackgroundColor3 = v and SEL_COLOR or C.item
local c = 0
for _ in pairs(S.NPCNames) do c += 1 end
npcCount.Text = "  Selected NPC types: " .. c
updateCount()
end)
row.MouseButton1Click:Connect(function() sw.Set(not S.NPCNames[name]) end)
npcRows[name] = row
end
local c = 0
for _ in pairs(S.NPCNames) do c += 1 end
npcCount.Text = "  Selected NPC types: " .. c
updateCount()
end
local function npcBtn(text, cb)
local b = new("TextButton", {
Text = text, Size = UDim2.new(0.333, -4, 1, 0), BackgroundColor3 = C.item,
TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 13,
}, npcBtnRow)
corner(b, 8)
b.MouseButton1Click:Connect(cb)
end
npcBtn("Scan NPCs", function() refreshNPCs() end)
npcBtn("Select all", function()
for name in pairs(npcRows) do S.NPCNames[name] = true end
refreshNPCs(true)
end)
npcBtn("Clear", function()
S.NPCNames = {}
refreshNPCs(true)
end)
task.defer(refreshNPCs)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function isBlocked(part, ch)
rayParams.FilterDescendantsInstances = {LP.Character, ch}
local origin = Camera.CFrame.Position
return Workspace:Raycast(origin, part.Position - origin, rayParams) ~= nil
end
local function screenDist(part, center)
local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
if not onScreen then return nil end
return (Vector2.new(pos.X, pos.Y) - center).Magnitude
end
local function pickPart(ch, center)
local head = ch:FindFirstChild("Head")
local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
local root = ch:FindFirstChild("HumanoidRootPart")
local mode = S.TargetPart
if mode == "Head" then return head or root or torso end
if mode == "Torso" then return torso or root or head end
if mode == "Root" then return root or torso or head end
local best, bestD
for _, p in pairs({head, torso, root}) do
local d = p and screenDist(p, center)
if d and (not bestD or d < bestD) then best, bestD = p, d end
end
return best
end
local function evaluate(ch, center)
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then return nil end
local plr = Players:GetPlayerFromCharacter(ch)
if plr and S.TeamCheck and LP.Team and plr.Team == LP.Team then return nil end
local part = pickPart(ch, center) or ch.PrimaryPart
if not part then return nil end
local sd = screenDist(part, center)
if not sd then return nil end
if S.UseFOV and sd > S.FOV then return nil end
if S.WallCheck and isBlocked(part, ch) then return nil end
return {
model = ch, part = part, sd = sd, hp = hum.Health,
dist = (Camera.CFrame.Position - part.Position).Magnitude,
}
end
local function isSelected(m)
local plr = Players:GetPlayerFromCharacter(m)
if plr then return S.Targets[plr] == true end
return S.NPCNames[m.Name] == true
end
local locked = nil
local function getTarget()
local vp = Camera.ViewportSize
local center = Vector2.new(vp.X / 2, vp.Y / 2)
if S.Sticky and locked and locked.Parent and isSelected(locked) then
local e = evaluate(locked, center)
if e then return e end
end
locked = nil
local best
local function consider(ch)
local e = evaluate(ch, center)
if e then
if S.Priority == "Distance" then e.key = e.dist
elseif S.Priority == "Lowest HP" then e.key = e.hp
else e.key = e.sd end
if not best or e.key < best.key then best = e end
end
end
for plr in pairs(S.Targets) do
if plr.Character then consider(plr.Character) end
end
if next(S.NPCNames) ~= nil then
for _, m in ipairs(npcCache) do
if m.Parent and S.NPCNames[m.Name] then consider(m) end
end
end
if best then locked = best.model end
return best
end
track(RunService.RenderStepped:Connect(function()
Camera = Workspace.CurrentCamera
fovCircle.Visible = S.Aimbot and S.UseFOV and S.ShowFOV
if not S.Aimbot then locked = nil return end
if S.HoldToAim and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
locked = nil
return
end
local t = getTarget()
if not t then return end
local alpha = math.clamp(S.Speed / 100, 0.01, 1)
local cf = Camera.CFrame
Camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, t.part.Position), alpha)
end))
local espObjs = {}
local islandObjs = {}
local function removeESP(model)
local o = espObjs[model]
if o then
pcall(function() if o.hl then o.hl:Destroy() end end)
pcall(function() o.gui:Destroy() end)
espObjs[model] = nil
end
end
local function addESP(model, kind, part)
local color = kind == "player" and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(255, 170, 40)
local bb = new("BillboardGui", {
Adornee = part, Size = UDim2.fromOffset(150, 34), StudsOffset = Vector3.new(0, 3, 0),
AlwaysOnTop = true, ResetOnSpawn = false,
}, espFolder)
local txt = new("TextLabel", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = color,
TextStrokeTransparency = 0.3, Font = Enum.Font.GothamBold, TextSize = 12, Text = model.Name,
}, bb)
local o = {gui = bb, txt = txt, kind = kind, part = part, color = color}
espObjs[model] = o
return o
end
local function setOutline(model, o, on)
if on and not o.hl then
o.hl = new("Highlight", {
Adornee = model, FillColor = o.color, OutlineColor = Color3.new(1, 1, 1),
FillTransparency = 0.6, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
}, espFolder)
elseif not on and o.hl then
o.hl:Destroy()
o.hl = nil
end
end
local function espRootPart(m)
return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
end
local function updateESP()
local ch = LP.Character
local myRoot = ch and ch:FindFirstChild("HumanoidRootPart")
local origin = myRoot and myRoot.Position or Camera.CFrame.Position
local list = {}
local function consider(m, kind)
if m and m.Parent then
local part = espRootPart(m)
if part then
local d = (part.Position - origin).Magnitude
if d <= S.ESPDist then
list[#list + 1] = {m = m, kind = kind, part = part, dist = d}
end
end
end
end
if S.ESPPlayers then
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP then consider(p.Character, "player") end
end
end
if S.ESPNPCs then
for _, m in ipairs(npcCache) do consider(m, "npc") end
end
table.sort(list, function(a, b) return a.dist < b.dist end)
local wanted = {}
for i = 1, math.min(#list, S.ESPMax) do
local e = list[i]
wanted[e.m] = true
local o = espObjs[e.m]
if not o or o.kind ~= e.kind or o.part ~= e.part then
removeESP(e.m)
o = addESP(e.m, e.kind, e.part)
end
setOutline(e.m, o, S.ESPHighlight and i <= 15)
local hum = e.m:FindFirstChildOfClass("Humanoid")
local text = (e.kind == "npc" and "[NPC] " or "") .. e.m.Name .. "\n"
.. math.floor(e.dist) .. "m | " .. (hum and math.floor(hum.Health) or 0) .. " HP"
if o.last ~= text then
o.last = text
o.txt.Text = text
end
end
for m in pairs(espObjs) do
if not wanted[m] then removeESP(m) end
end
end
local islandList = {}
local function refreshIslandList()
local out = {}
local function add(inst)
local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
if part then out[#out + 1] = {name = inst.Name, part = part} end
end
local wo = Workspace:FindFirstChild("_WorldOrigin")
local loc = wo and wo:FindFirstChild("Locations")
if loc then
for _, c in ipairs(loc:GetChildren()) do add(c) end
else
local map = Workspace:FindFirstChild("Map")
if map then
for _, c in ipairs(map:GetChildren()) do
if c:IsA("Model") or c:IsA("Folder") then add(c) end
end
end
end
islandList = out
end
local function clearIslands()
for part, o in pairs(islandObjs) do
pcall(function() o.gui:Destroy() end)
islandObjs[part] = nil
end
end
local function updateIslands()
local ch = LP.Character
local myRoot = ch and ch:FindFirstChild("HumanoidRootPart")
local origin = myRoot and myRoot.Position or Camera.CFrame.Position
local seen = {}
for _, isl in ipairs(islandList) do
local part = isl.part
if part.Parent then
seen[part] = true
local o = islandObjs[part]
if not o then
local bb = new("BillboardGui", {
Adornee = part, Size = UDim2.fromOffset(180, 36),
AlwaysOnTop = true, ResetOnSpawn = false,
}, espFolder)
local txt = new("TextLabel", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
TextColor3 = Color3.fromRGB(90, 200, 255), TextStrokeTransparency = 0.3,
Font = Enum.Font.GothamBold, TextSize = 13,
}, bb)
o = {gui = bb, txt = txt}
islandObjs[part] = o
end
local text = isl.name .. "\n" .. math.floor((part.Position - origin).Magnitude) .. "m"
if o.last ~= text then
o.last = text
o.txt.Text = text
end
end
end
for part, o in pairs(islandObjs) do
if not seen[part] then
pcall(function() o.gui:Destroy() end)
islandObjs[part] = nil
end
end
end
local function cleanupESP()
for m in pairs(espObjs) do removeESP(m) end
clearIslands()
end
header(visPage, "ESP")
makeToggle(visPage, "ESP Players", false, function(v) S.ESPPlayers = v; pcall(updateESP) end)
makeToggle(visPage, "ESP NPCs", false, function(v)
S.ESPNPCs = v
if v then pcall(scanNPCs) end
pcall(updateESP)
end)
makeToggle(visPage, "ESP Islands", false, function(v)
S.ESPIslands = v
if v then
pcall(refreshIslandList)
pcall(updateIslands)
else
clearIslands()
end
end)
header(visPage, "ESP PERFORMANCE (less lag)")
makeSlider(visPage, "Max distance", 100, 5000, S.ESPDist, function(v) S.ESPDist = v end)
makeSlider(visPage, "Max drawn at once", 5, 100, S.ESPMax, function(v) S.ESPMax = v end)
makeToggle(visPage, "Outline (a bit heavier)", false, function(v) S.ESPHighlight = v end)
task.spawn(function()
local t = 0
while alive do
task.wait(0.5)
t += 1
if t % 6 == 0 and needNPC() then pcall(scanNPCs) end
if t % 10 == 0 and S.ESPIslands then pcall(refreshIslandList) end
if S.ESPPlayers or S.ESPNPCs or next(espObjs) ~= nil then pcall(updateESP) end
if S.ESPIslands then pcall(updateIslands) end
end
end)
header(miscPage, "MOVEMENT")
local noclipT = makeToggle(miscPage, "Noclip", false, function(v) S.Noclip = v end)
local binding = nil
local noclipKeyBtn
local function noclipKeyText() return "Noclip key: " .. S.NoclipKey.Name .. "   (click to change)" end
noclipKeyBtn = makeButton(miscPage, noclipKeyText(), function()
binding = "noclip"
noclipKeyBtn.Text = "Press a key...  (Esc = cancel)"
end)
local origWS
local function getHum()
return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end
local function hookHumanoid(h)
if not h then return end
track(h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
if S.WalkSpeedOn and S.SpeedMode == "WalkSpeed" and h.WalkSpeed ~= S.WalkSpeed then
h.WalkSpeed = S.WalkSpeed
end
end))
end
hookHumanoid(getHum())
track(LP.CharacterAdded:Connect(function(ch)
hookHumanoid(ch:WaitForChild("Humanoid", 10))
end))
local function restoreWalkSpeed()
local h = getHum()
if h and origWS then h.WalkSpeed = origWS end
origWS = nil
end
makeToggle(miscPage, "Speed", false, function(v)
S.WalkSpeedOn = v
if v then
local h = getHum()
if S.SpeedMode == "WalkSpeed" then origWS = origWS or (h and h.WalkSpeed) or 16 end
else
restoreWalkSpeed()
end
end)
makeCycle(miscPage, "Speed mode", {"CFrame", "WalkSpeed"}, S.SpeedMode, function(v)
S.SpeedMode = v
if v == "CFrame" then
restoreWalkSpeed()
elseif S.WalkSpeedOn then
local h = getHum()
origWS = origWS or (h and h.WalkSpeed) or 16
end
end)
makeSlider(miscPage, "Speed", 16, 400, S.WalkSpeed, function(v) S.WalkSpeed = v end)
local function applySpeed(dt)
if not S.WalkSpeedOn then return end
local ch = LP.Character
local h = getHum()
if not (ch and h) then return end
if S.SpeedMode == "WalkSpeed" then
if h.WalkSpeed ~= S.WalkSpeed then h.WalkSpeed = S.WalkSpeed end
else
local root = ch:FindFirstChild("HumanoidRootPart")
local dir = h.MoveDirection
if root and dir.Magnitude > 0 then
local extra = math.max(S.WalkSpeed - h.WalkSpeed, 0)
root.CFrame = root.CFrame + dir.Unit * extra * dt
end
end
end
track(RunService.Heartbeat:Connect(applySpeed))
track(RunService.Stepped:Connect(function(_, dt)
if S.WalkSpeedOn and S.SpeedMode == "WalkSpeed" then applySpeed(dt) end
end))
track(RunService.Stepped:Connect(function()
if S.Noclip and LP.Character then
for _, p in ipairs(LP.Character:GetDescendants()) do
if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
end
end
end))
header(miscPage, "TELEPORT")
makeToggle(miscPage, "Teleport to mouse (press key)", S.TPEnabled, function(v) S.TPEnabled = v end)
local tpKeyBtn
local function keyText() return "TP key: " .. S.TPKey.Name .. "   (click to change)" end
tpKeyBtn = makeButton(miscPage, keyText(), function()
binding = "tp"
tpKeyBtn.Text = "Press a key...  (Esc = cancel)"
end)
local tpParams = RaycastParams.new()
tpParams.FilterType = Enum.RaycastFilterType.Exclude
tpParams.IgnoreWater = false
local function teleportToMouse()
local ch = LP.Character
local root = ch and ch:FindFirstChild("HumanoidRootPart")
if not root then return end
Camera = Workspace.CurrentCamera
local loc = UIS:GetMouseLocation()
local ray = Camera:ViewportPointToRay(loc.X, loc.Y)
tpParams.FilterDescendantsInstances = {ch}
local res = Workspace:Raycast(ray.Origin, ray.Direction * 5000, tpParams)
if not res then return end
local cf = ch:GetPivot()
ch:PivotTo(CFrame.new(res.Position + Vector3.new(0, 4, 0)) * (cf - cf.Position))
root.AssemblyLinearVelocity = Vector3.zero
end
track(UIS.InputBegan:Connect(function(input)
if binding then
if input.UserInputType == Enum.UserInputType.Keyboard then
local which = binding
binding = nil
if input.KeyCode ~= Enum.KeyCode.Escape then
if which == "tp" then S.TPKey = input.KeyCode else S.NoclipKey = input.KeyCode end
end
tpKeyBtn.Text = keyText()
noclipKeyBtn.Text = noclipKeyText()
end
return
end
if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
if UIS:GetFocusedTextBox() or os.clock() < inject.t then return end
if input.KeyCode == S.NoclipKey then
noclipT.Set(not S.Noclip)
end
if S.TPEnabled and input.KeyCode == S.TPKey then
local ok, err = pcall(teleportToMouse)
if not ok then warn("[Hub] teleport error: " .. tostring(err)) end
end
end))
header(miscPage, "WATER")
local Terrain = Workspace.Terrain
local waterY, waterPad, padActive
local rayWater = RaycastParams.new()
rayWater.FilterType = Enum.RaycastFilterType.Exclude
rayWater.IgnoreWater = false
local rayLand = RaycastParams.new()
rayLand.FilterType = Enum.RaycastFilterType.Exclude
local function ensurePad()
if not waterPad or not waterPad.Parent then
waterPad = new("Part", {
Size = Vector3.new(24, 1, 24), Anchored = true, CanCollide = true,
Transparency = 1, CanTouch = false, CanQuery = false, Locked = true,
})
waterPad.Name = "WaterPad"
waterPad.Parent = Workspace
end
end
local function scanWater(root, hum)
local ch = LP.Character
rayWater.FilterDescendantsInstances = {ch, waterPad}
rayLand.FilterDescendantsInstances = {ch, waterPad}
local res = Workspace:Raycast(root.Position + Vector3.new(0, 8, 0), Vector3.new(0, -150, 0), rayWater)
if res and res.Material == Enum.Material.Water then
waterY = res.Position.Y
elseif hum and hum:GetState() == Enum.HumanoidStateType.Swimming then
waterY = root.Position.Y + 1.5
elseif not waterY then
local map = Workspace:FindFirstChild("Map")
local plane = map and map:FindFirstChild("WaterBase-Plane")
if plane then waterY = plane.Position.Y + plane.Size.Y / 2 end
end
if not waterY then padActive = false return end
local y = root.Position.Y
if y < waterY - 6 or y > waterY + 14 then padActive = false return end
local g = Workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayLand)
padActive = not (g and g.Position.Y > waterY - 1.5)
end
local waterTick = 0
track(RunService.Heartbeat:Connect(function(dt)
if not S.WaterWalk then return end
local ch = LP.Character
local root = ch and ch:FindFirstChild("HumanoidRootPart")
if not root then return end
waterTick += dt
if waterTick >= 0.12 then
waterTick = 0
pcall(scanWater, root, getHum())
end
if padActive and waterY then
ensurePad()
waterPad.CFrame = CFrame.new(root.Position.X, waterY - 0.5, root.Position.Z)
if root.Position.Y < waterY + 2 then
root.CFrame = root.CFrame + Vector3.new(0, waterY + 3 - root.Position.Y, 0)
end
elseif waterPad then
waterPad.CFrame = CFrame.new(0, -5000, 0)
end
end))
makeToggle(miscPage, "Walk on water", false, function(v)
S.WaterWalk = v
if not v then
padActive = false
if waterPad then waterPad.CFrame = CFrame.new(0, -5000, 0) end
end
end)
label(miscPage, "  Tip: if it doesn't start, swim in the water once", UDim2.new(1, -8, 0, 20), nil,
{TextColor3 = C.sub, TextSize = 12})
local function cleanupWater()
S.WaterWalk = false
pcall(function() if waterPad then waterPad:Destroy() end end)
end
header(miscPage, "JUMP")
makeToggle(miscPage, "Infinite jump", false, function(v) S.InfJump = v end)
track(UIS.JumpRequest:Connect(function()
if S.InfJump then
local h = getHum()
if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end))
local BLRepl = game:GetService("ReplicatedStorage")
local blEvents = BLRepl:FindFirstChild("Events")
local dataEvent = blEvents and blEvents:FindFirstChild("DataEvent")
local dataFunction = blEvents and blEvents:FindFirstChild("DataFunction")
S.BLMobs, S.BLNPCs, S.BLItems, S.BLChakra, S.BLAreas = false, false, false, false, false
S.BLPickup, S.BLPickupRange = false, 50
S.BLFly, S.BLFlySpeed = false, 80
S.LogRemotes, S.LogAll, S.LogFilter = false, false, ""
local function blRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function blPartOf(inst)
if not inst then return nil end
if inst:IsA("BasePart") then return inst end
if inst:IsA("Model") then
return inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChild("Main")
or inst:FindFirstChildWhichIsA("BasePart", true)
end
return inst:FindFirstChildWhichIsA("BasePart", true)
end
local bl = {mobs = {}, npcs = {}, items = {}}
local function blScan()
local mobs, npcs, items = {}, {}, {}
for _, o in ipairs(Workspace:GetChildren()) do
if o:IsA("Model") then
local nv = o:FindFirstChild("NPC")
if nv and nv:IsA("ValueBase") then
local ok, val = pcall(function() return nv.Value end)
if ok and val == "Combat" then mobs[#mobs + 1] = o
elseif ok and val == "Dialog" then npcs[#npcs + 1] = o end
end
elseif o:IsA("BasePart") then
if o:FindFirstChild("Pickupable") and o:FindFirstChild("ID") then items[#items + 1] = o end
end
end
bl.mobs, bl.npcs, bl.items = mobs, npcs, items
end
blScan()
local BL_COLORS = {
mob = Color3.fromRGB(255, 120, 60), npc = Color3.fromRGB(120, 255, 120),
item = Color3.fromRGB(255, 230, 80), chakra = Color3.fromRGB(90, 200, 255),
area = Color3.fromRGB(200, 150, 255),
}
local blObjs = {}
local function blRemoveESP(key)
local o = blObjs[key]
if o then
pcall(function() o.gui:Destroy() end)
blObjs[key] = nil
end
end
local function blAddESP(key, part, kind)
local bb = new("BillboardGui", {
Adornee = part, Size = UDim2.fromOffset(150, 34), StudsOffset = Vector3.new(0, 2.5, 0),
AlwaysOnTop = true, ResetOnSpawn = false,
}, espFolder)
local txt = new("TextLabel", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = BL_COLORS[kind],
TextStrokeTransparency = 0.3, Font = Enum.Font.GothamBold, TextSize = 12,
}, bb)
local o = {gui = bb, txt = txt, part = part}
blObjs[key] = o
return o
end
local function blUpdateESP()
local root = blRoot()
local origin = root and root.Position or Camera.CFrame.Position
local cands = {}
local function consider(key, part, name, kind, limited)
if part and part.Parent then
local d = (part.Position - origin).Magnitude
if not limited or d <= S.ESPDist then
cands[#cands + 1] = {key = key, part = part, name = name, kind = kind, dist = d, limited = limited}
end
end
end
if S.BLMobs then
for _, m in ipairs(bl.mobs) do consider(m, blPartOf(m), m.Name, "mob", true) end
end
if S.BLNPCs then
for _, m in ipairs(bl.npcs) do consider(m, blPartOf(m), m.Name, "npc", true) end
end
if S.BLItems then
for _, it in ipairs(bl.items) do consider(it, it, it.Name, "item", true) end
end
if S.BLChakra then
local f = Workspace:FindFirstChild("ChakraPoints")
if f then
for _, c in ipairs(f:GetChildren()) do
local pn = c:FindFirstChild("PointName")
local nm = c.Name
if pn and pn:IsA("ValueBase") then nm = tostring(pn.Value) end
consider(c, c:FindFirstChild("Main") or blPartOf(c), nm, "chakra", false)
end
end
end
if S.BLAreas then
local f = Workspace:FindFirstChild("Locations")
if f then
for _, c in ipairs(f:GetChildren()) do consider(c, blPartOf(c), c.Name, "area", false) end
end
end
table.sort(cands, function(a, b) return a.dist < b.dist end)
local wanted, count = {}, 0
for _, c in ipairs(cands) do
if c.limited then count += 1 end
if not c.limited or count <= S.ESPMax then
wanted[c.key] = true
local o = blObjs[c.key]
if not o or o.part ~= c.part then
blRemoveESP(c.key)
o = blAddESP(c.key, c.part, c.kind)
end
local text = c.name .. "\n" .. math.floor(c.dist) .. "m"
if c.kind == "mob" then
local h = c.key:FindFirstChildOfClass("Humanoid")
if h then text = text .. " | " .. math.floor(h.Health) .. " HP" end
end
if o.last ~= text then
o.last = text
o.txt.Text = text
end
end
end
for k in pairs(blObjs) do
if not wanted[k] then blRemoveESP(k) end
end
end
header(visPage, "BLOODLINES ESP")
makeToggle(visPage, "Mobs", false, function(v) S.BLMobs = v; pcall(blUpdateESP) end)
makeToggle(visPage, "NPCs (dialog)", false, function(v) S.BLNPCs = v; pcall(blUpdateESP) end)
makeToggle(visPage, "Items / crates / fruit (pickups)", false, function(v) S.BLItems = v; pcall(blUpdateESP) end)
makeToggle(visPage, "Chakra points", false, function(v) S.BLChakra = v; pcall(blUpdateESP) end)
makeToggle(visPage, "Areas", false, function(v) S.BLAreas = v; pcall(blUpdateESP) end)
task.spawn(function()
local t = 0
while alive do
task.wait(0.5)
t += 1
if t % 3 == 0 then pcall(blScan) end
if S.BLMobs or S.BLNPCs or S.BLItems or S.BLChakra or S.BLAreas or next(blObjs) ~= nil then
pcall(blUpdateESP)
end
end
end)
local function blGoto(pos)
local ch = LP.Character
local root = blRoot()
if not (ch and root) then return end
ch:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 4)))
root.AssemblyLinearVelocity = Vector3.zero
end
header(tpPage, "TELEPORT (tap a name)")
local tpBtnRow = new("Frame", {Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1}, tpPage)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, tpBtnRow)
local tpList = new("Frame", {
Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
}, tpPage)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name}, tpList)
local tpRows = {}
local function tpHeader(sortName, text)
local h = label(tpList, text, UDim2.new(1, 0, 0, 22), nil,
{Font = Enum.Font.GothamBold, TextColor3 = C.sub, TextSize = 12})
h.Name = sortName
tpRows[#tpRows + 1] = h
end
local function tpRow(sortName, text, cb)
local b = new("TextButton", {
Name = sortName, Text = "  " .. text, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.item,
TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, tpList)
corner(b, 8)
b.MouseButton1Click:Connect(cb)
tpRows[#tpRows + 1] = b
end
local function buildTPList()
for _, r in pairs(tpRows) do r:Destroy() end
tpRows = {}
pcall(blScan)
tpHeader("1", "  PLAYERS")
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP then
tpRow("2" .. p.Name:lower(), p.DisplayName .. "  (@" .. p.Name .. ")", function()
local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
if r then blGoto(r.Position) end
end)
end
end
tpHeader("3", "  NPCs")
for _, npc in ipairs(bl.npcs) do
tpRow("4" .. npc.Name:lower(), npc.Name, function()
local pt = blPartOf(npc)
if pt then blGoto(pt.Position) end
end)
end
tpHeader("5", "  CHAKRA POINTS")
local cf = Workspace:FindFirstChild("ChakraPoints")
if cf then
for _, c in ipairs(cf:GetChildren()) do
local pn = c:FindFirstChild("PointName")
local nm = (pn and pn:IsA("ValueBase")) and tostring(pn.Value) or c.Name
tpRow("6" .. nm:lower(), nm, function()
local pt = c:FindFirstChild("Main") or blPartOf(c)
if pt then blGoto(pt.Position) end
end)
end
end
tpHeader("7", "  AREAS")
local lf = Workspace:FindFirstChild("Locations")
if lf then
for _, a in ipairs(lf:GetChildren()) do
tpRow("8" .. a.Name:lower(), a.Name, function()
local pt = blPartOf(a)
if pt then blGoto(pt.Position) end
end)
end
end
end
local function nearestOf(list, getPart)
local root = blRoot()
if not root then return nil end
local best, bd
for _, o in ipairs(list) do
local pt = o.Parent and getPart(o)
if pt then
local d = (pt.Position - root.Position).Magnitude
if not bd or d < bd then best, bd = pt, d end
end
end
return best
end
local function tpBtn(text, cb)
local b = new("TextButton", {
Text = text, Size = UDim2.new(0.333, -4, 1, 0), BackgroundColor3 = C.item,
TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12,
}, tpBtnRow)
corner(b, 8)
b.MouseButton1Click:Connect(cb)
end
tpBtn("Refresh lists", buildTPList)
tpBtn("Nearest item", function()
pcall(blScan)
local pt = nearestOf(bl.items, function(o) return o end)
if pt then blGoto(pt.Position) end
end)
tpBtn("Nearest mob", function()
pcall(blScan)
local pt = nearestOf(bl.mobs, blPartOf)
if pt then blGoto(pt.Position) end
end)
track(Players.PlayerAdded:Connect(function() task.delay(0.5, buildTPList) end))
track(Players.PlayerRemoving:Connect(function() task.delay(0.5, buildTPList) end))
task.defer(buildTPList)
header(miscPage, "BLOODLINES")
makeToggle(miscPage, "Auto pickup (items near you)", false, function(v) S.BLPickup = v end)
makeSlider(miscPage, "Pickup range", 10, 150, S.BLPickupRange, function(v) S.BLPickupRange = v end)
local lastPick = setmetatable({}, {__mode = "k"})
task.spawn(function()
while alive do
task.wait(0.15)
if S.BLPickup and dataEvent then
local root = blRoot()
if root then
for _, it in ipairs(bl.items) do
if it.Parent and (it.Position - root.Position).Magnitude <= S.BLPickupRange then
local last = lastPick[it]
if not last or os.clock() - last > 1 then
lastPick[it] = os.clock()
local id = it:FindFirstChild("ID")
if id then pcall(function() dataEvent:FireServer("PickUp", id.Value) end) end
end
end
end
end
end
end
end)
local flyBV
local function flyStop()
if flyBV then
pcall(function() flyBV:Destroy() end)
flyBV = nil
end
end
makeToggle(miscPage, "Fly (WASD + Space / Shift)", false, function(v)
S.BLFly = v
if not v then flyStop() end
end)
makeSlider(miscPage, "Fly speed", 10, 400, S.BLFlySpeed, function(v) S.BLFlySpeed = v end)
track(RunService.Stepped:Connect(function()
if not S.BLFly then return end
local root = blRoot()
if not root then return end
if not flyBV or flyBV.Parent ~= root then
flyStop()
flyBV = Instance.new("BodyVelocity")
flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
flyBV.Velocity = Vector3.zero
flyBV.Parent = root
end
local cf = Workspace.CurrentCamera.CFrame
local v = Vector3.zero
local any = false
if UIS:IsKeyDown(Enum.KeyCode.W) then v += cf.LookVector any = true end
if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cf.LookVector any = true end
if UIS:IsKeyDown(Enum.KeyCode.D) then v += cf.RightVector any = true end
if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cf.RightVector any = true end
if not any then
local h = getHum()
if h and h.MoveDirection.Magnitude > 0 then v = h.MoveDirection end
end
if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0, 1, 0) end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
v -= Vector3.new(0, 1, 0)
end
flyBV.Velocity = v.Magnitude > 0 and v.Unit * S.BLFlySpeed or Vector3.zero
end))
local logLines, logDirty, logHooked, oldNC = {}, false, false, nil
local function fmt(v, depth)
depth = depth or 0
local t = typeof(v)
if t == "string" then
return string.format("%q", #v > 60 and v:sub(1, 60) .. "..." or v)
elseif t == "number" or t == "boolean" or t == "nil" then
return tostring(v)
elseif t == "Instance" then
return "<" .. v.ClassName .. " " .. v.Name .. ">"
elseif t == "table" then
if depth >= 2 then return "{...}" end
local parts, n = {}, 0
for k, val in pairs(v) do
n += 1
if n > 6 then parts[#parts + 1] = "..." break end
parts[#parts + 1] = "[" .. fmt(k, depth + 1) .. "]=" .. fmt(val, depth + 1)
end
return "{" .. table.concat(parts, ", ") .. "}"
end
return tostring(v)
end
local function record(remote, method, args)
if not S.LogAll and remote ~= dataEvent and remote ~= dataFunction then return end
local parts = {}
for i = 1, args.n do parts[i] = fmt(args[i]) end
local line = string.format("%s:%s(%s)", remote.Name, method, table.concat(parts, ", "))
local f = S.LogFilter
if f ~= "" and not line:lower():find(f, 1, true) then return end
local last = logLines[#logLines]
if last and last.text == line then
last.n += 1
else
logLines[#logLines + 1] = {text = line, n = 1}
if #logLines > 300 then table.remove(logLines, 1) end
end
logDirty = true
end
local logStatus
local function installLogHook()
if logHooked then return end
if not (hookmetamethod and getnamecallmethod) then
logStatus.Text = "  Your executor has no hookmetamethod - logging isn't available here"
return
end
logHooked = true
local wrap = newcclosure or function(f) return f end
local isA = game.IsA
oldNC = hookmetamethod(game, "__namecall", wrap(function(self, ...)
local method = getnamecallmethod()
if S.LogRemotes and alive and (method == "FireServer" or method == "InvokeServer")
and not (checkcaller and checkcaller()) then
pcall(function()
if typeof(self) == "Instance" and (isA(self, "RemoteEvent") or isA(self, "RemoteFunction")) then
record(self, method, table.pack(...))
end
end)
end
if setnamecallmethod then setnamecallmethod(method) end
return oldNC(self, ...)
end))
end
header(devPage, "REMOTE LOG")
label(devPage, "  Turn on, do the action in game (parry, mission...), then copy the log.", UDim2.new(1, -8, 0, 34), nil,
{TextColor3 = C.sub, TextSize = 12, TextWrapped = true})
makeToggle(devPage, "Log remote calls", false, function(v)
S.LogRemotes = v
if v then installLogHook() end
end)
makeCycle(devPage, "Log", {"Data remotes only", "All remotes"}, "Data remotes only", function(v)
S.LogAll = (v == "All remotes")
end)
logStatus = label(devPage, "", UDim2.new(1, -8, 0, 20), nil, {TextColor3 = C.accent, TextSize = 12})
local filterBox = new("TextBox", {
Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = C.panel, TextColor3 = C.text,
PlaceholderText = "Only log lines containing... (optional)", PlaceholderColor3 = C.sub, Text = "",
Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
}, devPage)
corner(filterBox, 8)
filterBox:GetPropertyChangedSignal("Text"):Connect(function() S.LogFilter = filterBox.Text:lower() end)
local function logText()
local out = {}
for _, l in ipairs(logLines) do
out[#out + 1] = l.text .. (l.n > 1 and ("  x" .. l.n) or "")
end
return table.concat(out, "\n")
end
local copyBtn
copyBtn = makeButton(devPage, "Copy log", function()
if setclipboard then
setclipboard(logText())
copyBtn.Text = "Copied!"
else
copyBtn.Text = "Your executor can't copy"
end
task.delay(1.5, function() if copyBtn.Parent then copyBtn.Text = "Copy log" end end)
end)
makeButton(devPage, "Clear log", function()
logLines = {}
logDirty = true
end)
local logLabel = label(devPage, "  (log is empty)", UDim2.new(1, -8, 0, 0), nil,
{TextWrapped = true, TextSize = 12, AutomaticSize = Enum.AutomaticSize.Y, TextYAlignment = Enum.TextYAlignment.Top})
task.spawn(function()
while alive do
task.wait(0.5)
if logDirty then
logDirty = false
local out = {}
for i = math.max(1, #logLines - 24), #logLines do
local l = logLines[i]
out[#out + 1] = l.text .. (l.n > 1 and ("  x" .. l.n) or "")
end
logLabel.Text = #out > 0 and table.concat(out, "\n") or "  (log is empty)"
end
end
end)
local function blCleanup()
S.BLFly, S.LogRemotes, S.BLPickup = false, false, false
S.BLMobs, S.BLNPCs, S.BLItems, S.BLChakra, S.BLAreas = false, false, false, false, false
flyStop()
for k in pairs(blObjs) do blRemoveESP(k) end
end
local Lighting = game:GetService("Lighting")
local perf = {boost = false, vfx = "Normal", noTex = false, render3d = true}
local saved = nil
local partOrig = setmetatable({}, {__mode = "k"})
local texOrig = setmetatable({}, {__mode = "k"})
local vfxOrig = setmetatable({}, {__mode = "k"})
local VFX = {ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true}
local function applyPart(inst)
if inst:IsA("BasePart") and not inst:IsA("Terrain") then
if perf.boost then
if inst.Material == Enum.Material.Water then return end
if not partOrig[inst] then
partOrig[inst] = {inst.Material, inst.CastShadow, inst.Reflectance}
end
inst.Material = Enum.Material.SmoothPlastic
inst.CastShadow = false
inst.Reflectance = 0
else
local o = partOrig[inst]
if o then
inst.Material, inst.CastShadow, inst.Reflectance = o[1], o[2], o[3]
partOrig[inst] = nil
end
end
end
end
local function applyVfx(inst)
local cls = inst.ClassName
if not VFX[cls] then return end
local level = perf.vfx
local o = vfxOrig[inst]
if not o then
if level == "Normal" then return end
o = {enabled = inst.Enabled}
if cls == "ParticleEmitter" then
o.rate = inst.Rate
o.life = inst.Lifetime
end
vfxOrig[inst] = o
end
if level == "Normal" then
inst.Enabled = o.enabled
if o.rate then
inst.Rate = o.rate
inst.Lifetime = o.life
end
elseif level == "Reduced" then
inst.Enabled = o.enabled
if cls == "ParticleEmitter" then
inst.Rate = o.rate * 0.3
inst.Lifetime = NumberRange.new(o.life.Min * 0.5, o.life.Max * 0.5)
end
else
inst.Enabled = false
if cls == "ParticleEmitter" then
inst.Rate = 0
inst.Lifetime = NumberRange.new(0, 0)
end
end
end
local function applyTex(inst)
if inst:IsA("Decal") then
if perf.noTex then
if texOrig[inst] == nil then texOrig[inst] = inst.Transparency end
inst.Transparency = 1
elseif texOrig[inst] ~= nil then
inst.Transparency = texOrig[inst]
texOrig[inst] = nil
end
end
end
local function applyInstance(inst)
pcall(function()
applyPart(inst)
applyVfx(inst)
applyTex(inst)
end)
end
local sweeping, sweepAgain = false, false
local function sweep()
if sweeping then sweepAgain = true return end
sweeping = true
task.spawn(function()
repeat
sweepAgain = false
local list = Workspace:GetDescendants()
for i = 1, #list do
applyInstance(list[i])
if i % 400 == 0 then task.wait() end
end
until not sweepAgain
sweeping = false
end)
end
track(Workspace.DescendantAdded:Connect(function(inst)
if perf.boost or perf.vfx ~= "Normal" or perf.noTex then applyInstance(inst) end
end))
local function setBoost(on)
perf.boost = on
if on then
if not saved then
saved = {fx = {}}
pcall(function() saved.quality = settings().Rendering.QualityLevel end)
saved.shadows = Lighting.GlobalShadows
for _, e in ipairs(Lighting:GetChildren()) do
if e:IsA("PostEffect") then
saved.fx[#saved.fx + 1] = {e, "Enabled", e.Enabled}
elseif e:IsA("Atmosphere") then
saved.fx[#saved.fx + 1] = {e, "Density", e.Density}
saved.fx[#saved.fx + 1] = {e, "Haze", e.Haze}
end
end
local clouds = Terrain:FindFirstChildOfClass("Clouds")
if clouds then saved.fx[#saved.fx + 1] = {clouds, "Enabled", clouds.Enabled} end
saved.waveSize, saved.waveSpeed, saved.reflect =
Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance
end
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
Lighting.GlobalShadows = false
for _, f in ipairs(saved.fx) do
pcall(function()
if f[2] == "Enabled" then f[1].Enabled = false else f[1][f[2]] = 0 end
end)
end
pcall(function()
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0
Terrain.WaterReflectance = 0
end)
elseif saved then
pcall(function() settings().Rendering.QualityLevel = saved.quality end)
Lighting.GlobalShadows = saved.shadows
for _, f in ipairs(saved.fx) do pcall(function() f[1][f[2]] = f[3] end) end
pcall(function()
Terrain.WaterWaveSize = saved.waveSize
Terrain.WaterWaveSpeed = saved.waveSpeed
Terrain.WaterReflectance = saved.reflect
end)
saved = nil
end
sweep()
end
local function cleanupPerf()
local was = perf.boost or perf.vfx ~= "Normal" or perf.noTex
perf.vfx, perf.noTex = "Normal", false
if perf.boost then setBoost(false) elseif was then sweep() end
if not perf.render3d then
pcall(function() RunService:Set3dRenderingEnabled(true) end)
perf.render3d = true
end
end
header(perfPage, "FPS")
local fpsLabel = label(perfPage, "  FPS: --", UDim2.new(1, -8, 0, 24), nil,
{Font = Enum.Font.GothamBold, TextColor3 = C.accent})
do
local frames, acc = 0, 0
track(RunService.RenderStepped:Connect(function(dt)
frames += 1
acc += dt
if acc >= 0.5 then
fpsLabel.Text = "  FPS: " .. math.floor(frames / acc + 0.5)
frames, acc = 0, 0
end
end))
end
header(perfPage, "BOOST")
local boostToggle = makeToggle(perfPage, "FPS Booster (low graphics)", false, setBoost)
local vfxCycle = makeCycle(perfPage, "VFX", {"Normal", "Reduced", "Minimal"}, "Normal", function(v)
perf.vfx = v
sweep()
end)
makeToggle(perfPage, "Remove textures / decals", false, function(v)
perf.noTex = v
sweep()
