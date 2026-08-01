local MyUI = {}
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ระบบ Theme ใหม่ สวยขึ้น โทนสีมืด (Dark Mode) ตัดด้วยสีฟ้า (Accent)
MyUI.Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Topbar = Color3.fromRGB(25, 25, 30),
    TabListBg = Color3.fromRGB(30, 30, 35),
    TabButton = Color3.fromRGB(40, 40, 45),
    Accent = Color3.fromRGB(85, 170, 255), -- สีฟ้าสว่าง
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(160, 160, 170),
    ElementBackground = Color3.fromRGB(35, 35, 40),
    ElementHover = Color3.fromRGB(45, 45, 50),
    Outline = Color3.fromRGB(50, 50, 60), -- เส้นขอบ
    ToggleDisabled = Color3.fromRGB(50, 50, 60),
}

function MyUI:CreateWindow(options)
    local WindowName = options.Name or "My Premium UI"
    
    if CoreGui:FindFirstChild("MyCustomUI_Screen") then
        CoreGui:FindFirstChild("MyCustomUI_Screen"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MyCustomUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = (gethui and gethui()) or CoreGui

    -- =====================================
    -- วาดหน้าต่างหลัก (MainFrame)
    -- =====================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
    MainFrame.BackgroundColor3 = MyUI.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10) -- ขอบมนขึ้น
    UICorner.Parent = MainFrame
    
    -- ใส่เส้นขอบหน้าต่าง (UIStroke) เพื่อความพรีเมียม
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = MyUI.Theme.Outline
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    -- แถบ Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.BackgroundColor3 = MyUI.Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 10)
    TopbarCorner.Parent = Topbar
    
    local CornerRepair = Instance.new("Frame")
    CornerRepair.Size = UDim2.new(1, 0, 0, 10)
    CornerRepair.Position = UDim2.new(0, 0, 1, -10)
    CornerRepair.BackgroundColor3 = MyUI.Theme.Topbar
    CornerRepair.BorderSizePixel = 0
    CornerRepair.Parent = Topbar
    
    -- เส้นกั้นระหว่าง Topbar กับ TabList
    local TopbarLine = Instance.new("Frame")
    TopbarLine.Size = UDim2.new(1, 0, 0, 1)
    TopbarLine.Position = UDim2.new(0, 0, 1, 0)
    TopbarLine.BackgroundColor3 = MyUI.Theme.Outline
    TopbarLine.BorderSizePixel = 0
    TopbarLine.Parent = Topbar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -30, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowName
    TitleLabel.TextColor3 = MyUI.Theme.Text
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    -- ระบบลากหน้าต่าง (Drag)
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
            TweenService:Create(MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    -- ปุ่มย่อ/ขยาย (ปุ่มลัดคีย์บอร์ด)
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- =====================================
    -- สร้างปุ่มลอยสำหรับเปิด/ปิด UI (Mobile / Toggle Button)
    -- =====================================
    local MobileBtn = Instance.new("TextButton")
    MobileBtn.Size = UDim2.new(0, 50, 0, 50)
    MobileBtn.Position = UDim2.new(0, 20, 0, 20)
    MobileBtn.BackgroundColor3 = MyUI.Theme.Topbar
    MobileBtn.Text = "UI"
    MobileBtn.TextColor3 = MyUI.Theme.Accent
    MobileBtn.Font = Enum.Font.GothamBlack
    MobileBtn.TextSize = 18
    MobileBtn.Parent = ScreenGui
    
    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(1, 0) -- เป็นวงกลม
    MobileCorner.Parent = MobileBtn
    
    local MobileStroke = Instance.new("UIStroke")
    MobileStroke.Color = MyUI.Theme.Outline
    MobileStroke.Thickness = 2
    MobileStroke.Parent = MobileBtn

    -- ระบบแยกการ "ลาก (Drag)" กับการ "คลิก (Click)" ของปุ่มลอย
    local btnDragging = false
    local btnDragStart
    local btnStartPos
    local btnHasMoved = false

    MobileBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            btnDragging = true
            btnHasMoved = false
            btnDragStart = input.Position
            btnStartPos = MobileBtn.Position
            -- อนิเมชั่นตอนกด
            TweenService:Create(MobileBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 45, 0, 45)}):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - btnDragStart
            if delta.Magnitude > 5 then
                btnHasMoved = true -- ถ้าเลื่อนเกิน 5 pixel ถือว่าลาก ไม่ใช่คลิก
            end
            MobileBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if btnDragging then
                btnDragging = false
                TweenService:Create(MobileBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 50)}):Play()
                
                if not btnHasMoved then
                    -- ถ้าไม่ได้ลาก แต่แค่กดคลิก ให้เปิด/ปิด UI
                    MainFrame.Visible = not MainFrame.Visible
                end
            end
        end
    end)

    -- =====================================
    -- แถบ TabList
    -- =====================================
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 0, 40)
    TabList.Position = UDim2.new(0, 0, 0, 40)
    TabList.BackgroundColor3 = MyUI.Theme.TabListBg
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.ScrollingDirection = Enum.ScrollingDirection.X
    TabList.Parent = MainFrame

    local TabListLine = Instance.new("Frame")
    TabListLine.Size = UDim2.new(1, 0, 0, 1)
    TabListLine.Position = UDim2.new(0, 0, 1, 0)
    TabListLine.BackgroundColor3 = MyUI.Theme.Outline
    TabListLine.BorderSizePixel = 0
    TabListLine.Parent = TabList

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 8)
    TabListLayout.Parent = TabList

    local TabListPadding = Instance.new("UIPadding")
    TabListPadding.PaddingLeft = UDim.new(0, 10)
    TabListPadding.PaddingTop = UDim.new(0, 6)
    TabListPadding.Parent = TabList

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, TabListLayout.AbsoluteContentSize.X + 20, 0, 0)
    end)

    -- พื้นที่แสดงเนื้อหา
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, -80)
    ContentContainer.Position = UDim2.new(0, 0, 0, 80)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local WindowObj = {}
    local FirstTab = true

    function WindowObj:CreateTab(tabName)
        local tabName = tabName or "Tab"
        
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 100, 1, -6)
        TabButton.BackgroundColor3 = FirstTab and MyUI.Theme.Accent or MyUI.Theme.TabButton
        TabButton.Text = tabName
        TabButton.TextColor3 = MyUI.Theme.Text
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.Parent = TabList
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabButton
        
        TabButton.Size = UDim2.new(0, TabButton.TextBounds.X + 30, 1, -6)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = MyUI.Theme.Accent
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = TabPage
        
        -- ระยะห่างขอบ
        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 2)
        PagePadding.PaddingRight = UDim.new(0, 2)
        PagePadding.PaddingTop = UDim.new(0, 2)
        PagePadding.PaddingBottom = UDim.new(0, 2)
        PagePadding.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, btn in ipairs(TabList:GetChildren()) do
                if btn:IsA("TextButton") then
                    TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = MyUI.Theme.TabButton}):Play()
                end
            end
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundColor3 = MyUI.Theme.Accent}):Play()

            for _, page in ipairs(ContentContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then
                    page.Visible = false
                end
            end
            TabPage.Visible = true
        end)

        if FirstTab then FirstTab = false end
        local TabObj = {}

        -- =====================================
        -- วาด Button
        -- =====================================
        function TabObj:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end

            local ButtonFrame = Instance.new("TextButton")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 38)
            ButtonFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            ButtonFrame.Text = "   " .. btnName
            ButtonFrame.TextColor3 = MyUI.Theme.Text
            ButtonFrame.Font = Enum.Font.Gotham
            ButtonFrame.TextSize = 14
            ButtonFrame.TextXAlignment = Enum.TextXAlignment.Left
            ButtonFrame.Parent = TabPage

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 6)
            BtnCorner.Parent = ButtonFrame
            
            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = MyUI.Theme.Outline
            BtnStroke.Thickness = 1
            BtnStroke.Parent = ButtonFrame

            ButtonFrame.MouseEnter:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = MyUI.Theme.ElementHover}):Play()
            end)
            ButtonFrame.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = MyUI.Theme.ElementBackground}):Play()
            end)

            ButtonFrame.MouseButton1Click:Connect(function()
                pcall(callback)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, -6, 0, 34)}):Play()
                wait(0.1)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 38)}):Play()
            end)
        end

        -- =====================================
        -- วาด Toggle
        -- =====================================
        function TabObj:CreateToggle(options)
            local tglName = options.Name or "Toggle"
            local callback = options.Callback or function() end
            local state = options.CurrentValue or false

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            ToggleFrame.Text = "   " .. tglName
            ToggleFrame.TextColor3 = MyUI.Theme.Text
            ToggleFrame.Font = Enum.Font.Gotham
            ToggleFrame.TextSize = 14
            ToggleFrame.TextXAlignment = Enum.TextXAlignment.Left
            ToggleFrame.Parent = TabPage

            local TglCorner = Instance.new("UICorner")
            TglCorner.CornerRadius = UDim.new(0, 6)
            TglCorner.Parent = ToggleFrame
            
            local TglStroke = Instance.new("UIStroke")
            TglStroke.Color = MyUI.Theme.Outline
            TglStroke.Thickness = 1
            TglStroke.Parent = ToggleFrame

            local ToggleCheck = Instance.new("Frame")
            ToggleCheck.Size = UDim2.new(0, 42, 0, 22)
            ToggleCheck.Position = UDim2.new(1, -55, 0.5, -11)
            ToggleCheck.BackgroundColor3 = state and MyUI.Theme.Accent or MyUI.Theme.ToggleDisabled
            ToggleCheck.Parent = ToggleFrame

            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(1, 0)
            CheckCorner.Parent = ToggleCheck

            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
            ToggleCircle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.Parent = ToggleCheck

            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                pcall(callback, state)
                
                TweenService:Create(ToggleCheck, TweenInfo.new(0.2), {
                    BackgroundColor3 = state and MyUI.Theme.Accent or MyUI.Theme.ToggleDisabled
                }):Play()
                
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }):Play()
            end)
        end

        -- =====================================
        -- วาด Slider
        -- =====================================
        function TabObj:CreateSlider(options)
            local sldName = options.Name or "Slider"
            local min = options.Range and options.Range[1] or 0
            local max = options.Range and options.Range[2] or 100
            local default = options.CurrentValue or min
            local callback = options.Callback or function() end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            SliderFrame.Parent = TabPage

            local SldCorner = Instance.new("UICorner")
            SldCorner.CornerRadius = UDim.new(0, 6)
            SldCorner.Parent = SliderFrame
            
            local SldStroke = Instance.new("UIStroke")
            SldStroke.Color = MyUI.Theme.Outline
            SldStroke.Thickness = 1
            SldStroke.Parent = SliderFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -20, 0, 20)
            TitleLabel.Position = UDim2.new(0, 10, 0, 8)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = sldName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = SliderFrame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -60, 0, 8)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = MyUI.Theme.Accent
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 14
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 8)
            SliderBar.Position = UDim2.new(0, 10, 0, 32)
            SliderBar.BackgroundColor3 = MyUI.Theme.ToggleDisabled
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = SliderFrame

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            local SliderFill = Instance.new("Frame")
            local startScale = (default - min) / (max - min)
            SliderFill.Size = UDim2.new(startScale, 0, 1, 0)
            SliderFill.BackgroundColor3 = MyUI.Theme.Accent
            SliderFill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill

            local sliding = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + ((max - min) * pos))
                ValueLabel.Text = tostring(value)
                TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                pcall(callback, value)
            end

            SliderBar.InputBegan:Connect(function(input)
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
        end

        return TabObj
    end

    return WindowObj
end

return MyUI
