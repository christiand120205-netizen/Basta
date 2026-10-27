-- Secret Service Protection (MOBILE FIXED: PERMANENTLY CENTERED FOV)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Protection Configuration
local ProtectionSettings = {
    Enabled = false,
    FOV = 120,
    Smoothness = 0.15,
    HardAim = false,
    TargetPart = "Head",
    WallCheck = true,
    ShowFOV = true,
    ShowHealthBars = false,
    StickyTarget = true,
    SwitchMargin = 25,
    IgnoreTeam = true,
}

local GuiOpen = false
local HealthBarStorage = {}

-- Targeting state (persists across frames)
local currentTargetName = nil
local lastTargetTime = 0

-- Every RBXScriptConnection lives here so Unload can kill them all
local Connections = {}
local function track(conn)
    table.insert(Connections, conn)
    return conn
end

----------------------------------------------------------------
-- UI CONSTRUCTION
----------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SecretServiceUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.AnchorPoint = Vector2.new(1, 1)
OpenButton.Size = UDim2.new(0, 110, 0, 44)
OpenButton.Position = UDim2.new(1, -15, 1, -15)
OpenButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Text = "Menu"
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 13
OpenButton.ZIndex = 10
OpenButton.Parent = ScreenGui
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 8)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 300, 0, 460)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Title is a sibling of TitleBar (behind it), NOT a child
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Secret Service"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = false
Title.ZIndex = 3
Title.Parent = MainFrame

-- Transparent full-width button ON TOP of Title - grabs all touches
local TitleBar = Instance.new("TextButton")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.Text = ""
TitleBar.AutoButtonColor = false
TitleBar.Active = true
TitleBar.Selectable = true
TitleBar.ZIndex = 4
TitleBar.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 32, 0, 32)
CloseButton.Position = UDim2.new(1, -38, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.ZIndex = 5
CloseButton.Parent = MainFrame
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -50)
Scroll.Position = UDim2.new(0, 8, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.CanvasSize = UDim2.new(0, 0, 0, 720)
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Scroll

----------------------------------------------------------------
-- MOBILE-COMPATIBLE UI CONTROLS
----------------------------------------------------------------

local function CreateToggle(name, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = Scroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 44, 0, 24)
    Btn.Position = UDim2.new(1, -48, 0.5, -12)
    Btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
    Btn.Text = ""
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 12)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    track(Btn.Activated:Connect(function()
        local newState = Btn.BackgroundColor3 == Color3.fromRGB(60, 60, 60)
        Btn.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
        callback(newState)
    end))
end

local function CreateSlider(name, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 48)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = Scroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 22)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local SliderBack = Instance.new("TextButton")
    SliderBack.Text = ""
    SliderBack.AutoButtonColor = false
    SliderBack.Size = UDim2.new(1, -20, 0, 10)
    SliderBack.Position = UDim2.new(0, 10, 0.65, -3)
    SliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SliderBack.Parent = Frame
    Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)

    local SliderMain = Instance.new("Frame")
    SliderMain.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderMain.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    SliderMain.BorderSizePixel = 0
    SliderMain.Parent = SliderBack
    Instance.new("UICorner", SliderMain).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function applyPosition(xPos)
        local sliderPos = SliderBack.AbsolutePosition.X
        local sliderWidth = SliderBack.AbsoluteSize.X
        if sliderWidth <= 0 then return end
        local pos = math.clamp((xPos - sliderPos) / sliderWidth, 0, 1)
        SliderMain.Size = UDim2.new(pos, 0, 1, 0)
        local value = min + (max - min) * pos
        if max > 1 then value = math.floor(value) else value = math.floor(value * 100) / 100 end
        Label.Text = name .. ": " .. value
        callback(value)
    end

    track(SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyPosition(input.Position.X)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            applyPosition(input.Position.X)
        end
    end))
end

local function CreateButton(name, color, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = Scroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -12, 0, 26)
    Btn.Position = UDim2.new(0, 6, 0.5, -13)
    Btn.BackgroundColor3 = color
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    track(Btn.Activated:Connect(callback))
end

local function CreateCycler(name, options, defaultIndex, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = Scroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -120, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 100, 0, 26)
    Btn.Position = UDim2.new(1, -106, 0.5, -13)
    Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Text = options[defaultIndex]
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local idx = defaultIndex
    track(Btn.Activated:Connect(function()
        idx = idx % #options + 1
        Btn.Text = options[idx]
        callback(options[idx])
    end))
end

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -6, 0, 30)
InfoLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
InfoLabel.Text = "Target: None"
InfoLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 13
InfoLabel.Parent = Scroll
Instance.new("UICorner", InfoLabel)

----------------------------------------------------------------
-- CORE UTILITIES
----------------------------------------------------------------

local function isVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char, part.Parent }
    local result = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil
end

local function isTeammate(p)
    if not ProtectionSettings.IgnoreTeam then return false end
    if not LocalPlayer.Team or not p.Team then return false end
    return LocalPlayer.Team == p.Team
end

local function CreateHealthBar(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Bar_" .. player.Name
    billboard.Size = UDim2.new(4, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false

    local background = Instance.new("Frame", billboard)
    background.Name = "Bar"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    Instance.new("UICorner", background)

    local fill = Instance.new("Frame", background)
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill)

    billboard.Parent = ScreenGui
    return billboard
end

----------------------------------------------------------------
-- INITIALIZE UI CONTROLS
----------------------------------------------------------------

CreateToggle("Enable Protection", false, function(v) ProtectionSettings.Enabled = v end)
CreateCycler("Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}, 1, function(v)
    ProtectionSettings.TargetPart = v
end)
CreateSlider("FOV Radius", 1, 600, ProtectionSettings.FOV, function(v) ProtectionSettings.FOV = v end)
CreateSlider("Smoothness", 0, 1, ProtectionSettings.Smoothness, function(v) ProtectionSettings.Smoothness = v end)
CreateToggle("Hard Aim", false, function(v) ProtectionSettings.HardAim = v end)
CreateToggle("Wall Check", true, function(v) ProtectionSettings.WallCheck = v end)
CreateToggle("Ignore Teammates", true, function(v) ProtectionSettings.IgnoreTeam = v end)
CreateToggle("Sticky Target", true, function(v) ProtectionSettings.StickyTarget = v end)
CreateToggle("Show FOV Circle", true, function(v) ProtectionSettings.ShowFOV = v end)
CreateToggle("Show Health Bars", false, function(v) ProtectionSettings.ShowHealthBars = v end)

-- FOV Circle permanently pinned to the dead center
local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = ScreenGui
local Stroke = Instance.new("UIStroke", FOVCircle)
Stroke.Color = Color3.fromRGB(0, 170, 255)
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

----------------------------------------------------------------
-- DRAGGABLE MENU (dual-path: TitleBar.InputChanged + UIS.InputChanged)
----------------------------------------------------------------

do
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateDrag(input)
        if not dragging or not dragStart then return end
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        local vp = Camera.ViewportSize
        local w, h = MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y
        newX = math.clamp(newX, -(vp.X / 2) + w / 2 + 8, (vp.X / 2) - w / 2 - 8)
        newY = math.clamp(newY, -(vp.Y / 2) + h / 2 + 8, (vp.Y / 2) - h / 2 - 8)
        MainFrame.Position = UDim2.new(0.5, newX, 0.5, newY)
    end

    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end

    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end

    track(TitleBar.InputBegan:Connect(beginDrag))

    -- Path A: global UIS (works when nothing else captures)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateDrag(input)
        end
    end))

    -- Path B: GuiObject direct (works when UIS is swallowed)
    track(TitleBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateDrag(input)
        end
    end))

    -- Reset on release from either source
    track(UserInputService.InputEnded:Connect(endDrag))
    track(TitleBar.InputEnded:Connect(endDrag))
end

----------------------------------------------------------------
-- UNLOAD (fully clean)
----------------------------------------------------------------

local function UnloadScript()
    ProtectionSettings.Enabled = false
    ProtectionSettings.ShowHealthBars = false

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    for _, bar in pairs(HealthBarStorage) do
        pcall(function() bar:Destroy() end)
    end
    HealthBarStorage = {}

    pcall(function() ScreenGui:Destroy() end)
end

CreateButton("Unload Script", Color3.fromRGB(170, 50, 50), UnloadScript)

----------------------------------------------------------------
-- MENU OPEN / CLOSE
----------------------------------------------------------------

track(OpenButton.Activated:Connect(function()
    GuiOpen = not GuiOpen
    MainFrame.Visible = GuiOpen
    OpenButton.Text = GuiOpen and "Close" or "Menu"
end))

track(CloseButton.Activated:Connect(function()
    GuiOpen = false
    MainFrame.Visible = false
    OpenButton.Text = "Menu"
end))

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------

track(RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize
    local screenCenter = Vector2.new(vpSize.X / 2, vpSize.Y / 2)

    -- 1. FOV Circle
    if ProtectionSettings.Enabled and ProtectionSettings.ShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        FOVCircle.Size = UDim2.new(0, ProtectionSettings.FOV * 2, 0, ProtectionSettings.FOV * 2)
    else
        FOVCircle.Visible = false
    end

    -- 2. Target Selection with sticky + grace + team filter
    local target = nil
    if ProtectionSettings.Enabled then
        local maxDist = ProtectionSettings.FOV
        local bestPlayer, bestDist = nil, math.huge
        local currentPlayer, currentDist = nil, math.huge

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer
            and not isTeammate(p)
            and p.Character
            and p.Character:FindFirstChild("Humanoid")
            and p.Character.Humanoid.Health > 0 then
                local part = p.Character:FindFirstChild(ProtectionSettings.TargetPart)
                    or p.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        local passesWallCheck = not ProtectionSettings.WallCheck or isVisible(part)
                        -- Current target gets a wider re-acquire window
                        local limit = (p.Name == currentTargetName) and (maxDist + 30) or maxDist
                        if dist <= limit and passesWallCheck then
                            if p.Name == currentTargetName then
                                currentPlayer, currentDist = p, dist
                            end
                            if dist < bestDist then
                                bestPlayer, bestDist = p, dist
                            end
                        end
                    end
                end
            end
        end

        -- Sticky decision
        if ProtectionSettings.StickyTarget and currentPlayer then
            target = currentPlayer
            if bestPlayer and bestPlayer ~= currentPlayer and bestDist < currentDist - ProtectionSettings.SwitchMargin then
                target = bestPlayer
                currentTargetName = bestPlayer.Name
            end
        else
            target = bestPlayer
            currentTargetName = bestPlayer and bestPlayer.Name or nil
        end

        -- Grace period: keep last target briefly if selection dropped out
        if target then
            lastTargetTime = tick()
        elseif currentTargetName and tick() - lastTargetTime  CONTROLS
----------------------------------------------------------------

CreateToggle("Enable Protection", false, function(v) ProtectionSettings.Enabled = v end)
CreateSlider("FOV Radius", 1, 600, ProtectionSettings.FOV, function(v) ProtectionSettings.FOV = v end)
CreateSlider("Smoothness", 0, 1, ProtectionSettings.Smoothness, function(v) ProtectionSettings.Smoothness = v end)
CreateToggle("Hard Aim", false, function(v) ProtectionSettings.HardAim = v end)
CreateToggle("Wall Check", true, function(v) ProtectionSettings.WallCheck = v end)
CreateToggle("Show FOV Circle", true, function(v) ProtectionSettings.ShowFOV = v end)
CreateToggle("Show Health Bars", false, function(v) ProtectionSettings.ShowHealthBars = v end)

-- FOV Circle permanently pinned to the dead center
local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = ScreenGui
local Stroke = Instance.new("UIStroke", FOVCircle)
Stroke.Color = Color3.fromRGB(0, 170, 255)
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

----------------------------------------------------------------
-- DRAGGABLE MENU (title bar only, touch + mouse)
----------------------------------------------------------------

do
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateDrag(input)
        if not dragging or not dragStart then return end
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y

        local vp = Camera.ViewportSize
        local w, h = MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y
        newX = math.clamp(newX, -(vp.X / 2) + w / 2 + 8, (vp.X / 2) - w / 2 - 8)
        newY = math.clamp(newY, -(vp.Y / 2) + h / 2 + 8, (vp.Y / 2) - h / 2 - 8)

        MainFrame.Position = UDim2.new(0.5, newX, 0.5, newY)
    end

    track(Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end))
end

----------------------------------------------------------------
-- UNLOAD (Option B - fully clean)
----------------------------------------------------------------

local function UnloadScript()
    -- Stop all logic immediately
    ProtectionSettings.Enabled = false
    ProtectionSettings.ShowHealthBars = false

    -- Disconnect every tracked connection
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    -- Destroy health bars
    for _, bar in pairs(HealthBarStorage) do
        pcall(function() bar:Destroy() end)
    end
    HealthBarStorage = {}

    -- Destroy the whole UI (ScreenGui holds FOVCircle, health bars, buttons)
    pcall(function() ScreenGui:Destroy() end)
end

CreateButton("Unload Script", Color3.fromRGB(170, 50, 50), UnloadScript)

----------------------------------------------------------------
-- MENU OPEN / CLOSE
----------------------------------------------------------------

track(OpenButton.Activated:Connect(function()
    GuiOpen = not GuiOpen
    MainFrame.Visible = GuiOpen
    OpenButton.Text = GuiOpen and "Close" or "Menu"
end))

track(CloseButton.Activated:Connect(function()
    GuiOpen = false
    MainFrame.Visible = false
    OpenButton.Text = "Menu"
end))

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------

track(RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize
    local screenCenter = Vector2.new(vpSize.X / 2, vpSize.Y / 2)

    -- 1. FOV Circle (Fixed strictly in the center)
    if ProtectionSettings.Enabled and ProtectionSettings.ShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        FOVCircle.Size = UDim2.new(0, ProtectionSettings.FOV * 2, 0, ProtectionSettings.FOV * 2)
    else
        FOVCircle.Visible = false
    end

    -- 2. Target Selection (Strictly closest to screen center)
    local target = nil
    if ProtectionSettings.Enabled then
        local maxDist = ProtectionSettings.FOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local part = p.Character:FindFirstChild(ProtectionSettings.TargetPart)
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        local passesWallCheck = not ProtectionSettings.WallCheck or isVisible(part)
                        if dist <= maxDist and passesWallCheck then
                            maxDist = dist
                            target = p
                        end
                    end
                end
            end
        end

        if target and target.Character then
            local aimPart = target.Character[ProtectionSettings.TargetPart]
            local targetCF = CFrame.new(Camera.CFrame.Position, aimPart.Position)
            if ProtectionSettings.HardAim then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, ProtectionSettings.Smoothness)
            end
            InfoLabel.Text = "Target: " .. target.Name
        else
            InfoLabel.Text = "Target: None"
        end
    end

    -- 3. Health Bars
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function()
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
                local bar = HealthBarStorage[player.Name]
                if not bar then
                    bar = CreateHealthBar(player)
                    HealthBarStorage[player.Name] = bar
                end

                local hum = player.Character.Humanoid
                local head = player.Character.Head
                local barFrame = bar:FindFirstChild("Bar")

                if ProtectionSettings.ShowHealthBars and hum.Health > 0 and (not ProtectionSettings.WallCheck or isVisible(head)) then
                    bar.Enabled = true
                    bar.Adornee = head
                    if barFrame and barFrame:FindFirstChild("Fill") then
                        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        barFrame.Fill.Size = UDim2.new(hp, 0, 1, 0)
                        barFrame.Fill.BackgroundColor3 = Color3.fromHSV(hp * 0.3, 1, 1)
                    end
                else
                    bar.Enabled = false
                end
            elseif HealthBarStorage[player.Name] then
                HealthBarStorage[player.Name]:Destroy()
                HealthBarStorage[player.Name] = nil
            end
        end)
    end
end))

----------------------------------------------------------------
-- CLEANUP ON LEAVE
----------------------------------------------------------------

track(Players.PlayerRemoving:Connect(function(player)
    if HealthBarStorage[player.Name] then
        HealthBarStorage[player.Name]:Destroy()
        HealthBarStorage[player.Name] = nil
    end
end))
