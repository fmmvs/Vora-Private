-- [[ VORA PRIVATE // ELITE V11 - FULL RED EDITION ]] --
-- Menu Toggle: RIGHT CONTROL

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Configuration State
local Vora = {
    CurrentTab = "Aimlock",
    LockedTarget = nil,
    AimKey = nil,
    WalkKey = nil,
    
    -- Aimlock Settings
    AimEnabled = true,
    Smoothing = 0,
    Prediction = 0,
    AimFOV = 150,
    WallCheckOnSelect = true,
    SmartKOCheck = true,
    
    -- ESP Settings
    ESPEnabled = false,
    ESPObjects = {},
    
    -- Misc Settings
    WalkSpeed = 16,
    WalkToggle = false,
    KillAuraEnabled = false,
    KillAuraTarget = "",
    
    Accent = Color3.fromRGB(255, 0, 0) -- RED ACCENT
}

-- // Visual Helpers (Original Circle Logic)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Radius = Vora.AimFOV
FOVCircle.Visible = Vora.AimEnabled
FOVCircle.Color = Vora.Accent
FOVCircle.Transparency = 1

-- // UI Framework (Elite V11 Base)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 450, 0, 520)
Main.Position = UDim2.new(0.5, -225, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Main.BorderSizePixel = 2
Main.BorderColor3 = Vora.Accent
Main.Active = true
Main.Draggable = true

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Header.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "VORA PRIVATE"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 32
Title.BackgroundTransparency = 1

local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(1, 0, 0, 45)
TabFrame.Position = UDim2.new(0, 0, 0, 60)
TabFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TabFrame.BorderSizePixel = 0

local function CreateTabBtn(text, pos)
    local btn = Instance.new("TextButton", TabFrame)
    btn.Size = UDim2.new(0.33, 0, 1, 0)
    btn.Position = UDim2.new(pos, 0, 0, 0)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(0.4, 0.4, 0.4)
    btn.BackgroundTransparency = 1
    return btn
end

local AimTabBtn = CreateTabBtn("AIMLOCK", 0)
local ESPTabBtn = CreateTabBtn("ESP", 0.33)
local MiscTabBtn = CreateTabBtn("MISC", 0.66)
AimTabBtn.TextColor3 = Vora.Accent

local function CreateContainer()
    local c = Instance.new("ScrollingFrame", Main)
    c.Size = UDim2.new(1, -40, 1, -120)
    c.Position = UDim2.new(0, 20, 0, 115)
    c.BackgroundTransparency = 1
    c.CanvasSize = UDim2.new(0, 0, 0, 650)
    c.ScrollBarThickness = 0
    c.Visible = false
    Instance.new("UIListLayout", c).Padding = UDim.new(0, 15)
    return c
end

local AimContainer = CreateContainer(); AimContainer.Visible = true
local ESPContainer = CreateContainer()
local MiscContainer = CreateContainer()

-- // ESP Setup
local function CreateESP(plr)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Vora.Accent
    box.Thickness = 1
    Vora.ESPObjects[plr] = box
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(p) if Vora.ESPObjects[p] then Vora.ESPObjects[p]:Remove() Vora.ESPObjects[p] = nil end end)

-- // Logic Helpers (Original Calculations)
local function IsValid(target)
    if not target or not target.Character or not target.Character:FindFirstChild("Head") then return false end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    if Vora.SmartKOCheck and hum and hum.Health <= 1 then return false end
    return true
end

local function GetClosest()
    local target, closest = nil, Vora.AimFOV
    local mouse = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsValid(p) then
            if Vora.WallCheckOnSelect then
                local parts = Camera:GetPartsObscuringTarget({p.Character.Head.Position}, {LocalPlayer.Character, p.Character})
                if #parts > 0 then continue end
            end
            local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if dist < closest then target = p; closest = dist end
            end
        end
    end
    return target
end

-- // UI Elements
local function CreateToggle(name, default, parent, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, 0, 0, 50); Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Btn.BorderSizePixel = 0
    Btn.Text = name .. (default and ": ON" or ": OFF"); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 16
    Btn.TextColor3 = default and Vora.Accent or Color3.new(0.6, 0.6, 0.6)
    local s = default
    Btn.MouseButton1Click:Connect(function()
        s = not s; Btn.Text = name .. (s and ": ON" or ": OFF"); Btn.TextColor3 = s and Vora.Accent or Color3.new(0.6, 0.6, 0.6); callback(s)
    end)
end

local function CreateSlider(name, min, max, default, parent, callback)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 60); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 25); l.Text = name .. ": " .. default; l.TextColor3 = Color3.new(1, 1, 1); l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(1, 0, 0, 6); bg.Position = UDim2.new(0, 0, 0, 35); bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35); bg.BorderSizePixel = 0
    local fill = Instance.new("Frame", bg); fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Vora.Accent; fill.BorderSizePixel = 0
    local function Update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor((min + (max - min) * pos) * 100) / 100
        l.Text = name .. ": " .. val; callback(val)
    end
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local c; c = UserInputService.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)
            local r; r = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then c:Disconnect(); r:Disconnect() end end)
            Update(input)
        end
    end)
end

-- Populate Tabs
CreateToggle("Enable Lock", true, AimContainer, function(v) Vora.AimEnabled = v; FOVCircle.Visible = v end)
CreateToggle("Wall Check", true, AimContainer, function(v) Vora.WallCheckOnSelect = v end)
CreateToggle("Smart KO Check", true, AimContainer, function(v) Vora.SmartKOCheck = v end)

local AimBindBtn = Instance.new("TextButton", AimContainer); AimBindBtn.Size = UDim2.new(1, 0, 0, 50); AimBindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); AimBindBtn.Text = "SET LOCK KEY"; AimBindBtn.Font = Enum.Font.GothamBold; AimBindBtn.TextColor3 = Color3.new(1,1,1); AimBindBtn.BorderSizePixel = 0
AimBindBtn.MouseButton1Click:Connect(function()
    AimBindBtn.Text = "..."; local c; c = UserInputService.InputBegan:Connect(function(i)
        Vora.AimKey = (i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType)
        AimBindBtn.Text = "KEY: " .. Vora.AimKey.Name:upper(); c:Disconnect()
    end)
end)

CreateSlider("Smoothing", 0, 1, 0, AimContainer, function(v) Vora.Smoothing = v end)
CreateSlider("Prediction", 0, 1, 0, AimContainer, function(v) Vora.Prediction = v end)
CreateSlider("FOV Size", 30, 800, 150, AimContainer, function(v) Vora.AimFOV = v; FOVCircle.Radius = v end)

CreateToggle("Box ESP", false, ESPContainer, function(v) Vora.ESPEnabled = v end)

-- Kill Aura & Misc
local AuraInput = Instance.new("TextBox", MiscContainer)
AuraInput.Size = UDim2.new(1, 0, 0, 45); AuraInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20); AuraInput.BorderSizePixel = 0
AuraInput.PlaceholderText = "Type Username Here..."; AuraInput.Text = ""; AuraInput.Font = Enum.Font.GothamBold; AuraInput.TextColor3 = Color3.new(1,1,1); AuraInput.TextSize = 14
AuraInput.FocusLost:Connect(function() Vora.KillAuraTarget = AuraInput.Text end)

CreateToggle("Kill Aura", false, MiscContainer, function(v) Vora.KillAuraEnabled = v end)

local SpeedBindBtn = Instance.new("TextButton", MiscContainer); SpeedBindBtn.Size = UDim2.new(1, 0, 0, 45); SpeedBindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); SpeedBindBtn.Text = "SET SPEED KEY"; SpeedBindBtn.Font = Enum.Font.GothamBold; SpeedBindBtn.TextColor3 = Color3.new(1,1,1); SpeedBindBtn.BorderSizePixel = 0
SpeedBindBtn.MouseButton1Click:Connect(function()
    SpeedBindBtn.Text = "..."; local c; c = UserInputService.InputBegan:Connect(function(i)
        Vora.WalkKey = (i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType)
        SpeedBindBtn.Text = "KEY: " .. Vora.WalkKey.Name:upper(); c:Disconnect()
    end)
end)
CreateSlider("WalkSpeed", 16, 250, 16, MiscContainer, function(v) Vora.WalkSpeed = v end)

-- Tab Navigation
AimTabBtn.MouseButton1Click:Connect(function() AimContainer.Visible = true; ESPContainer.Visible = false; MiscContainer.Visible = false; AimTabBtn.TextColor3 = Vora.Accent; ESPTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4); MiscTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4) end)
ESPTabBtn.MouseButton1Click:Connect(function() AimContainer.Visible = false; ESPContainer.Visible = true; MiscContainer.Visible = false; ESPTabBtn.TextColor3 = Vora.Accent; AimTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4); MiscTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4) end)
MiscTabBtn.MouseButton1Click:Connect(function() AimContainer.Visible = false; ESPContainer.Visible = false; MiscContainer.Visible = true; MiscTabBtn.TextColor3 = Vora.Accent; AimTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4); ESPTabBtn.TextColor3 = Color3.new(0.4, 0.4, 0.4) end)

-- // Main Update Loop
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()

    -- Speed Logic
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Vora.WalkToggle and Vora.WalkSpeed or 16
    end

    -- Kill Aura Logic
    if Vora.KillAuraEnabled and Vora.KillAuraTarget ~= "" then
        local targetPlr = Players:FindFirstChild(Vora.KillAuraTarget)
        if IsValid(targetPlr) and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = targetPlr.Character.HumanoidRootPart
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHRP.Position)
        else
            Vora.KillAuraEnabled = false
        end
    end

    -- Original Aimlock Logic (Preserved Math)
    if Vora.AimEnabled and Vora.LockedTarget then
        if not IsValid(Vora.LockedTarget) then Vora.LockedTarget = nil; return end
        local head = Vora.LockedTarget.Character.Head
        local root = Vora.LockedTarget.Character:FindFirstChild("HumanoidRootPart")
        local tPos = head.Position + (root and root.Velocity * Vora.Prediction or Vector3.zero)
        local targetCF = CFrame.new(Camera.CFrame.Position, tPos)
        if Vora.Smoothing <= 0 then Camera.CFrame = targetCF else Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Vora.Smoothing) end
    end

    -- ESP Fix (Updating after camera movement)
    for plr, box in pairs(Vora.ESPObjects) do
        if Vora.ESPEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3.5, 0))
                local h = math.abs(top.Y - bottom.Y)
                box.Size = Vector2.new(h / 1.5, h)
                box.Position = Vector2.new(pos.X - (box.Size.X / 2), pos.Y - (box.Size.Y / 2))
                box.Visible = true
            else box.Visible = false end
        else box.Visible = false end
    end
end)

-- // Input Processing (Original Toggle Logic)
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible end
    if Vora.AimKey and (i.KeyCode == Vora.AimKey or i.UserInputType == Vora.AimKey) then
        if Vora.LockedTarget then Vora.LockedTarget = nil else Vora.LockedTarget = GetClosest() end
    end
    if Vora.WalkKey and (i.KeyCode == Vora.WalkKey or i.UserInputType == Vora.WalkKey) then
        Vora.WalkToggle = not Vora.WalkToggle
    end
end)

print("VORA PRIVATE // ELITE V11 - RED & FULL FEATURES LOADED")
