local MyUI = {}
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Modern Dark Theme with Blue Accent
MyUI.Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Topbar = Color3.fromRGB(20, 20, 25),
    TabListBg = Color3.fromRGB(25, 25, 30),
    TabButton = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(65, 130, 255), -- Blue Accent
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(140, 140, 150),
    ElementBackground = Color3.fromRGB(25, 25, 30),
    ElementHover = Color3.fromRGB(35, 35, 40),
    Outline = Color3.fromRGB(45, 45, 55),
    ToggleDisabled = Color3.fromRGB(45, 45, 50),
    DropdownBg = Color3.fromRGB(20, 20, 25),
}

-- Utility function for creating tweens easily
local function Tween(obj, props, time, style, dir)
    time = time or 0.2
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
    tw:Play()
    return tw
end

-- Create rounded corners
local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- Create stroke (border)
local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or MyUI.Theme.Outline
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function MyUI:CreateWindow(options)
    local WindowName = options.Name or "Premium UI Hub"
    local ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    
    if CoreGui:FindFirstChild("MyCustomUI_Screen") then
        CoreGui:FindFirstChild("MyCustomUI_Screen"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MyCustomUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = (gethui and gethui()) or CoreGui

    -- Main Notification Container
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

    -- Notification Function (Accessible Globally)
    function MyUI:Notify(title, text, duration)
        duration = duration or 3
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(1, 0, 0, 60)
        NotifFrame.BackgroundColor3 = MyUI.Theme.Topbar
        NotifFrame.BackgroundTransparency = 1
        NotifFrame.Position = UDim2.new(1, 50, 0, 0)
        NotifFrame.Parent = NotifContainer
        
        CreateCorner(NotifFrame, 8)
        local NotifStroke = CreateStroke(NotifFrame, MyUI.Theme.Accent, 1)
        NotifStroke.Transparency = 1

        local NTitle = Instance.new("TextLabel")
        NTitle.Size = UDim2.new(1, -20, 0, 25)
        NTitle.Position = UDim2.new(0, 10, 0, 5)
        NTitle.BackgroundTransparency = 1
        NTitle.Text = title
        NTitle.TextColor3 = MyUI.Theme.Accent
        NTitle.TextTransparency = 1
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
        NText.TextTransparency = 1
        NText.Font = Enum.Font.Gotham
        NText.TextSize = 13
        NText.TextXAlignment = Enum.TextXAlignment.Left
        NText.TextWrapped = true
        NText.Parent = NotifFrame

        -- Animation In
        Tween(NotifFrame, {BackgroundTransparency = 0.1, Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)
        Tween(NotifStroke, {Transparency = 0}, 0.4)
        Tween(NTitle, {TextTransparency = 0}, 0.4)
        Tween(NText, {TextTransparency = 0}, 0.4)

        task.spawn(function()
            task.wait(duration)
            -- Animation Out
            Tween(NotifFrame, {BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Tween(NotifStroke, {Transparency = 1}, 0.4)
            Tween(NTitle, {TextTransparency = 1}, 0.4)
            Tween(NText, {TextTransparency = 1}, 0.4)
            task.wait(0.4)
            NotifFrame:Destroy()
        end)
    end

    -- =====================================
    -- Main Window Setup
    -- =====================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 560, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
    MainFrame.BackgroundColor3 = MyUI.Theme.Background
    MainFrame.BackgroundTransparency = 0.05 -- Slight blur/acrylic feel
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    CreateCorner(MainFrame, 12)
    CreateStroke(MainFrame, MyUI.Theme.Outline, 1)

    -- Optional DropShadow simulation
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.ZIndex = 0
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    Shadow.ImageTransparency = 0.4
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23,23,277,277)
    Shadow.Parent = MainFrame

    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 45)
    Topbar.BackgroundColor3 = MyUI.Theme.Topbar
    Topbar.BackgroundTransparency = 0.1
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 12)
    TopbarCorner.Parent = Topbar
    
    local CornerRepair = Instance.new("Frame")
    CornerRepair.Size = UDim2.new(1, 0, 0, 12)
    CornerRepair.Position = UDim2.new(0, 0, 1, -12)
    CornerRepair.BackgroundColor3 = MyUI.Theme.Topbar
    CornerRepair.BackgroundTransparency = 0.1
    CornerRepair.BorderSizePixel = 0
    CornerRepair.Parent = Topbar
    
    local TopbarLine = Instance.new("Frame")
    TopbarLine.Size = UDim2.new(1, 0, 0, 1)
    TopbarLine.Position = UDim2.new(0, 0, 1, 0)
    TopbarLine.BackgroundColor3 = MyUI.Theme.Outline
    TopbarLine.BorderSizePixel = 0
    TopbarLine.Parent = Topbar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowName
    TitleLabel.TextColor3 = MyUI.Theme.Accent
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    -- Glow on title
    local TitleGlow = TitleLabel:Clone()
    TitleGlow.TextTransparency = 0.6
    TitleGlow.Position = UDim2.new(0, 21, 0, 1)
    TitleGlow.ZIndex = 0
    TitleGlow.Parent = Topbar

    -- Close Button (Optional visually, acts as hide)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = MyUI.Theme.TextDark
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = Topbar

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Color3.fromRGB(255, 100, 100)}, 0.2) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.2) end)
    CloseBtn.MouseButton1Click:Connect(function() 
        Tween(MainFrame, {Size = UDim2.new(0, 560, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        MainFrame.Visible = false
    end)

    -- Dragging System
    local dragging, dragInput, dragStart, startPos
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(MainFrame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08, Enum.EasingStyle.Sine)
        end
    end)

    -- Toggle Hotkey
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == ToggleKey then
            if MainFrame.Visible then
                Tween(MainFrame, {Size = UDim2.new(0, 560, 0, 0), BackgroundTransparency = 1}, 0.3)
                task.wait(0.3)
                MainFrame.Visible = false
            else
                MainFrame.Visible = true
                Tween(MainFrame, {Size = UDim2.new(0, 560, 0, 420), BackgroundTransparency = 0.05}, 0.4, Enum.EasingStyle.Back)
            end
        end
    end)

    -- Tab System Setup
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(0, 140, 1, -45)
    TabList.Position = UDim2.new(0, 0, 0, 45)
    TabList.BackgroundColor3 = MyUI.Theme.TabListBg
    TabList.BackgroundTransparency = 0.2
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageColor3 = MyUI.Theme.Accent
    TabList.Parent = MainFrame

    local TabListLine = Instance.new("Frame")
    TabListLine.Size = UDim2.new(0, 1, 1, 0)
    TabListLine.Position = UDim2.new(1, 0, 0, 0)
    TabListLine.BackgroundColor3 = MyUI.Theme.Outline
    TabListLine.BorderSizePixel = 0
    TabListLine.Parent = TabList

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.Parent = TabList

    local TabListPadding = Instance.new("UIPadding")
    TabListPadding.PaddingLeft = UDim.new(0, 8)
    TabListPadding.PaddingRight = UDim.new(0, 8)
    TabListPadding.PaddingTop = UDim.new(0, 10)
    TabListPadding.Parent = TabList

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -145, 1, -45)
    ContentContainer.Position = UDim2.new(0, 145, 0, 45)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local WindowObj = {}
    local FirstTab = true

    function WindowObj:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 34)
        TabButton.BackgroundColor3 = FirstTab and MyUI.Theme.Accent or MyUI.Theme.TabButton
        TabButton.BackgroundTransparency = FirstTab and 0 or 0.5
        TabButton.Text = "  " .. tabName
        TabButton.TextColor3 = FirstTab and Color3.fromRGB(255,255,255) or MyUI.Theme.TextDark
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 14
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabList
        
        CreateCorner(TabButton, 6)

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Size = UDim2.new(0, 3, 0, 18)
        TabIndicator.Position = UDim2.new(0, 4, 0.5, -9)
        TabIndicator.BackgroundColor3 = Color3.fromRGB(255,255,255)
        TabIndicator.BackgroundTransparency = FirstTab and 0 or 1
        TabIndicator.Parent = TabButton
        CreateCorner(TabIndicator, 2)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, 0, 1, -10)
        TabPage.Position = UDim2.new(0, 0, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = MyUI.Theme.Accent
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = TabPage
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 5)
        PagePadding.PaddingRight = UDim.new(0, 15)
        PagePadding.PaddingTop = UDim.new(0, 2)
        PagePadding.PaddingBottom = UDim.new(0, 10)
        PagePadding.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)
        TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 20)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, btn in ipairs(TabList:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = MyUI.Theme.TabButton, BackgroundTransparency = 0.5}, 0.3)
                    Tween(btn, {TextColor3 = MyUI.Theme.TextDark}, 0.3)
                    local ind = btn:FindFirstChild("Frame")
                    if ind then Tween(ind, {BackgroundTransparency = 1}, 0.3) end
                end
            end
            Tween(TabButton, {BackgroundColor3 = MyUI.Theme.Accent, BackgroundTransparency = 0}, 0.3)
            Tween(TabButton, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.3)
            Tween(TabIndicator, {BackgroundTransparency = 0}, 0.3)

            for _, page in ipairs(ContentContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then
                    page.Visible = false
                    page.Position = UDim2.new(0, 20, 0, 10)
                end
            end
            TabPage.Visible = true
            Tween(TabPage, {Position = UDim2.new(0, 0, 0, 10)}, 0.4, Enum.EasingStyle.Back)
        end)

        if FirstTab then FirstTab = false end
        local TabObj = {}

        -- Label
        function TabObj:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = TabPage

            local LabelText = Instance.new("TextLabel")
            LabelText.Size = UDim2.new(1, 0, 1, 0)
            LabelText.BackgroundTransparency = 1
            LabelText.Text = text
            LabelText.TextColor3 = MyUI.Theme.TextDark
            LabelText.Font = Enum.Font.GothamSemibold
            LabelText.TextSize = 14
            LabelText.TextXAlignment = Enum.TextXAlignment.Left
            LabelText.Parent = LabelFrame
        end

        -- Button
        function TabObj:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end

            local ButtonFrame = Instance.new("TextButton")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 38)
            ButtonFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            ButtonFrame.Text = ""
            ButtonFrame.AutoButtonColor = false
            ButtonFrame.Parent = TabPage

            CreateCorner(ButtonFrame, 6)
            local BtnStroke = CreateStroke(ButtonFrame, MyUI.Theme.Outline, 1)

            local BtnText = Instance.new("TextLabel")
            BtnText.Size = UDim2.new(1, -20, 1, 0)
            BtnText.Position = UDim2.new(0, 10, 0, 0)
            BtnText.BackgroundTransparency = 1
            BtnText.Text = btnName
            BtnText.TextColor3 = MyUI.Theme.Text
            BtnText.Font = Enum.Font.Gotham
            BtnText.TextSize = 14
            BtnText.TextXAlignment = Enum.TextXAlignment.Center
            BtnText.Parent = ButtonFrame

            ButtonFrame.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = MyUI.Theme.ElementHover}, 0.2)
                Tween(BtnStroke, {Color = MyUI.Theme.Accent}, 0.2)
            end)
            ButtonFrame.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = MyUI.Theme.ElementBackground}, 0.2)
                Tween(BtnStroke, {Color = MyUI.Theme.Outline}, 0.2)
            end)
            ButtonFrame.MouseButton1Down:Connect(function()
                Tween(ButtonFrame, {Size = UDim2.new(1, -4, 0, 34)}, 0.1)
            end)
            ButtonFrame.MouseButton1Up:Connect(function()
                Tween(ButtonFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.1)
                task.spawn(callback)
            end)
        end

        -- Toggle
        function TabObj:CreateToggle(options)
            local tglName = options.Name or "Toggle"
            local callback = options.Callback or function() end
            local state = options.CurrentValue or false

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            ToggleFrame.Text = ""
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Parent = TabPage

            CreateCorner(ToggleFrame, 6)
            local TglStroke = CreateStroke(ToggleFrame, MyUI.Theme.Outline, 1)

            local TglText = Instance.new("TextLabel")
            TglText.Size = UDim2.new(1, -60, 1, 0)
            TglText.Position = UDim2.new(0, 10, 0, 0)
            TglText.BackgroundTransparency = 1
            TglText.Text = tglName
            TglText.TextColor3 = MyUI.Theme.Text
            TglText.Font = Enum.Font.Gotham
            TglText.TextSize = 14
            TglText.TextXAlignment = Enum.TextXAlignment.Left
            TglText.Parent = ToggleFrame

            local ToggleCheck = Instance.new("Frame")
            ToggleCheck.Size = UDim2.new(0, 42, 0, 22)
            ToggleCheck.Position = UDim2.new(1, -52, 0.5, -11)
            ToggleCheck.BackgroundColor3 = state and MyUI.Theme.Accent or MyUI.Theme.ToggleDisabled
            ToggleCheck.Parent = ToggleFrame
            CreateCorner(ToggleCheck, 11)

            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
            ToggleCircle.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.Parent = ToggleCheck
            CreateCorner(ToggleCircle, 9)

            ToggleFrame.MouseEnter:Connect(function() Tween(TglStroke, {Color = MyUI.Theme.Accent}, 0.2) end)
            ToggleFrame.MouseLeave:Connect(function() Tween(TglStroke, {Color = MyUI.Theme.Outline}, 0.2) end)

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                task.spawn(callback, state)
                
                Tween(ToggleCheck, {BackgroundColor3 = state and MyUI.Theme.Accent or MyUI.Theme.ToggleDisabled}, 0.2)
                Tween(ToggleCircle, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.3, Enum.EasingStyle.Back)
            end)
        end

        -- Slider
        function TabObj:CreateSlider(options)
            local sldName = options.Name or "Slider"
            local min = options.Range and options.Range[1] or 0
            local max = options.Range and options.Range[2] or 100
            local default = options.CurrentValue or min
            local callback = options.Callback or function() end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 56)
            SliderFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            SliderFrame.Parent = TabPage

            CreateCorner(SliderFrame, 6)
            CreateStroke(SliderFrame, MyUI.Theme.Outline, 1)

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -60, 0, 24)
            TitleLabel.Position = UDim2.new(0, 10, 0, 6)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = sldName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = SliderFrame

            local ValueBox = Instance.new("TextBox")
            ValueBox.Size = UDim2.new(0, 40, 0, 20)
            ValueBox.Position = UDim2.new(1, -50, 0, 8)
            ValueBox.BackgroundColor3 = MyUI.Theme.Topbar
            ValueBox.Text = tostring(default)
            ValueBox.TextColor3 = MyUI.Theme.Accent
            ValueBox.Font = Enum.Font.GothamBold
            ValueBox.TextSize = 13
            ValueBox.Parent = SliderFrame
            CreateCorner(ValueBox, 4)

            local SliderBarBg = Instance.new("TextButton")
            SliderBarBg.Size = UDim2.new(1, -20, 0, 6)
            SliderBarBg.Position = UDim2.new(0, 10, 0, 40)
            SliderBarBg.BackgroundColor3 = MyUI.Theme.ToggleDisabled
            SliderBarBg.Text = ""
            SliderBarBg.AutoButtonColor = false
            SliderBarBg.Parent = SliderFrame
            CreateCorner(SliderBarBg, 3)

            local startScale = math.clamp((default - min) / (max - min), 0, 1)
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(startScale, 0, 1, 0)
            SliderFill.BackgroundColor3 = MyUI.Theme.Accent
            SliderFill.Parent = SliderBarBg
            CreateCorner(SliderFill, 3)

            local sliding = false
            local function updateSlider(input)
                local relativeX = math.clamp(input.Position.X - SliderBarBg.AbsolutePosition.X, 0, SliderBarBg.AbsoluteSize.X)
                local pos = relativeX / SliderBarBg.AbsoluteSize.X
                local value = math.floor(min + ((max - min) * pos))
                ValueBox.Text = tostring(value)
                Tween(SliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
                task.spawn(callback, value)
            end

            SliderBarBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            ValueBox.FocusLost:Connect(function()
                local num = tonumber(ValueBox.Text)
                if num then
                    num = math.clamp(num, min, max)
                    ValueBox.Text = tostring(num)
                    local pos = (num - min) / (max - min)
                    Tween(SliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.2)
                    task.spawn(callback, num)
                else
                    ValueBox.Text = tostring(default)
                end
            end)
        end

        -- TextBox
        function TabObj:CreateInput(options)
            local inpName = options.Name or "TextBox"
            local placeholder = options.PlaceholderText or "Type here..."
            local callback = options.Callback or function() end

            local InputFrame = Instance.new("Frame")
            InputFrame.Size = UDim2.new(1, 0, 0, 42)
            InputFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            InputFrame.Parent = TabPage

            CreateCorner(InputFrame, 6)
            local InpStroke = CreateStroke(InputFrame, MyUI.Theme.Outline, 1)

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(0, 120, 1, 0)
            TitleLabel.Position = UDim2.new(0, 10, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = inpName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = InputFrame

            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -140, 0, 26)
            TextBox.Position = UDim2.new(0, 130, 0, 8)
            TextBox.BackgroundColor3 = MyUI.Theme.Topbar
            TextBox.PlaceholderText = placeholder
            TextBox.Text = ""
            TextBox.TextColor3 = MyUI.Theme.Text
            TextBox.Font = Enum.Font.Gotham
            TextBox.TextSize = 13
            TextBox.Parent = InputFrame
            CreateCorner(TextBox, 4)

            InputFrame.MouseEnter:Connect(function() Tween(InpStroke, {Color = MyUI.Theme.Accent}, 0.2) end)
            InputFrame.MouseLeave:Connect(function() Tween(InpStroke, {Color = MyUI.Theme.Outline}, 0.2) end)

            TextBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    task.spawn(callback, TextBox.Text)
                end
            end)
        end

        -- Dropdown
        function TabObj:CreateDropdown(options)
            local dropName = options.Name or "Dropdown"
            local list = options.Options or {}
            local callback = options.Callback or function() end

            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, 0, 0, 42)
            DropFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = TabPage

            CreateCorner(DropFrame, 6)
            local DropStroke = CreateStroke(DropFrame, MyUI.Theme.Outline, 1)

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(1, 0, 0, 42)
            DropBtn.BackgroundTransparency = 1
            DropBtn.Text = ""
            DropBtn.Parent = DropFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -40, 1, 0)
            TitleLabel.Position = UDim2.new(0, 10, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = dropName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = DropBtn

            local Icon = Instance.new("TextLabel")
            Icon.Size = UDim2.new(0, 20, 0, 20)
            Icon.Position = UDim2.new(1, -30, 0.5, -10)
            Icon.BackgroundTransparency = 1
            Icon.Text = "+"
            Icon.TextColor3 = MyUI.Theme.TextDark
            Icon.Font = Enum.Font.GothamBold
            Icon.TextSize = 16
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
                Tween(Icon, {Rotation = open and 45 or 0}, 0.2)
                
                local count = #DropList:GetChildren() - 1
                local listSize = math.clamp(count * 30 + (count - 1) * 4, 0, 150)
                
                if open then
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42 + listSize + 10)}, 0.3, Enum.EasingStyle.Quart)
                else
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart)
                end
            end)

            for i, v in pairs(list) do
                local OptionBtn = Instance.new("TextButton")
                OptionBtn.Size = UDim2.new(1, -10, 0, 30)
                OptionBtn.BackgroundColor3 = MyUI.Theme.DropdownBg
                OptionBtn.Text = "  " .. tostring(v)
                OptionBtn.TextColor3 = MyUI.Theme.TextDark
                OptionBtn.Font = Enum.Font.Gotham
                OptionBtn.TextSize = 13
                OptionBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptionBtn.Parent = DropList
                CreateCorner(OptionBtn, 4)

                OptionBtn.MouseEnter:Connect(function() Tween(OptionBtn, {TextColor3 = MyUI.Theme.Accent}, 0.2) end)
                OptionBtn.MouseLeave:Connect(function() Tween(OptionBtn, {TextColor3 = MyUI.Theme.TextDark}, 0.2) end)

                OptionBtn.MouseButton1Click:Connect(function()
                    TitleLabel.Text = dropName .. " : " .. tostring(v)
                    open = false
                    Tween(Icon, {Rotation = 0}, 0.2)
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart)
                    task.spawn(callback, v)
                end)
            end
            
            ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                DropList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
            end)
        end

        -- Keybind
        function TabObj:CreateKeybind(options)
            local keyName = options.Name or "Keybind"
            local default = options.CurrentKey or Enum.KeyCode.E
            local callback = options.Callback or function() end

            local KeyFrame = Instance.new("Frame")
            KeyFrame.Size = UDim2.new(1, 0, 0, 42)
            KeyFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            KeyFrame.Parent = TabPage

            CreateCorner(KeyFrame, 6)
            local KeyStroke = CreateStroke(KeyFrame, MyUI.Theme.Outline, 1)

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -100, 1, 0)
            TitleLabel.Position = UDim2.new(0, 10, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = keyName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = KeyFrame

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.new(0, 80, 0, 26)
            KeyBtn.Position = UDim2.new(1, -90, 0, 8)
            KeyBtn.BackgroundColor3 = MyUI.Theme.Topbar
            KeyBtn.Text = default.Name
            KeyBtn.TextColor3 = MyUI.Theme.Accent
            KeyBtn.Font = Enum.Font.GothamBold
            KeyBtn.TextSize = 13
            KeyBtn.Parent = KeyFrame
            CreateCorner(KeyBtn, 4)

            local binding = false
            local currentKey = default

            KeyBtn.MouseButton1Click:Connect(function()
                binding = true
                KeyBtn.Text = "..."
                Tween(KeyBtn, {BackgroundColor3 = MyUI.Theme.Accent, TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
            end)

            UserInputService.InputBegan:Connect(function(input, gp)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    currentKey = input.KeyCode
                    KeyBtn.Text = currentKey.Name
                    Tween(KeyBtn, {BackgroundColor3 = MyUI.Theme.Topbar, TextColor3 = MyUI.Theme.Accent}, 0.2)
                elseif not gp and input.KeyCode == currentKey and not binding then
                    task.spawn(callback)
                end
            end)
        end

        return TabObj
    end

    return WindowObj
end

return MyUI
