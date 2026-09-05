local MyUI = {}
MyUI.UnloadCallbacks = {}

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Mouse = Players.LocalPlayer:GetMouse()

-- =====================================
-- Theme Engine
-- =====================================
MyUI.Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 25),
    Topbar = Color3.fromRGB(20, 20, 25),
    Element = Color3.fromRGB(25, 25, 30),
    ElementHover = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(85, 120, 255),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(130, 130, 140),
    Outline = Color3.fromRGB(45, 45, 55),
    Red = Color3.fromRGB(255, 75, 75)
}

-- =====================================
-- Utility Functions
-- =====================================
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

-- =====================================
-- Unload System
-- =====================================
function MyUI:OnUnload(callback)
    table.insert(self.UnloadCallbacks, callback)
end

local function UnloadLibrary()
    for _, cb in ipairs(MyUI.UnloadCallbacks) do
        pcall(cb)
    end
    if CoreGui:FindFirstChild("MyCustomUI_ScreenV2") then
        CoreGui:FindFirstChild("MyCustomUI_ScreenV2"):Destroy()
    end
end

-- =====================================
-- Main Window
-- =====================================
function MyUI:CreateWindow(options)
    local WindowName = options.Name or "Premium Hub V2"
    local ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    
    UnloadLibrary() -- Destroy existing instances first
    MyUI.UnloadCallbacks = {} -- Reset callbacks

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MyCustomUI_ScreenV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = (gethui and gethui()) or CoreGui

    -- =====================================
    -- Notification System V2
    -- =====================================
    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Size = UDim2.new(0, 300, 1, -40)
    NotifContainer.Position = UDim2.new(1, -320, 0, 20)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Parent = ScreenGui

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.Padding = UDim.new(0, 10)
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.Parent = NotifContainer

    function MyUI:Notify(title, text, duration)
        duration = duration or 3
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(1, 0, 0, 0)
        NotifFrame.BackgroundColor3 = MyUI.Theme.Sidebar
        NotifFrame.BackgroundTransparency = 0.1
        NotifFrame.ClipsDescendants = true
        NotifFrame.Parent = NotifContainer
        
        CreateCorner(NotifFrame, 8)
        CreateStroke(NotifFrame, MyUI.Theme.Outline, 1)

        local NTitle = Instance.new("TextLabel")
        NTitle.Size = UDim2.new(1, -20, 0, 25)
        NTitle.Position = UDim2.new(0, 10, 0, 5)
        NTitle.BackgroundTransparency = 1
        NTitle.Text = title
        NTitle.TextColor3 = MyUI.Theme.Accent
        NTitle.Font = Enum.Font.GothamBold
        NTitle.TextSize = 14
        NTitle.TextXAlignment = Enum.TextXAlignment.Left
        NTitle.Parent = NotifFrame

        local NText = Instance.new("TextLabel")
        NText.Size = UDim2.new(1, -20, 0, 25)
        NText.Position = UDim2.new(0, 10, 0, 30)
        NText.BackgroundTransparency = 1
        NText.Text = text
        NText.TextColor3 = MyUI.Theme.Text
        NText.Font = Enum.Font.Gotham
        NText.TextSize = 13
        NText.TextXAlignment = Enum.TextXAlignment.Left
        NText.TextWrapped = true
        NText.Parent = NotifFrame
        
        local Bar = Instance.new("Frame")
        Bar.Size = UDim2.new(1, 0, 0, 3)
        Bar.Position = UDim2.new(0, 0, 1, -3)
        Bar.BackgroundColor3 = MyUI.Theme.Accent
        Bar.BorderSizePixel = 0
        Bar.Parent = NotifFrame
        CreateCorner(Bar, 3)

        -- Animate In
        Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 65)}, 0.4, Enum.EasingStyle.Back)
        Tween(Bar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)

        task.spawn(function()
            task.wait(duration)
            -- Animate Out
            Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Sine)
            task.wait(0.3)
            NotifFrame:Destroy()
        end)
    end

    -- =====================================
    -- Main Window Setup
    -- =====================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 650, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
    MainFrame.BackgroundColor3 = MyUI.Theme.Background
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    CreateCorner(MainFrame, 10)
    local MainStroke = CreateStroke(MainFrame, MyUI.Theme.Outline, 1)
    
    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Name = "DropShadow"
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 5)
    DropShadow.Size = UDim2.new(1, 40, 1, 40)
    DropShadow.ZIndex = 0
    DropShadow.Image = "rbxassetid://5554236805"
    DropShadow.ImageColor3 = Color3.fromRGB(0,0,0)
    DropShadow.ImageTransparency = 0.5
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(23,23,277,277)
    DropShadow.Parent = MainFrame

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.Y - MainFrame.AbsolutePosition.Y < 50 then -- Only drag from top 50px
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(MainFrame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08, Enum.EasingStyle.Sine)
        end
    end)

    -- Toggle Logic
    local uiToggled = true
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == ToggleKey then
            uiToggled = not uiToggled
            if uiToggled then
                MainFrame.Visible = true
                Tween(MainFrame, {Size = UDim2.new(0, 650, 0, 450), BackgroundTransparency = 0.05}, 0.4, Enum.EasingStyle.Back)
                Tween(MainStroke, {Transparency = 0}, 0.2)
            else
                Tween(MainFrame, {Size = UDim2.new(0, 650, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Sine)
                Tween(MainStroke, {Transparency = 1}, 0.2)
                task.wait(0.3)
                MainFrame.Visible = false
            end
        end
    end)

    -- =====================================
    -- Sidebar Setup
    -- =====================================
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = MyUI.Theme.Sidebar
    Sidebar.BackgroundTransparency = 0.2
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarLine = Instance.new("Frame")
    SidebarLine.Size = UDim2.new(0, 1, 1, 0)
    SidebarLine.Position = UDim2.new(1, -1, 0, 0)
    SidebarLine.BackgroundColor3 = MyUI.Theme.Outline
    SidebarLine.BorderSizePixel = 0
    SidebarLine.Parent = Sidebar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 50)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowName
    TitleLabel.TextColor3 = MyUI.Theme.Accent
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    local TitleLine = Instance.new("Frame")
    TitleLine.Size = UDim2.new(1, -20, 0, 1)
    TitleLine.Position = UDim2.new(0, 10, 0, 50)
    TitleLine.BackgroundColor3 = MyUI.Theme.Outline
    TitleLine.BorderSizePixel = 0
    TitleLine.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -10, 1, -120)
    TabContainer.Position = UDim2.new(0, 5, 0, 60)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 2
    TabContainer.ScrollBarImageColor3 = MyUI.Theme.Accent
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Destruct Button in Sidebar
    local DestructBtn = Instance.new("TextButton")
    DestructBtn.Size = UDim2.new(1, -20, 0, 35)
    DestructBtn.Position = UDim2.new(0, 10, 1, -45)
    DestructBtn.BackgroundColor3 = MyUI.Theme.Red
    DestructBtn.BackgroundTransparency = 0.8
    DestructBtn.Text = "Unload UI"
    DestructBtn.TextColor3 = MyUI.Theme.Red
    DestructBtn.Font = Enum.Font.GothamBold
    DestructBtn.TextSize = 13
    DestructBtn.Parent = Sidebar
    CreateCorner(DestructBtn, 6)
    local DestructStroke = CreateStroke(DestructBtn, MyUI.Theme.Red, 1)
    DestructStroke.Transparency = 0.5
    
    DestructBtn.MouseEnter:Connect(function() Tween(DestructBtn, {BackgroundTransparency = 0.5}, 0.2) end)
    DestructBtn.MouseLeave:Connect(function() Tween(DestructBtn, {BackgroundTransparency = 0.8}, 0.2) end)
    DestructBtn.MouseButton1Click:Connect(function()
        UnloadLibrary()
    end)

    -- =====================================
    -- Content Area Setup
    -- =====================================
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -160, 1, 0)
    ContentArea.Position = UDim2.new(0, 160, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame

    local WindowObj = {}
    local CurrentTab = nil
    local FirstTab = true

    function WindowObj:CreateTab(tabName, iconId)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -10, 0, 35)
        TabBtn.Position = UDim2.new(0, 5, 0, 0)
        TabBtn.BackgroundColor3 = FirstTab and MyUI.Theme.Accent or MyUI.Theme.Element
        TabBtn.BackgroundTransparency = FirstTab and 0 or 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabContainer
        CreateCorner(TabBtn, 6)

        local TabText = Instance.new("TextLabel")
        TabText.Size = UDim2.new(1, -35, 1, 0)
        TabText.Position = UDim2.new(0, 30, 0, 0)
        TabText.BackgroundTransparency = 1
        TabText.Text = tabName
        TabText.TextColor3 = FirstTab and Color3.fromRGB(255,255,255) or MyUI.Theme.TextDark
        TabText.Font = Enum.Font.GothamSemibold
        TabText.TextSize = 13
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 8, 0.5, -8)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = iconId or "rbxassetid://6031265976" -- Default dot icon
        TabIcon.ImageColor3 = FirstTab and Color3.fromRGB(255,255,255) or MyUI.Theme.TextDark
        TabIcon.Parent = TabBtn

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.Position = FirstTab and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = MyUI.Theme.Accent
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 15)
        PagePadding.PaddingRight = UDim.new(0, 15)
        PagePadding.PaddingTop = UDim.new(0, 15)
        PagePadding.PaddingBottom = UDim.new(0, 15)
        PagePadding.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 30)
        end)

        if FirstTab then CurrentTab = {Btn = TabBtn, Txt = TabText, Ico = TabIcon, Page = TabPage}; FirstTab = false end

        TabBtn.MouseButton1Click:Connect(function()
            if CurrentTab.Btn == TabBtn then return end
            
            -- Hide old
            Tween(CurrentTab.Btn, {BackgroundTransparency = 1}, 0.2)
            Tween(CurrentTab.Txt, {TextColor3 = MyUI.Theme.TextDark}, 0.2)
            Tween(CurrentTab.Ico, {ImageColor3 = MyUI.Theme.TextDark}, 0.2)
            local oldPage = CurrentTab.Page
            Tween(oldPage, {Position = UDim2.new(0, 0, -1, 0)}, 0.3, Enum.EasingStyle.Sine)
            task.delay(0.3, function() oldPage.Visible = false end)

            -- Show new
            CurrentTab = {Btn = TabBtn, Txt = TabText, Ico = TabIcon, Page = TabPage}
            Tween(TabBtn, {BackgroundTransparency = 0, BackgroundColor3 = MyUI.Theme.Accent}, 0.3)
            Tween(TabText, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.3)
            Tween(TabIcon, {ImageColor3 = Color3.fromRGB(255,255,255)}, 0.3)
            
            TabPage.Visible = true
            TabPage.Position = UDim2.new(0, 0, 1, 0)
            Tween(TabPage, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)
        end)

        local TabObj = {}

        -- =====================================
        -- Section
        -- =====================================
        function TabObj:CreateSection(sectionName)
            local SecFrame = Instance.new("Frame")
            SecFrame.Size = UDim2.new(1, 0, 0, 30)
            SecFrame.BackgroundTransparency = 1
            SecFrame.Parent = TabPage

            local SecText = Instance.new("TextLabel")
            SecText.Size = UDim2.new(1, 0, 1, 0)
            SecText.BackgroundTransparency = 1
            SecText.Text = sectionName
            SecText.TextColor3 = MyUI.Theme.Accent
            SecText.Font = Enum.Font.GothamBold
            SecText.TextSize = 14
            SecText.TextXAlignment = Enum.TextXAlignment.Left
            SecText.Parent = SecFrame

            local SecLine = Instance.new("Frame")
            SecLine.Size = UDim2.new(1, 0, 0, 1)
            SecLine.Position = UDim2.new(0, 0, 1, -5)
            SecLine.BackgroundColor3 = MyUI.Theme.Outline
            SecLine.BorderSizePixel = 0
            SecLine.Parent = SecFrame
        end

        -- =====================================
        -- Paragraph
        -- =====================================
        function TabObj:CreateParagraph(title, desc)
            local PFrame = Instance.new("Frame")
            PFrame.Size = UDim2.new(1, 0, 0, 50)
            PFrame.BackgroundColor3 = MyUI.Theme.Element
            PFrame.Parent = TabPage
            CreateCorner(PFrame, 6)
            CreateStroke(PFrame, MyUI.Theme.Outline, 1)

            local PTitle = Instance.new("TextLabel")
            PTitle.Size = UDim2.new(1, -20, 0, 20)
            PTitle.Position = UDim2.new(0, 10, 0, 5)
            PTitle.BackgroundTransparency = 1
            PTitle.Text = title
            PTitle.TextColor3 = MyUI.Theme.Text
            PTitle.Font = Enum.Font.GothamBold
            PTitle.TextSize = 13
            PTitle.TextXAlignment = Enum.TextXAlignment.Left
            PTitle.Parent = PFrame

            local PDesc = Instance.new("TextLabel")
            PDesc.Size = UDim2.new(1, -20, 0, 20)
            PDesc.Position = UDim2.new(0, 10, 0, 25)
            PDesc.BackgroundTransparency = 1
            PDesc.Text = desc
            PDesc.TextColor3 = MyUI.Theme.TextDark
            PDesc.Font = Enum.Font.Gotham
            PDesc.TextSize = 12
            PDesc.TextXAlignment = Enum.TextXAlignment.Left
            PDesc.TextWrapped = true
            PDesc.Parent = PFrame
        end

        -- =====================================
        -- Button
        -- =====================================
        function TabObj:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end

            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, 0, 0, 38)
            BtnFrame.BackgroundColor3 = MyUI.Theme.Element
            BtnFrame.Text = ""
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = TabPage
            CreateCorner(BtnFrame, 6)
            local Stroke = CreateStroke(BtnFrame, MyUI.Theme.Outline, 1)

            local BtnText = Instance.new("TextLabel")
            BtnText.Size = UDim2.new(1, -20, 1, 0)
            BtnText.Position = UDim2.new(0, 10, 0, 0)
            BtnText.BackgroundTransparency = 1
            BtnText.Text = btnName
            BtnText.TextColor3 = MyUI.Theme.Text
            BtnText.Font = Enum.Font.Gotham
            BtnText.TextSize = 13
            BtnText.TextXAlignment = Enum.TextXAlignment.Center
            BtnText.Parent = BtnFrame
            
            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -26, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6031090666" -- Pointer icon
            Icon.ImageColor3 = MyUI.Theme.TextDark
            Icon.Parent = BtnFrame

            BtnFrame.MouseEnter:Connect(function() Tween(BtnFrame, {BackgroundColor3 = MyUI.Theme.ElementHover}, 0.2); Tween(Stroke, {Color = MyUI.Theme.Accent}, 0.2) end)
            BtnFrame.MouseLeave:Connect(function() Tween(BtnFrame, {BackgroundColor3 = MyUI.Theme.Element}, 0.2); Tween(Stroke, {Color = MyUI.Theme.Outline}, 0.2) end)
            BtnFrame.MouseButton1Down:Connect(function() Tween(BtnFrame, {Size = UDim2.new(1, -4, 0, 34)}, 0.1) end)
            BtnFrame.MouseButton1Up:Connect(function() Tween(BtnFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.1); task.spawn(callback) end)
        end

        -- =====================================
        -- Toggle
        -- =====================================
        function TabObj:CreateToggle(options)
            local tglName = options.Name or "Toggle"
            local state = options.CurrentValue or false
            local callback = options.Callback or function() end

            local TglFrame = Instance.new("TextButton")
            TglFrame.Size = UDim2.new(1, 0, 0, 38)
            TglFrame.BackgroundColor3 = MyUI.Theme.Element
            TglFrame.Text = ""
            TglFrame.AutoButtonColor = false
            TglFrame.Parent = TabPage
            CreateCorner(TglFrame, 6)
            local Stroke = CreateStroke(TglFrame, MyUI.Theme.Outline, 1)

            local TglText = Instance.new("TextLabel")
            TglText.Size = UDim2.new(1, -60, 1, 0)
            TglText.Position = UDim2.new(0, 10, 0, 0)
            TglText.BackgroundTransparency = 1
            TglText.Text = tglName
            TglText.TextColor3 = MyUI.Theme.Text
            TglText.Font = Enum.Font.Gotham
            TglText.TextSize = 13
            TglText.TextXAlignment = Enum.TextXAlignment.Left
            TglText.Parent = TglFrame

            local TglBg = Instance.new("Frame")
            TglBg.Size = UDim2.new(0, 36, 0, 18)
            TglBg.Position = UDim2.new(1, -46, 0.5, -9)
            TglBg.BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(45, 45, 50)
            TglBg.Parent = TglFrame
            CreateCorner(TglBg, 9)

            local TglCircle = Instance.new("Frame")
            TglCircle.Size = UDim2.new(0, 14, 0, 14)
            TglCircle.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            TglCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TglCircle.Parent = TglBg
            CreateCorner(TglCircle, 7)

            TglFrame.MouseEnter:Connect(function() Tween(TglFrame, {BackgroundColor3 = MyUI.Theme.ElementHover}, 0.2); Tween(Stroke, {Color = MyUI.Theme.Accent}, 0.2) end)
            TglFrame.MouseLeave:Connect(function() Tween(TglFrame, {BackgroundColor3 = MyUI.Theme.Element}, 0.2); Tween(Stroke, {Color = MyUI.Theme.Outline}, 0.2) end)

            TglFrame.MouseButton1Click:Connect(function()
                state = not state
                task.spawn(callback, state)
                Tween(TglBg, {BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(45, 45, 50)}, 0.3)
                Tween(TglCircle, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.3, Enum.EasingStyle.Back)
            end)
        end

        -- =====================================
        -- Slider
        -- =====================================
        function TabObj:CreateSlider(options)
            local sldName = options.Name or "Slider"
            local min = options.Range[1] or 0
            local max = options.Range[2] or 100
            local val = options.CurrentValue or min
            local callback = options.Callback or function() end

            local SldFrame = Instance.new("Frame")
            SldFrame.Size = UDim2.new(1, 0, 0, 50)
            SldFrame.BackgroundColor3 = MyUI.Theme.Element
            SldFrame.Parent = TabPage
            CreateCorner(SldFrame, 6)
            CreateStroke(SldFrame, MyUI.Theme.Outline, 1)

            local SldText = Instance.new("TextLabel")
            SldText.Size = UDim2.new(1, -60, 0, 25)
            SldText.Position = UDim2.new(0, 10, 0, 2)
            SldText.BackgroundTransparency = 1
            SldText.Text = sldName
            SldText.TextColor3 = MyUI.Theme.Text
            SldText.Font = Enum.Font.Gotham
            SldText.TextSize = 13
            SldText.TextXAlignment = Enum.TextXAlignment.Left
            SldText.Parent = SldFrame

            local ValText = Instance.new("TextBox")
            ValText.Size = UDim2.new(0, 40, 0, 20)
            ValText.Position = UDim2.new(1, -50, 0, 5)
            ValText.BackgroundColor3 = MyUI.Theme.Topbar
            ValText.Text = tostring(val)
            ValText.TextColor3 = MyUI.Theme.Accent
            ValText.Font = Enum.Font.GothamBold
            ValText.TextSize = 12
            ValText.Parent = SldFrame
            CreateCorner(ValText, 4)

            local BarBg = Instance.new("TextButton")
            BarBg.Size = UDim2.new(1, -20, 0, 6)
            BarBg.Position = UDim2.new(0, 10, 0, 35)
            BarBg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            BarBg.Text = ""
            BarBg.AutoButtonColor = false
            BarBg.Parent = SldFrame
            CreateCorner(BarBg, 3)

            local startPct = math.clamp((val - min) / (max - min), 0, 1)
            local BarFill = Instance.new("Frame")
            BarFill.Size = UDim2.new(startPct, 0, 1, 0)
            BarFill.BackgroundColor3 = MyUI.Theme.Accent
            BarFill.Parent = BarBg
            CreateCorner(BarFill, 3)

            local sliding = false
            local function update(input)
                local relX = math.clamp(input.Position.X - BarBg.AbsolutePosition.X, 0, BarBg.AbsoluteSize.X)
                local pct = relX / BarBg.AbsoluteSize.X
                val = math.floor(min + ((max - min) * pct))
                ValText.Text = tostring(val)
                Tween(BarFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1)
                task.spawn(callback, val)
            end

            BarBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)

            ValText.FocusLost:Connect(function()
                local num = tonumber(ValText.Text)
                if num then
                    val = math.clamp(num, min, max)
                    ValText.Text = tostring(val)
                    local pct = (val - min) / (max - min)
                    Tween(BarFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
                    task.spawn(callback, val)
                else
                    ValText.Text = tostring(val)
                end
            end)
        end

        -- =====================================
        -- Dropdown (Supports Multi-Select)
        -- =====================================
        function TabObj:CreateDropdown(options)
            local dropName = options.Name or "Dropdown"
            local list = options.Options or {}
            local multi = options.MultiSelection or false
            local current = options.CurrentOption or (multi and {} or "")
            local callback = options.Callback or function() end

            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, 0, 0, 42)
            DropFrame.BackgroundColor3 = MyUI.Theme.Element
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = TabPage
            CreateCorner(DropFrame, 6)
            local Stroke = CreateStroke(DropFrame, MyUI.Theme.Outline, 1)

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(1, 0, 0, 42)
            DropBtn.BackgroundTransparency = 1
            DropBtn.Text = ""
            DropBtn.Parent = DropFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -40, 1, 0)
            TitleLabel.Position = UDim2.new(0, 10, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            local function getTitleStr()
                if not multi then return dropName .. " : " .. tostring(current) end
                if #current == 0 then return dropName .. " : None" end
                return dropName .. " : " .. table.concat(current, ", ")
            end
            TitleLabel.Text = getTitleStr()
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = DropBtn

            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -26, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6031091004" -- Down arrow
            Icon.ImageColor3 = MyUI.Theme.TextDark
            Icon.Parent = DropBtn

            local DropList = Instance.new("ScrollingFrame")
            DropList.Size = UDim2.new(1, -20, 1, -46)
            DropList.Position = UDim2.new(0, 10, 0, 42)
            DropList.BackgroundTransparency = 1
            DropList.ScrollBarThickness = 2
            DropList.ScrollBarImageColor3 = MyUI.Theme.Accent
            DropList.Parent = DropFrame

            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 4)
            ListLayout.Parent = DropList

            local open = false
            DropBtn.MouseButton1Click:Connect(function()
                open = not open
                Tween(Icon, {Rotation = open and 180 or 0}, 0.2)
                
                local count = #DropList:GetChildren() - 1
                local listSize = math.clamp(count * 30 + (count - 1) * 4, 0, 150)
                
                if open then
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42 + listSize + 10)}, 0.3, Enum.EasingStyle.Quart)
                else
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart)
                end
            end)

            for _, v in pairs(list) do
                local isSelected = false
                if multi then
                    isSelected = table.find(current, v) ~= nil
                else
                    isSelected = (current == v)
                end

                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, -10, 0, 30)
                OptBtn.BackgroundColor3 = MyUI.Theme.Topbar
                OptBtn.Text = "  " .. tostring(v)
                OptBtn.TextColor3 = isSelected and MyUI.Theme.Accent or MyUI.Theme.TextDark
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextSize = 13
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.Parent = DropList
                CreateCorner(OptBtn, 4)

                OptBtn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = table.find(current, v)
                        if idx then
                            table.remove(current, idx)
                            Tween(OptBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.2)
                        else
                            table.insert(current, v)
                            Tween(OptBtn, {TextColor3 = MyUI.Theme.Accent}, 0.2)
                        end
                        TitleLabel.Text = getTitleStr()
                        task.spawn(callback, current)
                    else
                        current = v
                        for _, sibling in pairs(DropList:GetChildren()) do
                            if sibling:IsA("TextButton") then
                                Tween(sibling, {TextColor3 = MyUI.Theme.TextDark}, 0.2)
                            end
                        end
                        Tween(OptBtn, {TextColor3 = MyUI.Theme.Accent}, 0.2)
                        TitleLabel.Text = getTitleStr()
                        open = false
                        Tween(Icon, {Rotation = 0}, 0.2)
                        Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart)
                        task.spawn(callback, current)
                    end
                end)
            end
            
            ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                DropList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
            end)
        end

        return TabObj
    end

    return WindowObj
end

return MyUI
