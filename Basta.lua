-- Secret Service Protection (Stable Player-Only Revert)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

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
    SwitchMargin = 30,
    IgnoreTeam = true,
}

local HealthBarStorage = {}
local Minimized = false
local ExpandedHeight = 260
local FrameWidth = 480
local CircleSize = 52

local currentTarget = nil
local lastTargetTime = 0

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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, FrameWidth, 0, ExpandedHeight)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.ClipsDescendants = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local UIScale = Instance.new("UIScale")
UIScale.Scale = 1
UIScale.Parent = MainFrame

local function updateScale()
    local vp = Camera.ViewportSize
    if vp.X < 700 then UIScale.Scale = 0.85
    elseif vp.X < 900 then UIScale.Scale = 0.95
    else UIScale.Scale = 1 end
end
updateScale()
track(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 36)
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

local TitleBar = Instance.new("TextButton")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.Text = ""
TitleBar.AutoButtonColor = false
TitleBar.Active = true
TitleBar.Selectable = true
TitleBar.ZIndex = 10
TitleBar.Parent = MainFrame

local MinimizeCircleButton = Instance.new("TextButton")
MinimizeCircleButton.Name = "MinimizeCircleButton"
MinimizeCircleButton.Size = UDim2.new(0, 28, 0, 28)
MinimizeCircleButton.Position = UDim2.new(1, -34, 0, 4)
MinimizeCircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
MinimizeCircleButton.Text = "○"
MinimizeCircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeCircleButton.Font = Enum.Font.GothamBold
MinimizeCircleButton.TextSize = 16
MinimizeCircleButton.ZIndex = 11
MinimizeCircleButton.Parent = MainFrame
Instance.new("UICorner", MinimizeCircleButton).CornerRadius = UDim.new(1, 0)

local Columns = Instance.new("Frame")
Columns.Name = "Columns"
Columns.Size = UDim2.new(1, -16, 1, -44)
Columns.Position = UDim2.new(0, 8, 0, 40)
Columns.BackgroundTransparency = 1
Columns.Parent = MainFrame

local LeftColumn = Instance.new("ScrollingFrame")
LeftColumn.Name = "LeftColumn"
LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
LeftColumn.Position = UDim2.new(0, 0, 0, 0)
LeftColumn.BackgroundTransparency = 1
LeftColumn.BorderSizePixel = 0
LeftColumn.ScrollBarThickness = 2
LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 400)
LeftColumn.Parent = Columns

local LeftList = Instance.new("UIListLayout")
LeftList.Padding = UDim.new(0, 4)
LeftList.Parent = LeftColumn

local RightColumn = Instance.new("ScrollingFrame")
RightColumn.Name = "RightColumn"
RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
RightColumn.Position = UDim2.new(0.5, 4, 0, 0)
RightColumn.BackgroundTransparency = 1
RightColumn.BorderSizePixel = 0
RightColumn.ScrollBarThickness = 2
RightColumn.CanvasSize = UDim2.new(0, 0, 0, 400)
RightColumn.Parent = Columns

local RightList = Instance.new("UIListLayout")
RightList.Padding = UDim.new(0, 4)
RightList.Parent = RightColumn

----------------------------------------------------------------
-- UI CONTROLS
----------------------------------------------------------------

local function CreateToggle(name, default, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -4, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 40, 0, 20)
    Btn.Position = UDim2.new(1, -44, 0.5, -10)
    Btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
    Btn.Text = ""
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    track(Btn.Activated:Connect(function()
        local newState = Btn.BackgroundColor3 == Color3.fromRGB(60, 60, 60)
        Btn.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
        callback(newState)
    end))
end

local function CreateSlider(name, min, max, default, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -4, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -8, 0, 18)
    Label.Position = UDim2.new(0, 8, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local SliderBack = Instance.new("TextButton")
    SliderBack.Text = ""
    SliderBack.AutoButtonColor = false
    SliderBack.Size = UDim2.new(1, -16, 0, 8)
    SliderBack.Position = UDim2.new(0, 8, 0.65, -2)
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

local function CreateButton(name, color, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -4, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 22)
    Btn.Position = UDim2.new(0, 4, 0.5, -11)
    Btn.BackgroundColor3 = color
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    track(Btn.Activated:Connect(callback))
end

local function CreateCycler(name, options, defaultIndex, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -4, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -110, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 92, 0, 22)
    Btn.Position = UDim2.new(1, -98, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 11
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
InfoLabel.Size = UDim2.new(1, -4, 0, 26)
InfoLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
InfoLabel.Text = "Target: None"
InfoLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 12
InfoLabel.Parent = RightColumn
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
    if p == LocalPlayer then return false end

    if LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return true end
    if LocalPlayer.TeamColor and p.TeamColor
    and LocalPlayer.TeamColor ~= Enum.TeamColor.Neutral
    and p.TeamColor ~= Enum.TeamColor.Neutral
    and LocalPlayer.TeamColor == p.TeamColor then return true end

    local myAttr, theirAttr = LocalPlayer:GetAttribute("Team"), p:GetAttribute("Team")
    if myAttr ~= nil and theirAttr ~= nil and myAttr == theirAttr then return true end

    local myVal, theirVal = LocalPlayer:FindFirstChild("Team"), p:FindFirstChild("Team")
    if myVal and theirVal and myVal:IsA("ValueBase") and theirVal:IsA("ValueBase")
    and myVal.Value == theirVal.Value then return true end

    return false
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

CreateToggle("Enable Protection", false, function(v) ProtectionSettings.Enabled = v end, LeftColumn)
CreateCycler("Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}, 1, function(v)
    ProtectionSettings.TargetPart = v
end, LeftColumn)
CreateSlider("FOV Radius", 1, 600, ProtectionSettings.FOV, function(v) ProtectionSettings.FOV = v end, LeftColumn)
CreateSlider("Smoothness", 0, 1, ProtectionSettings.Smoothness, function(v) ProtectionSettings.Smoothness = v end, LeftColumn)
CreateToggle("Hard Aim", false, function(v) ProtectionSettings.HardAim = v end, LeftColumn)
CreateToggle("Sticky Target", true, function(v) ProtectionSettings.StickyTarget = v end, LeftColumn)

CreateToggle("Wall Check", true, function(v) ProtectionSettings.WallCheck = v end, RightColumn)
CreateToggle("Ignore Teammates", true, function(v) ProtectionSettings.IgnoreTeam = v end, RightColumn)
CreateToggle("Show FOV Circle", true, function(v) ProtectionSettings.ShowFOV = v end, RightColumn)
CreateToggle("Show Health Bars", false, function(v) ProtectionSettings.ShowHealthBars = v end, RightColumn)

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = ScreenGui
local Stroke = Instance.new("UIStroke", FOVCircle)
Stroke.Color = Color3.fromRGB(0, 170, 255)
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

----------------------------------------------------------------
-- DRAG & TAP LOGIC
----------------------------------------------------------------

do
    local dragging = false
    local dragTouchId = nil
    local dragStart = nil
    local startPos = nil
    
    local tapStart = 0
    local tapPos = Vector2.zero

    local function updateDrag(pos)
        if not dragging or not dragStart then return end
        local delta = pos - dragStart
        local vp = Camera.ViewportSize
        
        local currentW = MainFrame.AbsoluteSize.X
        local currentH = MainFrame.AbsoluteSize.Y

        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        
        local pad = Minimized and 0 or 10
        
        newX = math.clamp(newX, -(vp.X / 2) + (currentW / 2) + pad, (vp.X / 2) - (currentW / 2) - pad)
        newY = math.clamp(newY, -(vp.Y / 2) + (currentH / 2) + pad, (vp.Y / 2) - (currentH / 2) - pad)
        
        MainFrame.Position = UDim2.new(0.5, newX, 0.5, newY)
    end

    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragTouchId = input
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = MainFrame.Position
            
            if Minimized then
                tapStart = tick()
                tapPos = Vector2.new(input.Position.X, input.Position.Y)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragTouchId = nil
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = MainFrame.Position
            
            if Minimized then
                tapStart = tick()
                tapPos = Vector2.new(input.Position.X, input.Position.Y)
            end
        end
    end

    local function endDrag(input)
        if dragTouchId and input == dragTouchId then
            dragging = false
            dragTouchId = nil
            
            if Minimized and (tick() - tapStart) < 0.3 then
                toggleMinimize()
            end
            
            dragStart = nil
            startPos = nil
        elseif not dragTouchId and input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if Minimized and (tick() - tapStart) < 0.3 then
                toggleMinimize()
            end
            dragStart = nil
            startPos = nil
        end
    end

    track(TitleBar.InputBegan:Connect(beginDrag))
    
    track(UserInputService.TouchMoved:Connect(function(input)
        if not dragging then return end
        if dragTouchId and input ~= dragTouchId then return end
        updateDrag(Vector2.new(input.Position.X, input.Position.Y))
    end))

    track(UserInputService.TouchEnded:Connect(endDrag))

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and dragTouchId == nil and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(Vector2.new(input.Position.X, input.Position.Y))
        end
    end))

    track(UserInputService.InputEnded:Connect(endDrag))
end

----------------------------------------------------------------
-- MINIMIZE / EXPAND (MORPH FRAME INTO CIRCLE)
----------------------------------------------------------------

function toggleMinimize()
    Minimized = not Minimized

    if Minimized then
        Columns.Visible = false
        Title.Visible = false
        MinimizeCircleButton.Visible = false
        
        TitleBar.Size = UDim2.new(1, 0, 1, 0)

        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { 
            Size = UDim2.new(0, CircleSize, 0, CircleSize),
            BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        }):Play()

        TweenService:Create(MainCorner, TweenInfo.new(0.3), { 
            CornerRadius = UDim.new(1, 0) 
        }):Play()
    else
        TitleBar.Size = UDim2.new(1, 0, 0, 36)

        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { 
            Size = UDim2.new(0, FrameWidth, 0, ExpandedHeight),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        }):Play()

        TweenService:Create(MainCorner, TweenInfo.new(0.3), { 
            CornerRadius = UDim.new(0, 10) 
        }):Play()

        task.delay(0.3, function()
            if not Minimized then
                Columns.Visible = true
                Title.Visible = true
                MinimizeCircleButton.Visible = true
            end
        end)
    end
end

track(MinimizeCircleButton.Activated:Connect(toggleMinimize))

----------------------------------------------------------------
-- UNLOAD
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

CreateButton("Unload Script", Color3.fromRGB(170, 50, 50), UnloadScript, RightColumn)

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------

track(RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize
    local screenCenter = Vector2.new(vpSize.X / 2, vpSize.Y / 2)

    if ProtectionSettings.Enabled and ProtectionSettings.ShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        FOVCircle.Size = UDim2.new(0, ProtectionSettings.FOV * 2, 0, ProtectionSettings.FOV * 2)
    else
        FOVCircle.Visible = false
    end

    if ProtectionSettings.Enabled then
        local maxDist = ProtectionSettings.FOV
        local bestTarget, bestDist = nil, math.huge
        local validCurrentDist = math.huge
        
        -- 1. Check if our current target is still valid
        if currentTarget then
            local char = currentTarget.Character
            
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local part = char:FindFirstChild(ProtectionSettings.TargetPart) or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        local passesWallCheck = not ProtectionSettings.WallCheck or isVisible(part)
                        -- Grace window of +30 pixels for the locked target
                        if dist <= (maxDist + 30) and passesWallCheck then
                            validCurrentDist = dist
                        end
                    end
                end
            end
        end

        -- 2. Find the best new target
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isTeammate(p) then
                local char = p.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local part = char:FindFirstChild(ProtectionSettings.TargetPart) or char:FindFirstChild("HumanoidRootPart")
                    if part then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            local passesWallCheck = not ProtectionSettings.WallCheck or isVisible(part)
                            
                            if dist <= maxDist and passesWallCheck then
                                if dist < bestDist then 
                                    bestTarget, bestDist = p, dist 
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 3. Sticky Logic
        if ProtectionSettings.StickyTarget and currentTarget and validCurrentDist < math.huge then
            -- Keep current target unless new target is closer by SwitchMargin
            if bestTarget and bestTarget ~= currentTarget and bestDist < (validCurrentDist - ProtectionSettings.SwitchMargin) then
                currentTarget = bestTarget
            end
        else
            -- Not sticky, or lost current target
            currentTarget = bestTarget
        end

        -- 4. Grace period
        if currentTarget then
            lastTargetTime = tick()
        elseif currentTarget and tick() - lastTargetTime < 0.25 then
            -- keep target briefly
        else
            currentTarget = nil
        end

        -- 5. Aim execution
        if currentTarget then
            local targetChar = currentTarget.Character
            if targetChar then
                local aimPart = targetChar:FindFirstChild(ProtectionSettings.TargetPart) or targetChar:FindFirstChild("HumanoidRootPart")
                if aimPart then
                    local targetCF = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                    if ProtectionSettings.HardAim then
                        Camera.CFrame = targetCF
                    else
                        Camera.CFrame = Camera.CFrame:Lerp(targetCF, ProtectionSettings.Smoothness)
                    end
                    InfoLabel.Text = "Target: " .. currentTarget.Name
                else
                    InfoLabel.Text = "Target: None"
                end
            end
        else
            InfoLabel.Text = "Target: None"
        end
    end

    -- Health Bars
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function()
            if player ~= LocalPlayer and not isTeammate(player) and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
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
