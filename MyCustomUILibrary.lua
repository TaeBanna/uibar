--[[
    ===================================================================
    MyCustomUILibrary - Premium Modern UI Library for Roblox
    Optimized, Memory-Leak Free, Mobile Friendly, and Highly Extensible
    ===================================================================
--]]

local MyUI = {}
MyUI.UnloadCallbacks = {}
MyUI.Connections = {}
MyUI.CurrentScreenGui = nil
MyUI.NotifContainer = nil
MyUI.NotifGui = nil

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

-- Safe parent container resolver
local function GetSafeGuiParent()
    if gethui then
        local success, result = pcall(gethui)
        if success and result then return result end
    end
    local success, _ = pcall(function() return CoreGui.Name end)
    if success then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- =====================================
-- Theme Engine
-- =====================================
MyUI.Theme = {
    Background   = Color3.fromRGB(15, 15, 22),
    Sidebar      = Color3.fromRGB(20, 20, 28),
    Topbar       = Color3.fromRGB(20, 20, 28),
    Element      = Color3.fromRGB(25, 25, 35),
    ElementHover = Color3.fromRGB(34, 34, 48),
    Accent       = Color3.fromRGB(85, 125, 255),
    AccentDark   = Color3.fromRGB(60, 95, 210),
    Text         = Color3.fromRGB(245, 245, 250),
    TextDark     = Color3.fromRGB(140, 140, 155),
    Outline      = Color3.fromRGB(42, 42, 58),
    Red          = Color3.fromRGB(255, 75, 75),
    Green        = Color3.fromRGB(65, 210, 125),
    Yellow       = Color3.fromRGB(255, 195, 65)
}

function MyUI:SetTheme(newTheme)
    if type(newTheme) == "table" then
        for k, v in pairs(newTheme) do
            if MyUI.Theme[k] ~= nil then
                MyUI.Theme[k] = v
            end
        end
    end
end

-- =====================================
-- Internal Helpers
-- =====================================
local function TrackConnection(conn)
    table.insert(MyUI.Connections, conn)
    return conn
end

local function Tween(obj, props, time, style, dir)
    time = time or 0.2
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
    tw:Play()
    return tw
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or MyUI.Theme.Outline
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Active dropdown tracker for auto-closing when clicking outside
local ActiveDropdownData = nil

-- =====================================
-- Unload System
-- =====================================
function MyUI:OnUnload(callback)
    if type(callback) == "function" then
        table.insert(self.UnloadCallbacks, callback)
    end
end

function MyUI:Unload()
    -- Execute user cleanup callbacks safely
    for _, cb in ipairs(self.UnloadCallbacks) do
        pcall(cb)
    end
    self.UnloadCallbacks = {}

    -- Disconnect all tracked library connections
    for _, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    self.Connections = {}
    ActiveDropdownData = nil

    -- Clean up active UI instances
    if self.CurrentScreenGui and self.CurrentScreenGui.Parent then
        self.CurrentScreenGui:Destroy()
        self.CurrentScreenGui = nil
    end

    if self.NotifGui and self.NotifGui.Parent then
        self.NotifGui:Destroy()
        self.NotifGui = nil
        self.NotifContainer = nil
    end

    -- Fallback search to clean up orphaned instances in CoreGui or gethui()
    local parent = GetSafeGuiParent()
    local oldUI = parent:FindFirstChild("MyCustomUI_ScreenV2")
    if oldUI then pcall(function() oldUI:Destroy() end) end
    local oldNotif = parent:FindFirstChild("MyCustomUI_NotifV2")
    if oldNotif then pcall(function() oldNotif:Destroy() end) end
end

-- =====================================
-- Standalone Notification System
-- =====================================
local function EnsureNotifContainer()
    if MyUI.NotifContainer and MyUI.NotifContainer.Parent and MyUI.NotifGui and MyUI.NotifGui.Parent then
        return MyUI.NotifContainer
    end

    local parent = GetSafeGuiParent()
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MyCustomUI_NotifV2"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder = 9999
    notifGui.Parent = parent
    MyUI.NotifGui = notifGui

    local container = Instance.new("Frame")
    container.Name = "NotifContainer"
    container.Size = UDim2.new(0, 310, 1, -40)
    container.Position = UDim2.new(1, -325, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = notifGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.Parent = container

    MyUI.NotifContainer = container
    return container
end

function MyUI:Notify(title, text, duration, notifType)
    duration = duration or 3.5
    local container = EnsureNotifContainer()

    local accentColor = MyUI.Theme.Accent
    if notifType == "Success" then
        accentColor = MyUI.Theme.Green
    elseif notifType == "Error" then
        accentColor = MyUI.Theme.Red
    elseif notifType == "Warning" then
        accentColor = MyUI.Theme.Yellow
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifFrame.BackgroundColor3 = MyUI.Theme.Sidebar
    NotifFrame.BackgroundTransparency = 0.05
    NotifFrame.ClipsDescendants = true
    NotifFrame.Parent = container

    CreateCorner(NotifFrame, 8)
    CreateStroke(NotifFrame, MyUI.Theme.Outline, 1)

    -- Left colored accent bar
    local AccentPill = Instance.new("Frame")
    AccentPill.Size = UDim2.new(0, 4, 1, -12)
    AccentPill.Position = UDim2.new(0, 6, 0, 6)
    AccentPill.BackgroundColor3 = accentColor
    AccentPill.BorderSizePixel = 0
    AccentPill.Parent = NotifFrame
    CreateCorner(AccentPill, 2)

    local NTitle = Instance.new("TextLabel")
    NTitle.Size = UDim2.new(1, -55, 0, 22)
    NTitle.Position = UDim2.new(0, 18, 0, 6)
    NTitle.BackgroundTransparency = 1
    NTitle.Text = tostring(title or "Notification")
    NTitle.TextColor3 = accentColor
    NTitle.Font = Enum.Font.GothamBold
    NTitle.TextSize = 13
    NTitle.TextXAlignment = Enum.TextXAlignment.Left
    NTitle.Parent = NotifFrame

    -- Close Button (X)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -26, 0, 7)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = MyUI.Theme.TextDark
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = NotifFrame

    local NText = Instance.new("TextLabel")
    NText.Size = UDim2.new(1, -30, 0, 0)
    NText.Position = UDim2.new(0, 18, 0, 28)
    NText.BackgroundTransparency = 1
    NText.Text = tostring(text or "")
    NText.TextColor3 = MyUI.Theme.Text
    NText.Font = Enum.Font.Gotham
    NText.TextSize = 12
    NText.TextXAlignment = Enum.TextXAlignment.Left
    NText.TextYAlignment = Enum.TextYAlignment.Top
    NText.TextWrapped = true
    NText.Parent = NotifFrame

    -- Calculate dynamic height based on text content
    local measuredBounds = TextService:GetTextSize(
        NText.Text,
        12,
        Enum.Font.Gotham,
        Vector2.new(270, 1000)
    )
    local targetHeight = math.clamp(38 + measuredBounds.Y + 12, 60, 140)
    NText.Size = UDim2.new(1, -30, 0, measuredBounds.Y + 4)

    -- Progress Bar
    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 2)
    Bar.Position = UDim2.new(0, 0, 1, -2)
    Bar.BackgroundColor3 = accentColor
    Bar.BorderSizePixel = 0
    Bar.Parent = NotifFrame

    -- Animate In
    Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.35, Enum.EasingStyle.Back)
    Tween(Bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        local tw = Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Sine)
        tw.Completed:Connect(function()
            NotifFrame:Destroy()
        end)
    end

    CloseBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration, dismiss)
end

-- =====================================
-- Main Window
-- =====================================
function MyUI:CreateWindow(options)
    options = options or {}
    local WindowName = options.Name or "Premium Hub V2"
    local ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    local MobileButtonEnabled = options.MobileButton ~= false

    -- Clean up any previous UI instances completely
    MyUI:Unload()

    local parentContainer = GetSafeGuiParent()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MyCustomUI_ScreenV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 100
    ScreenGui.Parent = parentContainer
    MyUI.CurrentScreenGui = ScreenGui

    -- =====================================
    -- Main Frame Setup
    -- =====================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 640, 0, 430)
    MainFrame.Position = UDim2.new(0.5, -320, 0.5, -215)
    MainFrame.BackgroundColor3 = MyUI.Theme.Background
    MainFrame.BackgroundTransparency = 0.04
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    CreateCorner(MainFrame, 10)
    local MainStroke = CreateStroke(MainFrame, MyUI.Theme.Outline, 1)

    -- Drop Shadow
    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Name = "DropShadow"
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    DropShadow.Size = UDim2.new(1, 36, 1, 36)
    DropShadow.ZIndex = 0
    DropShadow.Image = "rbxassetid://5554236805"
    DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    DropShadow.ImageTransparency = 0.4
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(23, 23, 277, 277)
    DropShadow.Parent = MainFrame

    -- =====================================
    -- High Performance Dragging Logic (No Lag)
    -- =====================================
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, -70, 0, 48)
    dragHandle.BackgroundTransparency = 1
    dragHandle.ZIndex = 5
    dragHandle.Parent = MainFrame

    TrackConnection(dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end))

    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    -- Auto-close dropdown only when clicking outside of the dropdown frame
    TrackConnection(UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if ActiveDropdownData then
                local clickPos = input.Position
                local frame = ActiveDropdownData.Frame
                if frame and frame.Parent then
                    local absPos = frame.AbsolutePosition
                    local absSize = frame.AbsoluteSize
                    local isInside = clickPos.X >= absPos.X and clickPos.X <= (absPos.X + absSize.X)
                                 and clickPos.Y >= absPos.Y and clickPos.Y <= (absPos.Y + absSize.Y)
                    if not isInside then
                        ActiveDropdownData.Close()
                    end
                else
                    ActiveDropdownData.Close()
                end
            end
        end
    end))

    -- =====================================
    -- Toggle UI Visibility Logic
    -- =====================================
    local uiToggled = true
    local function SetUIVisible(visible)
        uiToggled = visible
        if uiToggled then
            MainFrame.Visible = true
            Tween(MainFrame, {Size = UDim2.new(0, 640, 0, 430), BackgroundTransparency = 0.04}, 0.35, Enum.EasingStyle.Back)
            Tween(MainStroke, {Transparency = 0}, 0.25)
        else
            if ActiveDropdownData then ActiveDropdownData.Close() end
            Tween(MainFrame, {Size = UDim2.new(0, 640, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quad)
            Tween(MainStroke, {Transparency = 1}, 0.2)
            task.delay(0.25, function()
                if not uiToggled then
                    MainFrame.Visible = false
                end
            end)
        end
    end

    TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == ToggleKey then
            SetUIVisible(not uiToggled)
        end
    end))

    -- =====================================
    -- Mobile Floating Toggle Pill
    -- =====================================
    if MobileButtonEnabled then
        local MobilePill = Instance.new("TextButton")
        MobilePill.Name = "MobileTogglePill"
        MobilePill.Size = UDim2.new(0, 42, 0, 42)
        MobilePill.Position = UDim2.new(0, 15, 0.5, -21)
        MobilePill.BackgroundColor3 = MyUI.Theme.Sidebar
        MobilePill.Text = ""
        MobilePill.AutoButtonColor = false
        MobilePill.Parent = ScreenGui
        CreateCorner(MobilePill, 21)
        local pillStroke = CreateStroke(MobilePill, MyUI.Theme.Accent, 1.5)

        local PillIcon = Instance.new("ImageLabel")
        PillIcon.Size = UDim2.new(0, 22, 0, 22)
        PillIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
        PillIcon.BackgroundTransparency = 1
        PillIcon.Image = "rbxassetid://6031265976" -- Logo dot / app icon
        PillIcon.ImageColor3 = MyUI.Theme.Accent
        PillIcon.Parent = MobilePill

        -- Dragging for mobile button
        local mDragging = false
        local mHasMoved = false
        local mDragStart, mStartPos
        TrackConnection(MobilePill.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                mDragging = true
                mHasMoved = false
                mDragStart = inp.Position
                mStartPos = MobilePill.Position
            end
        end))
        TrackConnection(UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                mDragging = false
            end
        end))
        TrackConnection(UserInputService.InputChanged:Connect(function(inp)
            if mDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local delta = inp.Position - mDragStart
                if delta.Magnitude > 4 then
                    mHasMoved = true
                end
                MobilePill.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + delta.X, mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y)
            end
        end))

        MobilePill.MouseButton1Click:Connect(function()
            if mHasMoved then
                mHasMoved = false
                return
            end
            SetUIVisible(not uiToggled)
            Tween(MobilePill, {Size = UDim2.new(0, 38, 0, 38)}, 0.1)
            task.delay(0.1, function()
                Tween(MobilePill, {Size = UDim2.new(0, 42, 0, 42)}, 0.15)
            end)
        end)
    end

    -- =====================================
    -- Sidebar Setup
    -- =====================================
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 165, 1, 0)
    Sidebar.BackgroundColor3 = MyUI.Theme.Sidebar
    Sidebar.BackgroundTransparency = 0.2
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarBorder = Instance.new("Frame")
    SidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    SidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    SidebarBorder.BackgroundColor3 = MyUI.Theme.Outline
    SidebarBorder.BorderSizePixel = 0
    SidebarBorder.Parent = Sidebar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 48)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowName
    TitleLabel.TextColor3 = MyUI.Theme.Accent
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    local TitleLine = Instance.new("Frame")
    TitleLine.Size = UDim2.new(1, -20, 0, 1)
    TitleLine.Position = UDim2.new(0, 10, 0, 48)
    TitleLine.BackgroundColor3 = MyUI.Theme.Outline
    TitleLine.BorderSizePixel = 0
    TitleLine.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -12, 1, -100)
    TabContainer.Position = UDim2.new(0, 6, 0, 56)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 2
    TabContainer.ScrollBarImageColor3 = MyUI.Theme.Outline
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer

    -- Unload Button in Sidebar
    local DestructBtn = Instance.new("TextButton")
    DestructBtn.Name = "UnloadButton"
    DestructBtn.Size = UDim2.new(1, -20, 0, 32)
    DestructBtn.Position = UDim2.new(0, 10, 1, -40)
    DestructBtn.BackgroundColor3 = MyUI.Theme.Red
    DestructBtn.BackgroundTransparency = 0.85
    DestructBtn.Text = "✕ Unload UI"
    DestructBtn.TextColor3 = MyUI.Theme.Red
    DestructBtn.Font = Enum.Font.GothamBold
    DestructBtn.TextSize = 12
    DestructBtn.Parent = Sidebar
    CreateCorner(DestructBtn, 6)
    local DestructStroke = CreateStroke(DestructBtn, MyUI.Theme.Red, 1)
    DestructStroke.Transparency = 0.6

    DestructBtn.MouseEnter:Connect(function()
        Tween(DestructBtn, {BackgroundTransparency = 0.6}, 0.2)
        Tween(DestructStroke, {Transparency = 0.2}, 0.2)
    end)
    DestructBtn.MouseLeave:Connect(function()
        Tween(DestructBtn, {BackgroundTransparency = 0.85}, 0.2)
        Tween(DestructStroke, {Transparency = 0.6}, 0.2)
    end)
    DestructBtn.MouseButton1Click:Connect(function()
        MyUI:Unload()
    end)

    -- =====================================
    -- Content Area & Top Controls Setup
    -- =====================================
    local TopbarControls = Instance.new("Frame")
    TopbarControls.Size = UDim2.new(0, 60, 0, 30)
    TopbarControls.Position = UDim2.new(1, -65, 0, 8)
    TopbarControls.BackgroundTransparency = 1
    TopbarControls.ZIndex = 10
    TopbarControls.Parent = MainFrame

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    MinimizeBtn.Position = UDim2.new(0, 0, 0, 2)
    MinimizeBtn.BackgroundColor3 = MyUI.Theme.Element
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = MyUI.Theme.TextDark
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 16
    MinimizeBtn.Parent = TopbarControls
    CreateCorner(MinimizeBtn, 5)

    local CloseWindowBtn = Instance.new("TextButton")
    CloseWindowBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseWindowBtn.Position = UDim2.new(0, 30, 0, 2)
    CloseWindowBtn.BackgroundColor3 = MyUI.Theme.Element
    CloseWindowBtn.Text = "✕"
    CloseWindowBtn.TextColor3 = MyUI.Theme.TextDark
    CloseWindowBtn.Font = Enum.Font.GothamBold
    CloseWindowBtn.TextSize = 11
    CloseWindowBtn.Parent = TopbarControls
    CreateCorner(CloseWindowBtn, 5)

    MinimizeBtn.MouseEnter:Connect(function() Tween(MinimizeBtn, {TextColor3 = MyUI.Theme.Text}, 0.15) end)
    MinimizeBtn.MouseLeave:Connect(function() Tween(MinimizeBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.15) end)
    MinimizeBtn.MouseButton1Click:Connect(function() SetUIVisible(false) end)

    CloseWindowBtn.MouseEnter:Connect(function() Tween(CloseWindowBtn, {TextColor3 = MyUI.Theme.Red}, 0.15) end)
    CloseWindowBtn.MouseLeave:Connect(function() Tween(CloseWindowBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.15) end)
    CloseWindowBtn.MouseButton1Click:Connect(function() MyUI:Unload() end)

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -165, 1, 0)
    ContentArea.Position = UDim2.new(0, 165, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame

    local WindowObj = {}
    local CurrentTab = nil
    local FirstTab = true

    function WindowObj:CreateTab(tabName, iconId)
        tabName = tabName or "Tab"

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.BackgroundColor3 = FirstTab and MyUI.Theme.Accent or MyUI.Theme.Element
        TabBtn.BackgroundTransparency = FirstTab and 0 or 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabContainer
        CreateCorner(TabBtn, 6)

        -- Active Tab Indicator Pill
        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 3, 0, 18)
        Indicator.Position = UDim2.new(0, 3, 0.5, -9)
        Indicator.BackgroundColor3 = MyUI.Theme.Text
        Indicator.BackgroundTransparency = FirstTab and 0 or 1
        Indicator.BorderSizePixel = 0
        Indicator.Parent = TabBtn
        CreateCorner(Indicator, 2)

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 12, 0.5, -8)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = iconId or "rbxassetid://6031265976"
        TabIcon.ImageColor3 = FirstTab and Color3.fromRGB(255, 255, 255) or MyUI.Theme.TextDark
        TabIcon.Parent = TabBtn

        local TabText = Instance.new("TextLabel")
        TabText.Size = UDim2.new(1, -38, 1, 0)
        TabText.Position = UDim2.new(0, 34, 0, 0)
        TabText.BackgroundTransparency = 1
        TabText.Text = tabName
        TabText.TextColor3 = FirstTab and Color3.fromRGB(255, 255, 255) or MyUI.Theme.TextDark
        TabText.Font = Enum.Font.GothamSemibold
        TabText.TextSize = 13
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.Parent = TabBtn

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = "Page_" .. tabName
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.Position = UDim2.new(0, 0, 0, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = MyUI.Theme.Accent
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 16)
        PagePadding.PaddingRight = UDim.new(0, 16)
        PagePadding.PaddingTop = UDim.new(0, 42) -- Space below topbar buttons
        PagePadding.PaddingBottom = UDim.new(0, 16)
        PagePadding.Parent = TabPage

        local tabData = {
            Btn = TabBtn,
            Txt = TabText,
            Ico = TabIcon,
            Ind = Indicator,
            Page = TabPage
        }

        if FirstTab then
            CurrentTab = tabData
            FirstTab = false
        end

        local isSwitching = false
        TabBtn.MouseButton1Click:Connect(function()
            if CurrentTab.Btn == TabBtn or isSwitching then return end
            isSwitching = true

            if ActiveDropdownData then ActiveDropdownData.Close() end

            -- Deactivate previous tab
            Tween(CurrentTab.Btn, {BackgroundTransparency = 1}, 0.2)
            Tween(CurrentTab.Txt, {TextColor3 = MyUI.Theme.TextDark}, 0.2)
            Tween(CurrentTab.Ico, {ImageColor3 = MyUI.Theme.TextDark}, 0.2)
            Tween(CurrentTab.Ind, {BackgroundTransparency = 1}, 0.2)
            CurrentTab.Page.Visible = false

            -- Activate new tab
            CurrentTab = tabData
            Tween(TabBtn, {BackgroundTransparency = 0, BackgroundColor3 = MyUI.Theme.Accent}, 0.25)
            Tween(TabText, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.25)
            Tween(TabIcon, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.25)
            Tween(Indicator, {BackgroundTransparency = 0}, 0.25)

            TabPage.Visible = true
            TabPage.Position = UDim2.new(0, 10, 0, 0)
            Tween(TabPage, {Position = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Sine)

            task.delay(0.25, function()
                isSwitching = false
            end)
        end)

        local TabObj = {}

        -- =====================================
        -- Label Component (with :Set)
        -- =====================================
        function TabObj:CreateLabel(text)
            local LblFrame = Instance.new("Frame")
            LblFrame.Size = UDim2.new(1, 0, 0, 24)
            LblFrame.BackgroundTransparency = 1
            LblFrame.Parent = TabPage

            local LblText = Instance.new("TextLabel")
            LblText.Size = UDim2.new(1, 0, 1, 0)
            LblText.BackgroundTransparency = 1
            LblText.Text = tostring(text or "")
            LblText.TextColor3 = MyUI.Theme.TextDark
            LblText.Font = Enum.Font.GothamSemibold
            LblText.TextSize = 13
            LblText.TextXAlignment = Enum.TextXAlignment.Left
            LblText.Parent = LblFrame

            local LabelController = {}
            function LabelController:Set(newText)
                LblText.Text = tostring(newText or "")
            end
            return LabelController
        end

        -- =====================================
        -- Section Component
        -- =====================================
        function TabObj:CreateSection(sectionName)
            local SecFrame = Instance.new("Frame")
            SecFrame.Size = UDim2.new(1, 0, 0, 28)
            SecFrame.BackgroundTransparency = 1
            SecFrame.Parent = TabPage

            local SecText = Instance.new("TextLabel")
            SecText.Size = UDim2.new(1, 0, 0, 20)
            SecText.BackgroundTransparency = 1
            SecText.Text = tostring(sectionName or "Section")
            SecText.TextColor3 = MyUI.Theme.Accent
            SecText.Font = Enum.Font.GothamBold
            SecText.TextSize = 13
            SecText.TextXAlignment = Enum.TextXAlignment.Left
            SecText.Parent = SecFrame

            local SecLine = Instance.new("Frame")
            SecLine.Size = UDim2.new(1, 0, 0, 1)
            SecLine.Position = UDim2.new(0, 0, 1, -2)
            SecLine.BackgroundColor3 = MyUI.Theme.Outline
            SecLine.BorderSizePixel = 0
            SecLine.Parent = SecFrame
        end

        -- =====================================
        -- Paragraph Component (with :Set)
        -- =====================================
        function TabObj:CreateParagraph(title, desc)
            local PFrame = Instance.new("Frame")
            PFrame.Size = UDim2.new(1, 0, 0, 52)
            PFrame.BackgroundColor3 = MyUI.Theme.Element
            PFrame.Parent = TabPage
            CreateCorner(PFrame, 6)
            CreateStroke(PFrame, MyUI.Theme.Outline, 1)

            local PTitle = Instance.new("TextLabel")
            PTitle.Size = UDim2.new(1, -20, 0, 20)
            PTitle.Position = UDim2.new(0, 10, 0, 6)
            PTitle.BackgroundTransparency = 1
            PTitle.Text = tostring(title or "")
            PTitle.TextColor3 = MyUI.Theme.Text
            PTitle.Font = Enum.Font.GothamBold
            PTitle.TextSize = 13
            PTitle.TextXAlignment = Enum.TextXAlignment.Left
            PTitle.Parent = PFrame

            local PDesc = Instance.new("TextLabel")
            PDesc.Size = UDim2.new(1, -20, 0, 20)
            PDesc.Position = UDim2.new(0, 10, 0, 26)
            PDesc.BackgroundTransparency = 1
            PDesc.Text = tostring(desc or "")
            PDesc.TextColor3 = MyUI.Theme.TextDark
            PDesc.Font = Enum.Font.Gotham
            PDesc.TextSize = 12
            PDesc.TextXAlignment = Enum.TextXAlignment.Left
            PDesc.TextWrapped = true
            PDesc.Parent = PFrame

            local ParagraphController = {}
            function ParagraphController:Set(newTitle, newDesc)
                if newTitle then PTitle.Text = tostring(newTitle) end
                if newDesc then PDesc.Text = tostring(newDesc) end
            end
            return ParagraphController
        end

        -- =====================================
        -- Button Component
        -- =====================================
        function TabObj:CreateButton(opt)
            opt = opt or {}
            local btnName = opt.Name or "Button"
            local callback = opt.Callback or function() end

            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, 0, 0, 36)
            BtnFrame.BackgroundColor3 = MyUI.Theme.Element
            BtnFrame.Text = ""
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = TabPage
            CreateCorner(BtnFrame, 6)
            local Stroke = CreateStroke(BtnFrame, MyUI.Theme.Outline, 1)

            local BtnText = Instance.new("TextLabel")
            BtnText.Size = UDim2.new(1, -36, 1, 0)
            BtnText.Position = UDim2.new(0, 12, 0, 0)
            BtnText.BackgroundTransparency = 1
            BtnText.Text = btnName
            BtnText.TextColor3 = MyUI.Theme.Text
            BtnText.Font = Enum.Font.GothamSemibold
            BtnText.TextSize = 13
            BtnText.TextXAlignment = Enum.TextXAlignment.Left
            BtnText.Parent = BtnFrame

            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -26, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6031090666" -- Pointer/Click icon
            Icon.ImageColor3 = MyUI.Theme.TextDark
            Icon.Parent = BtnFrame

            BtnFrame.MouseEnter:Connect(function()
                Tween(BtnFrame, {BackgroundColor3 = MyUI.Theme.ElementHover}, 0.2)
                Tween(Stroke, {Color = MyUI.Theme.Accent}, 0.2)
                Tween(Icon, {ImageColor3 = MyUI.Theme.Accent}, 0.2)
            end)
            BtnFrame.MouseLeave:Connect(function()
                Tween(BtnFrame, {BackgroundColor3 = MyUI.Theme.Element}, 0.2)
                Tween(Stroke, {Color = MyUI.Theme.Outline}, 0.2)
                Tween(Icon, {ImageColor3 = MyUI.Theme.TextDark}, 0.2)
            end)
            BtnFrame.MouseButton1Down:Connect(function()
                Tween(BtnFrame, {Size = UDim2.new(1, -4, 0, 34)}, 0.08)
            end)
            BtnFrame.MouseButton1Up:Connect(function()
                Tween(BtnFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.08)
                task.spawn(callback)
            end)

            local ButtonController = {}
            function ButtonController:SetText(t)
                BtnText.Text = tostring(t)
            end
            return ButtonController
        end

        -- =====================================
        -- Toggle Component (with :Set and :GetValue)
        -- =====================================
        function TabObj:CreateToggle(opt)
            opt = opt or {}
            local tglName = opt.Name or "Toggle"
            local state = opt.CurrentValue == true
            local callback = opt.Callback or function() end

            local TglFrame = Instance.new("TextButton")
            TglFrame.Size = UDim2.new(1, 0, 0, 36)
            TglFrame.BackgroundColor3 = MyUI.Theme.Element
            TglFrame.Text = ""
            TglFrame.AutoButtonColor = false
            TglFrame.Parent = TabPage
            CreateCorner(TglFrame, 6)
            local Stroke = CreateStroke(TglFrame, MyUI.Theme.Outline, 1)

            local TglText = Instance.new("TextLabel")
            TglText.Size = UDim2.new(1, -60, 1, 0)
            TglText.Position = UDim2.new(0, 12, 0, 0)
            TglText.BackgroundTransparency = 1
            TglText.Text = tglName
            TglText.TextColor3 = MyUI.Theme.Text
            TglText.Font = Enum.Font.GothamSemibold
            TglText.TextSize = 13
            TglText.TextXAlignment = Enum.TextXAlignment.Left
            TglText.Parent = TglFrame

            local TglBg = Instance.new("Frame")
            TglBg.Size = UDim2.new(0, 38, 0, 20)
            TglBg.Position = UDim2.new(1, -48, 0.5, -10)
            TglBg.BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(44, 44, 58)
            TglBg.Parent = TglFrame
            CreateCorner(TglBg, 10)

            local TglCircle = Instance.new("Frame")
            TglCircle.Size = UDim2.new(0, 14, 0, 14)
            TglCircle.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            TglCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TglCircle.Parent = TglBg
            CreateCorner(TglCircle, 7)

            TglFrame.MouseEnter:Connect(function()
                Tween(TglFrame, {BackgroundColor3 = MyUI.Theme.ElementHover}, 0.2)
                Tween(Stroke, {Color = MyUI.Theme.Accent}, 0.2)
            end)
            TglFrame.MouseLeave:Connect(function()
                Tween(TglFrame, {BackgroundColor3 = MyUI.Theme.Element}, 0.2)
                Tween(Stroke, {Color = MyUI.Theme.Outline}, 0.2)
            end)

            local function updateToggle(newState, skipCallback)
                state = newState
                Tween(TglBg, {BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(44, 44, 58)}, 0.25)
                Tween(TglCircle, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}, 0.25, Enum.EasingStyle.Back)
                if not skipCallback then
                    task.spawn(callback, state)
                end
            end

            TglFrame.MouseButton1Click:Connect(function()
                updateToggle(not state)
            end)

            local ToggleController = {}
            function ToggleController:Set(val)
                updateToggle(val == true)
            end
            function ToggleController:GetValue()
                return state
            end
            return ToggleController
        end

        -- =====================================
        -- Slider Component (Leak-Free, :Set, :GetValue)
        -- =====================================
        function TabObj:CreateSlider(opt)
            opt = opt or {}
            local sldName = opt.Name or "Slider"
            local min = (opt.Range and opt.Range[1]) or 0
            local max = (opt.Range and opt.Range[2]) or 100
            local step = opt.Step or 1
            local val = math.clamp(opt.CurrentValue or min, min, max)
            local callback = opt.Callback or function() end

            local SldFrame = Instance.new("Frame")
            SldFrame.Size = UDim2.new(1, 0, 0, 48)
            SldFrame.BackgroundColor3 = MyUI.Theme.Element
            SldFrame.Parent = TabPage
            CreateCorner(SldFrame, 6)
            local Stroke = CreateStroke(SldFrame, MyUI.Theme.Outline, 1)

            local SldText = Instance.new("TextLabel")
            SldText.Size = UDim2.new(1, -70, 0, 22)
            SldText.Position = UDim2.new(0, 12, 0, 4)
            SldText.BackgroundTransparency = 1
            SldText.Text = sldName
            SldText.TextColor3 = MyUI.Theme.Text
            SldText.Font = Enum.Font.GothamSemibold
            SldText.TextSize = 13
            SldText.TextXAlignment = Enum.TextXAlignment.Left
            SldText.Parent = SldFrame

            local ValText = Instance.new("TextBox")
            ValText.Size = UDim2.new(0, 48, 0, 20)
            ValText.Position = UDim2.new(1, -58, 0, 5)
            ValText.BackgroundColor3 = MyUI.Theme.Topbar
            ValText.Text = tostring(val)
            ValText.TextColor3 = MyUI.Theme.Accent
            ValText.Font = Enum.Font.GothamBold
            ValText.TextSize = 12
            ValText.Parent = SldFrame
            CreateCorner(ValText, 4)
            CreateStroke(ValText, MyUI.Theme.Outline, 1)

            local BarBg = Instance.new("TextButton")
            BarBg.Size = UDim2.new(1, -24, 0, 6)
            BarBg.Position = UDim2.new(0, 12, 0, 32)
            BarBg.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
            BarBg.Text = ""
            BarBg.AutoButtonColor = false
            BarBg.Parent = SldFrame
            CreateCorner(BarBg, 3)

            local rangeDelta = max - min
            local startPct = rangeDelta > 0 and math.clamp((val - min) / rangeDelta, 0, 1) or 0

            local BarBg = Instance.new("TextButton")
            BarBg.Size = UDim2.new(1, -24, 0, 14)
            BarBg.Position = UDim2.new(0, 12, 0, 28)
            BarBg.BackgroundTransparency = 1
            BarBg.Text = ""
            BarBg.AutoButtonColor = false
            BarBg.Parent = SldFrame

            local BarTrack = Instance.new("Frame")
            BarTrack.Size = UDim2.new(1, 0, 0, 6)
            BarTrack.Position = UDim2.new(0, 0, 0.5, -3)
            BarTrack.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
            BarTrack.BorderSizePixel = 0
            BarTrack.Parent = BarBg
            CreateCorner(BarTrack, 3)

            local BarFill = Instance.new("Frame")
            BarFill.Size = UDim2.new(startPct, 0, 1, 0)
            BarFill.BackgroundColor3 = MyUI.Theme.Accent
            BarFill.BorderSizePixel = 0
            BarFill.Parent = BarTrack
            CreateCorner(BarFill, 3)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 12, 0, 12)
            Knob.Position = UDim2.new(1, -6, 0.5, -6)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = BarFill
            CreateCorner(Knob, 6)

            local moveConn, releaseConn
            local function endSliding()
                if moveConn then moveConn:Disconnect(); moveConn = nil end
                if releaseConn then releaseConn:Disconnect(); releaseConn = nil end
                Tween(Knob, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.15)
            end

            local function updateSliderFromInput(inputX)
                local relX = math.clamp(inputX - BarTrack.AbsolutePosition.X, 0, BarTrack.AbsoluteSize.X)
                local pct = BarTrack.AbsoluteSize.X > 0 and (relX / BarTrack.AbsoluteSize.X) or 0
                local rawVal = min + (rangeDelta * pct)
                local steppedVal = math.floor((rawVal / step) + 0.5) * step
                val = math.clamp(steppedVal, min, max)

                -- Format precision cleanly
                if step < 1 then
                    ValText.Text = string.format("%.2f", val)
                else
                    ValText.Text = tostring(math.floor(val))
                end

                local cleanPct = rangeDelta > 0 and math.clamp((val - min) / rangeDelta, 0, 1) or 0
                Tween(BarFill, {Size = UDim2.new(cleanPct, 0, 1, 0)}, 0.08)
                task.spawn(callback, val)
            end

            BarBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Tween(Knob, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)}, 0.15)
                    updateSliderFromInput(input.Position.X)

                    endSliding()
                    moveConn = TrackConnection(UserInputService.InputChanged:Connect(function(moveInput)
                        if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                            updateSliderFromInput(moveInput.Position.X)
                        end
                    end))
                    releaseConn = TrackConnection(UserInputService.InputEnded:Connect(function(endInput)
                        if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                            endSliding()
                        end
                    end))
                end
            end)

            ValText.FocusLost:Connect(function()
                local num = tonumber(ValText.Text)
                if num then
                    val = math.clamp(num, min, max)
                    ValText.Text = tostring(val)
                    local pct = rangeDelta > 0 and math.clamp((val - min) / rangeDelta, 0, 1) or 0
                    Tween(BarFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
                    task.spawn(callback, val)
                else
                    ValText.Text = tostring(val)
                end
            end)

            local SliderController = {}
            function SliderController:Set(newVal)
                val = math.clamp(newVal or min, min, max)
                ValText.Text = tostring(val)
                local pct = rangeDelta > 0 and math.clamp((val - min) / rangeDelta, 0, 1) or 0
                Tween(BarFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
                task.spawn(callback, val)
            end
            function SliderController:GetValue()
                return val
            end
            return SliderController
        end

        -- =====================================
        -- Dropdown Component (Multi-Select, :Refresh, :Set)
        -- =====================================
        function TabObj:CreateDropdown(opt)
            opt = opt or {}
            local dropName = opt.Name or "Dropdown"
            local list = opt.Options or {}
            local multi = opt.MultiSelection == true
            local current = opt.CurrentOption or (multi and {} or (list[1] or ""))
            if multi and type(current) ~= "table" then
                current = {current}
            end
            local callback = opt.Callback or function() end

            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, 0, 0, 38)
            DropFrame.BackgroundColor3 = MyUI.Theme.Element
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = TabPage
            CreateCorner(DropFrame, 6)
            local Stroke = CreateStroke(DropFrame, MyUI.Theme.Outline, 1)

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(1, 0, 0, 38)
            DropBtn.BackgroundTransparency = 1
            DropBtn.Text = ""
            DropBtn.Parent = DropFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -40, 1, 0)
            TitleLabel.Position = UDim2.new(0, 12, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.GothamSemibold
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = DropBtn

            local function updateTitleDisplay()
                if not multi then
                    TitleLabel.Text = dropName .. " : " .. tostring(current)
                else
                    if #current == 0 then
                        TitleLabel.Text = dropName .. " : None"
                    else
                        TitleLabel.Text = dropName .. " : " .. table.concat(current, ", ")
                    end
                end
            end
            updateTitleDisplay()

            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -26, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6031091004" -- Down arrow
            Icon.ImageColor3 = MyUI.Theme.TextDark
            Icon.Parent = DropBtn

            local DropList = Instance.new("ScrollingFrame")
            DropList.Size = UDim2.new(1, -20, 1, -44)
            DropList.Position = UDim2.new(0, 10, 0, 40)
            DropList.BackgroundTransparency = 1
            DropList.ScrollBarThickness = 2
            DropList.ScrollBarImageColor3 = MyUI.Theme.Accent
            DropList.AutomaticCanvasSize = Enum.AutomaticSize.Y
            DropList.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropList.Parent = DropFrame

            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 4)
            ListLayout.Parent = DropList

            local open = false
            local function closeDropdown()
                if not open then return end
                open = false
                if ActiveDropdownData and ActiveDropdownData.Close == closeDropdown then
                    ActiveDropdownData = nil
                end
                Tween(Icon, {Rotation = 0}, 0.2)
                Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.25, Enum.EasingStyle.Quart)
            end

            local function toggleDropdown()
                open = not open
                if open then
                    if ActiveDropdownData and ActiveDropdownData.Close ~= closeDropdown then
                        ActiveDropdownData.Close()
                    end
                    ActiveDropdownData = { Close = closeDropdown, Frame = DropFrame }

                    local count = #list
                    local contentHeight = math.clamp(count * 32, 34, 150)
                    Tween(Icon, {Rotation = 180}, 0.2)
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 44 + contentHeight)}, 0.3, Enum.EasingStyle.Quart)
                else
                    closeDropdown()
                end
            end

            DropBtn.MouseButton1Click:Connect(toggleDropdown)

            local optionButtons = {}
            local function rebuildList()
                for _, child in ipairs(DropList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                optionButtons = {}

                for _, item in ipairs(list) do
                    local isSelected = false
                    if multi then
                        isSelected = table.find(current, item) ~= nil
                    else
                        isSelected = (current == item)
                    end

                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 28)
                    OptBtn.BackgroundColor3 = isSelected and MyUI.Theme.Topbar or MyUI.Theme.ElementHover
                    OptBtn.Text = "  " .. tostring(item)
                    OptBtn.TextColor3 = isSelected and MyUI.Theme.Accent or MyUI.Theme.TextDark
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.TextSize = 12
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.Parent = DropList
                    CreateCorner(OptBtn, 4)

                    OptBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(current, item)
                            if idx then
                                table.remove(current, idx)
                                Tween(OptBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.15)
                            else
                                table.insert(current, item)
                                Tween(OptBtn, {TextColor3 = MyUI.Theme.Accent}, 0.15)
                            end
                            updateTitleDisplay()
                            task.spawn(callback, current)
                        else
                            current = item
                            for _, btn in pairs(optionButtons) do
                                Tween(btn, {TextColor3 = MyUI.Theme.TextDark}, 0.15)
                            end
                            Tween(OptBtn, {TextColor3 = MyUI.Theme.Accent}, 0.15)
                            updateTitleDisplay()
                            closeDropdown()
                            task.spawn(callback, current)
                        end
                    end)

                    optionButtons[item] = OptBtn
                end
            end
            rebuildList()

            local DropdownController = {}
            function DropdownController:Refresh(newList, defaultOpt)
                list = newList or {}
                if defaultOpt ~= nil then
                    current = defaultOpt
                elseif not multi then
                    current = list[1] or ""
                end
                updateTitleDisplay()
                rebuildList()
                if open then
                    local count = #list
                    local contentHeight = math.clamp(count * 32, 34, 150)
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 44 + contentHeight)}, 0.2, Enum.EasingStyle.Quart)
                end
            end
            function DropdownController:Set(newVal)
                if multi then
                    if type(newVal) == "table" then
                        current = newVal
                    elseif newVal ~= nil then
                        current = {newVal}
                    else
                        current = {}
                    end
                else
                    current = newVal ~= nil and newVal or ""
                end
                updateTitleDisplay()
                rebuildList()
                task.spawn(callback, current)
            end
            function DropdownController:GetValue()
                return current
            end
            return DropdownController
        end

        -- =====================================
        -- Input (TextBox) Component [NEW]
        -- =====================================
        function TabObj:CreateInput(opt)
            opt = opt or {}
            local inputName = opt.Name or "Input"
            local placeholder = opt.PlaceholderText or "Type here..."
            local clearOnFocus = opt.ClearTextOnFocus or false
            local callback = opt.Callback or function() end
            local value = opt.Default or ""

            local InpFrame = Instance.new("Frame")
            InpFrame.Size = UDim2.new(1, 0, 0, 42)
            InpFrame.BackgroundColor3 = MyUI.Theme.Element
            InpFrame.Parent = TabPage
            CreateCorner(InpFrame, 6)
            local Stroke = CreateStroke(InpFrame, MyUI.Theme.Outline, 1)

            local InpTitle = Instance.new("TextLabel")
            InpTitle.Size = UDim2.new(0.4, 0, 1, 0)
            InpTitle.Position = UDim2.new(0, 12, 0, 0)
            InpTitle.BackgroundTransparency = 1
            InpTitle.Text = inputName
            InpTitle.TextColor3 = MyUI.Theme.Text
            InpTitle.Font = Enum.Font.GothamSemibold
            InpTitle.TextSize = 13
            InpTitle.TextXAlignment = Enum.TextXAlignment.Left
            InpTitle.Parent = InpFrame

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0.55, -12, 0, 26)
            Box.Position = UDim2.new(0.45, 0, 0.5, -13)
            Box.BackgroundColor3 = MyUI.Theme.Topbar
            Box.Text = value
            Box.PlaceholderText = placeholder
            Box.PlaceholderColor3 = MyUI.Theme.TextDark
            Box.TextColor3 = MyUI.Theme.Text
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Box.ClearTextOnFocus = clearOnFocus
            Box.Parent = InpFrame
            CreateCorner(Box, 4)
            local BoxStroke = CreateStroke(Box, MyUI.Theme.Outline, 1)

            Box.Focused:Connect(function()
                Tween(BoxStroke, {Color = MyUI.Theme.Accent}, 0.2)
            end)
            Box.FocusLost:Connect(function(enterPressed)
                Tween(BoxStroke, {Color = MyUI.Theme.Outline}, 0.2)
                value = Box.Text
                task.spawn(callback, value, enterPressed)
            end)

            local InputController = {}
            function InputController:Set(newText)
                value = tostring(newText or "")
                Box.Text = value
                task.spawn(callback, value, true)
            end
            function InputController:GetValue()
                return Box.Text
            end
            return InputController
        end

        -- =====================================
        -- Keybind Component [NEW]
        -- =====================================
        function TabObj:CreateKeybind(opt)
            opt = opt or {}
            local bindName = opt.Name or "Keybind"
            local currentKey = opt.CurrentKey or Enum.KeyCode.E
            local callback = opt.Callback or function() end
            local listening = false

            local KbFrame = Instance.new("Frame")
            KbFrame.Size = UDim2.new(1, 0, 0, 38)
            KbFrame.BackgroundColor3 = MyUI.Theme.Element
            KbFrame.Parent = TabPage
            CreateCorner(KbFrame, 6)
            local Stroke = CreateStroke(KbFrame, MyUI.Theme.Outline, 1)

            local KbText = Instance.new("TextLabel")
            KbText.Size = UDim2.new(1, -110, 1, 0)
            KbText.Position = UDim2.new(0, 12, 0, 0)
            KbText.BackgroundTransparency = 1
            KbText.Text = bindName
            KbText.TextColor3 = MyUI.Theme.Text
            KbText.Font = Enum.Font.GothamSemibold
            KbText.TextSize = 13
            KbText.TextXAlignment = Enum.TextXAlignment.Left
            KbText.Parent = KbFrame

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.new(0, 90, 0, 24)
            KeyBtn.Position = UDim2.new(1, -98, 0.5, -12)
            KeyBtn.BackgroundColor3 = MyUI.Theme.Topbar
            KeyBtn.Text = currentKey.Name
            KeyBtn.TextColor3 = MyUI.Theme.Accent
            KeyBtn.Font = Enum.Font.GothamBold
            KeyBtn.TextSize = 12
            KeyBtn.Parent = KbFrame
            CreateCorner(KeyBtn, 4)
            local KeyStroke = CreateStroke(KeyBtn, MyUI.Theme.Outline, 1)

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                KeyBtn.Text = "..."
                Tween(KeyStroke, {Color = MyUI.Theme.Accent}, 0.2)

                local bindConn
                bindConn = TrackConnection(UserInputService.InputBegan:Connect(function(input, gp)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        bindConn:Disconnect()
                        listening = false
                        Tween(KeyStroke, {Color = MyUI.Theme.Outline}, 0.2)
                        if input.KeyCode ~= Enum.KeyCode.Escape then
                            currentKey = input.KeyCode
                            KeyBtn.Text = currentKey.Name
                            task.spawn(callback, currentKey)
                        else
                            KeyBtn.Text = currentKey.Name
                        end
                    end
                end))
            end)

            local KeybindController = {}
            function KeybindController:Set(newKey)
                if typeof(newKey) == "EnumItem" then
                    currentKey = newKey
                    KeyBtn.Text = currentKey.Name
                    task.spawn(callback, currentKey)
                end
            end
            function KeybindController:GetValue()
                return currentKey
            end
            return KeybindController
        end

        return TabObj
    end

    function WindowObj:Unload()
        MyUI:Unload()
    end

    return WindowObj
end

return MyUI
