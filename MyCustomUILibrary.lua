local MyUI = {}
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ระบบ Theme เลียนแบบ Rayfield ทำให้แก้สีได้ง่ายจากจุดเดียว
MyUI.Theme = {
    Background = Color3.fromRGB(30, 30, 30),
    Topbar = Color3.fromRGB(20, 20, 20),
    TabListBg = Color3.fromRGB(25, 25, 25),
    TabButton = Color3.fromRGB(40, 40, 40),
    TabButtonSelected = Color3.fromRGB(0, 146, 214), -- สีฟ้าคล้ายๆ Rayfield
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 150),
    ElementBackground = Color3.fromRGB(40, 40, 40),
    ElementHover = Color3.fromRGB(50, 50, 50),
    ToggleEnabled = Color3.fromRGB(0, 146, 214),
    ToggleDisabled = Color3.fromRGB(60, 60, 60),
    SliderBackground = Color3.fromRGB(60, 60, 60),
    SliderFill = Color3.fromRGB(0, 146, 214),
}

function MyUI:CreateWindow(options)
    local WindowName = options.Name or "My Custom UI"
    
    if CoreGui:FindFirstChild("MyCustomUI_Screen") then
        CoreGui:FindFirstChild("MyCustomUI_Screen"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MyCustomUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = (gethui and gethui()) or CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.BackgroundColor3 = MyUI.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- แถบ Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 35)
    Topbar.BackgroundColor3 = MyUI.Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 8)
    TopbarCorner.Parent = Topbar
    local CornerRepair = Instance.new("Frame")
    CornerRepair.Size = UDim2.new(1, 0, 0, 8)
    CornerRepair.Position = UDim2.new(0, 0, 1, -8)
    CornerRepair.BackgroundColor3 = MyUI.Theme.Topbar
    CornerRepair.BorderSizePixel = 0
    CornerRepair.Parent = Topbar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = WindowName
    TitleLabel.TextColor3 = MyUI.Theme.Text
    TitleLabel.TextSize = 15
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    -- ระบบลากหน้าต่าง (รองรับ PC และ Mobile)
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

    -- ระบบย่อ/ขยาย (เปิด/ปิด) UI ด้วยปุ่ม RightControl (สามารถตั้งค่าปุ่มอื่นได้)
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- สร้างปุ่มลอยสำหรับเปิด/ปิด UI (แสดงตลอดเวลา)
    local MobileBtn = Instance.new("TextButton")
    MobileBtn.Size = UDim2.new(0, 45, 0, 45)
    MobileBtn.Position = UDim2.new(0, 20, 0, 20)
    MobileBtn.BackgroundColor3 = MyUI.Theme.Topbar
    MobileBtn.Text = "UI"
    MobileBtn.TextColor3 = MyUI.Theme.Text
    MobileBtn.Font = Enum.Font.GothamBold
    MobileBtn.TextSize = 14
    MobileBtn.Parent = ScreenGui
    
    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(1, 0)
    MobileCorner.Parent = MobileBtn
    
    -- ทำให้ปุ่มเปิดปิด UI ได้
    MobileBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- แถบ TabList คล้าย Rayfield
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 0, 35)
    TabList.Position = UDim2.new(0, 0, 0, 35)
    TabList.BackgroundColor3 = MyUI.Theme.TabListBg
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.ScrollingDirection = Enum.ScrollingDirection.X
    TabList.Parent = MainFrame

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabList

    local TabListPadding = Instance.new("UIPadding")
    TabListPadding.PaddingLeft = UDim.new(0, 10)
    TabListPadding.PaddingTop = UDim.new(0, 5)
    TabListPadding.Parent = TabList

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, TabListLayout.AbsoluteContentSize.X + 20, 0, 0)
    end)

    -- พื้นที่แสดง Content ของแต่ละ Tab
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, -70)
    ContentContainer.Position = UDim2.new(0, 0, 0, 70)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local WindowObj = {}
    local FirstTab = true

    function WindowObj:CreateTab(tabName)
        local tabName = tabName or "Tab"
        
        -- สร้างปุ่ม Tab
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 100, 1, -5)
        TabButton.BackgroundColor3 = FirstTab and MyUI.Theme.TabButtonSelected or MyUI.Theme.TabButton
        TabButton.Text = tabName
        TabButton.TextColor3 = MyUI.Theme.Text
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.Parent = TabList
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabButton
        
        -- ปรับขนาดปุ่ม Tab ตามความยาวข้อความอัตโนมัติ
        TabButton.Size = UDim2.new(0, TabButton.TextBounds.X + 30, 1, -5)

        -- สร้างหน้า (Page) สำหรับ Tab นี้
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 3
        TabPage.Visible = FirstTab
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- ระบบเปลี่ยน Tab
        TabButton.MouseButton1Click:Connect(function()
            -- รีเซ็ตสีปุ่ม Tab ทั้งหมด
            for _, btn in ipairs(TabList:GetChildren()) do
                if btn:IsA("TextButton") then
                    TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = MyUI.Theme.TabButton}):Play()
                end
            end
            -- ไฮไลท์ปุ่มที่เลือก
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundColor3 = MyUI.Theme.TabButtonSelected}):Play()

            -- ซ่อน Page อื่นและแสดง Page ปัจจุบัน
            for _, page in ipairs(ContentContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then
                    page.Visible = false
                end
            end
            TabPage.Visible = true
        end)

        if FirstTab then FirstTab = false end

        -- ฟังก์ชันจัดการสิ่งต่างๆ ใน Tab (เหมือน Rayfield:CreateButton)
        local TabObj = {}

        -- สร้างปุ่ม (Button)
        function TabObj:CreateButton(options)
            local btnName = options.Name or "Button"
            local callback = options.Callback or function() end

            local ButtonFrame = Instance.new("TextButton")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 35)
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

            ButtonFrame.MouseEnter:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = MyUI.Theme.ElementHover}):Play()
            end)
            ButtonFrame.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = MyUI.Theme.ElementBackground}):Play()
            end)

            ButtonFrame.MouseButton1Click:Connect(function()
                pcall(callback)
                -- Click Effect แบบเล็กลงนิดนึงแล้วเด้งกลับ
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, -6, 0, 31)}):Play()
                wait(0.1)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            end)
        end

        -- สร้างสวิตช์เปิดปิด (Toggle)
        function TabObj:CreateToggle(options)
            local tglName = options.Name or "Toggle"
            local callback = options.Callback or function() end
            local state = options.CurrentValue or false

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
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

            local ToggleCheck = Instance.new("Frame")
            ToggleCheck.Size = UDim2.new(0, 40, 0, 20)
            ToggleCheck.Position = UDim2.new(1, -50, 0.5, -10)
            ToggleCheck.BackgroundColor3 = state and MyUI.Theme.ToggleEnabled or MyUI.Theme.ToggleDisabled
            ToggleCheck.Parent = ToggleFrame

            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(1, 0)
            CheckCorner.Parent = ToggleCheck

            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
            ToggleCircle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleCircle.Parent = ToggleCheck

            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                pcall(callback, state)
                
                -- อนิเมชั่นสวิตช์เลื่อนแบบสมูท
                TweenService:Create(ToggleCheck, TweenInfo.new(0.2), {
                    BackgroundColor3 = state and MyUI.Theme.ToggleEnabled or MyUI.Theme.ToggleDisabled
                }):Play()
                
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()
            end)
        end

        -- สร้างแถบเลื่อน (Slider)
        function TabObj:CreateSlider(options)
            local sldName = options.Name or "Slider"
            local min = options.Range and options.Range[1] or 0
            local max = options.Range and options.Range[2] or 100
            local default = options.CurrentValue or min
            local callback = options.Callback or function() end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 45)
            SliderFrame.BackgroundColor3 = MyUI.Theme.ElementBackground
            SliderFrame.Parent = TabPage

            local SldCorner = Instance.new("UICorner")
            SldCorner.CornerRadius = UDim.new(0, 6)
            SldCorner.Parent = SliderFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -20, 0, 20)
            TitleLabel.Position = UDim2.new(0, 10, 0, 5)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = sldName
            TitleLabel.TextColor3 = MyUI.Theme.Text
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextSize = 14
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = SliderFrame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = MyUI.Theme.TextDark
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.TextSize = 14
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 0, 30)
            SliderBar.BackgroundColor3 = MyUI.Theme.SliderBackground
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = SliderFrame

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            local SliderFill = Instance.new("Frame")
            local startScale = (default - min) / (max - min)
            SliderFill.Size = UDim2.new(startScale, 0, 1, 0)
            SliderFill.BackgroundColor3 = MyUI.Theme.SliderFill
            SliderFill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill

            -- ระบบเลื่อน Slider
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

-- ==========================================
-- วิธีการนำไปใช้งาน (ตัวอย่าง)
-- ==========================================
--[[
local MyWindow = MyUI:CreateWindow({
    Name = "My Custom UI (V2 - Rayfield Inspired)",
    ToggleKey = Enum.KeyCode.RightControl -- เปลี่ยนเป็นปุ่มอื่นได้ เช่น Enum.KeyCode.RightShift
})

local Tab1 = MyWindow:CreateTab("ฟังก์ชันหลัก")
local Tab2 = MyWindow:CreateTab("ตั้งค่า")

Tab1:CreateButton({
    Name = "ปริ้นข้อความ",
    Callback = function()
        print("Hello World!")
    end
})

Tab1:CreateToggle({
    Name = "ออโต้ฟาร์ม",
    CurrentValue = false,
    Callback = function(state)
        print("สถานะออโต้ฟาร์ม: ", state)
    end
})

Tab2:CreateSlider({
    Name = "ความเร็ว",
    Range = {16, 100},
    CurrentValue = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})
]]

return MyUI
