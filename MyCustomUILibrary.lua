--[[
    ======================================================================
    MyCustomUILibrary v4
    Modern, responsive, mobile-friendly Roblox/Luau UI library

    Public API kept compatible with the previous version:
      MyUI:SetTheme(theme)
      MyUI:OnUnload(callback)
      MyUI:Unload()
      MyUI:Notify(title, text, duration, type)
      MyUI:CreateWindow(options)

      Window:CreateTab(name, iconId)
      Window:Unload()
      Window:SetVisible(bool)
      Window:Toggle()

      Tab:CreateLabel(text)
      Tab:CreateSection(name)
      Tab:CreateParagraph(title, desc)
      Tab:CreateButton(options)
      Tab:CreateToggle(options)
      Tab:CreateSlider(options)
      Tab:CreateDropdown(options)
      Tab:CreateInput(options)
      Tab:CreateKeybind(options)
      Tab:CreateColorPicker(options)
    ======================================================================
--]]

local MyUI = {}
MyUI.UnloadCallbacks = {}
MyUI.Connections = {}
MyUI.CurrentScreenGui = nil
MyUI.NotifContainer = nil
MyUI.NotifGui = nil

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    error("MyCustomUILibrary must be used on the client.", 0)
end

MyUI.Theme = {
    Background = Color3.fromRGB(11, 13, 19),
    BackgroundAlt = Color3.fromRGB(16, 19, 27),
    Sidebar = Color3.fromRGB(14, 17, 24),
    Topbar = Color3.fromRGB(15, 18, 26),
    Element = Color3.fromRGB(21, 25, 35),
    ElementHover = Color3.fromRGB(29, 34, 47),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentGradient = Color3.fromRGB(139, 92, 246),
    AccentDark = Color3.fromRGB(79, 70, 229),
    Text = Color3.fromRGB(246, 248, 252),
    TextDark = Color3.fromRGB(151, 160, 180),
    Outline = Color3.fromRGB(39, 45, 61),
    OutlineLight = Color3.fromRGB(61, 70, 94),
    Red = Color3.fromRGB(244, 63, 94),
    Green = Color3.fromRGB(34, 197, 94),
    Yellow = Color3.fromRGB(245, 158, 11),
    CardBg = Color3.fromRGB(18, 22, 31),
}

function MyUI:SetTheme(newTheme)
    if type(newTheme) ~= "table" then
        return
    end

    for key, value in pairs(newTheme) do
        if self.Theme[key] ~= nil then
            self.Theme[key] = value
        end
    end
end

local ActivePopup = nil

local function TrackConnection(connection)
    if connection then
        MyUI.Connections[connection] = true
    end
    return connection
end

local function DisconnectConnection(connection)
    if not connection then
        return
    end

    MyUI.Connections[connection] = nil
    if typeof(connection) == "RBXScriptConnection" and connection.Connected then
        connection:Disconnect()
    end
end

local function Dispatch(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)
        if not ok then
            warn("[MyCustomUILibrary] Callback error: " .. tostring(err))
        end
    end)
end

local function Tween(object, properties, duration, style, direction)
    if not object or not object.Parent then
        return nil
    end

    local ok, tween = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                duration or 0.18,
                style or Enum.EasingStyle.Quart,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )
    end)

    if ok and tween then
        tween:Play()
        return tween
    end

    return nil
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or MyUI.Theme.Outline
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function CreateGradient(parent, colorA, colorB, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA or MyUI.Theme.Accent),
        ColorSequenceKeypoint.new(1, colorB or MyUI.Theme.AccentGradient),
    })
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

local function CreateTextPadding(parent, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 10)
    padding.PaddingRight = UDim.new(0, right or left or 10)
    padding.Parent = parent
    return padding
end

local function SafeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function GetSafeGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui")

    if playerGui then
        return playerGui
    end

    return CoreGui
end

local function GetViewportSize()
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function Clamp(value, minValue, maxValue)
    if maxValue < minValue then
        return (minValue + maxValue) * 0.5
    end
    return math.clamp(value, minValue, maxValue)
end

local function IsPointerInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsPointerMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function SetButtonUX(button)
    button.AutoButtonColor = false
    button.Selectable = true
end

function MyUI:OnUnload(callback)
    if type(callback) == "function" then
        table.insert(self.UnloadCallbacks, callback)
    end
end

function MyUI:Unload()
    local callbacks = self.UnloadCallbacks
    self.UnloadCallbacks = {}
    for _, callback in ipairs(callbacks) do
        local ok, err = pcall(callback)
        if not ok then
            warn("[MyCustomUILibrary] Unload callback error: " .. tostring(err))
        end
    end

    if ActivePopup and ActivePopup.Close then
        pcall(ActivePopup.Close)
    end
    ActivePopup = nil

    for connection in pairs(self.Connections) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    self.Connections = {}

    SafeDestroy(self.CurrentScreenGui)
    SafeDestroy(self.NotifGui)
    self.CurrentScreenGui = nil
    self.NotifGui = nil
    self.NotifContainer = nil

    local candidates = {}
    local seen = {}

    local function addCandidate(parent)
        if parent and not seen[parent] then
            seen[parent] = true
            table.insert(candidates, parent)
        end
    end

    addCandidate(GetSafeGuiParent())
    addCandidate(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    addCandidate(CoreGui)

    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok then
            addCandidate(result)
        end
    end

    for _, parent in ipairs(candidates) do
        for _, name in ipairs({
            "MyCustomUI_ScreenV3",
            "MyCustomUI_NotifV3",
            "MyCustomUI_ScreenV4",
            "MyCustomUI_NotifV4",
        }) do
            local old = parent:FindFirstChild(name)
            if old then
                SafeDestroy(old)
            end
        end
    end
end

local function EnsureNotifContainer()
    if MyUI.NotifContainer
        and MyUI.NotifContainer.Parent
        and MyUI.NotifGui
        and MyUI.NotifGui.Parent
    then
        return MyUI.NotifContainer
    end

    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MyCustomUI_NotifV4"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.IgnoreGuiInset = true
    notifGui.DisplayOrder = 9999
    notifGui.Parent = GetSafeGuiParent()
    MyUI.NotifGui = notifGui

    local container = Instance.new("Frame")
    container.Name = "NotifContainer"
    container.AnchorPoint = Vector2.new(1, 0)
    container.BackgroundTransparency = 1
    container.Parent = notifGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    local function updateBounds()
        local viewport = GetViewportSize()
        local width = math.clamp(viewport.X - 24, 240, 340)
        container.Size = UDim2.new(0, width, 1, -24)
        container.Position = UDim2.new(1, -12, 0, 12)
    end

    updateBounds()

    local camera = Workspace.CurrentCamera
    if camera then
        TrackConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateBounds))
    end

    MyUI.NotifContainer = container
    return container
end

function MyUI:Notify(title, text, duration, notifType)
    duration = tonumber(duration) or 3.5
    duration = math.max(duration, 0.6)

    local container = EnsureNotifContainer()
    local accentColor = self.Theme.Accent
    local accentEnd = self.Theme.AccentGradient
    local iconId = "rbxassetid://6031075938"

    if notifType == "Success" then
        accentColor = self.Theme.Green
        accentEnd = Color3.fromRGB(16, 185, 129)
        iconId = "rbxassetid://6031094678"
    elseif notifType == "Error" then
        accentColor = self.Theme.Red
        accentEnd = Color3.fromRGB(225, 29, 72)
        iconId = "rbxassetid://6031075931"
    elseif notifType == "Warning" then
        accentColor = self.Theme.Yellow
        accentEnd = Color3.fromRGB(251, 191, 36)
        iconId = "rbxassetid://6031075931"
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundColor3 = self.Theme.BackgroundAlt
    frame.BackgroundTransparency = 0.02
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = container
    CreateCorner(frame, 12)
    CreateStroke(frame, self.Theme.Outline, 1, 0.15)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, -20)
    accent.Position = UDim2.new(0, 8, 0, 10)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = frame
    CreateCorner(accent, 4)
    CreateGradient(accent, accentColor, accentEnd, 90)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.fromOffset(18, 18)
    icon.Position = UDim2.new(0, 22, 0, 13)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = accentColor
    icon.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -82, 0, 20)
    titleLabel.Position = UDim2.new(0, 48, 0, 11)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title or "Notification")
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = frame

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.fromOffset(28, 28)
    closeButton.Position = UDim2.new(1, -34, 0, 6)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "×"
    closeButton.TextColor3 = self.Theme.TextDark
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = frame
    SetButtonUX(closeButton)

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -40, 0, 0)
    body.Position = UDim2.new(0, 22, 0, 36)
    body.BackgroundTransparency = 1
    body.Text = tostring(text or "")
    body.TextColor3 = self.Theme.TextDark
    body.Font = Enum.Font.Gotham
    body.TextSize = 12
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = frame

    local availableWidth = math.max(180, container.AbsoluteSize.X - 54)
    local measured = TextService:GetTextSize(
        body.Text,
        body.TextSize,
        body.Font,
        Vector2.new(availableWidth, 1000)
    )
    local bodyHeight = math.max(16, measured.Y)
    local targetHeight = math.clamp(54 + bodyHeight, 68, 170)
    body.Size = UDim2.new(1, -40, 0, bodyHeight + 2)

    local progressBackground = Instance.new("Frame")
    progressBackground.Size = UDim2.new(1, 0, 0, 2)
    progressBackground.Position = UDim2.new(0, 0, 1, -2)
    progressBackground.BackgroundColor3 = self.Theme.Outline
    progressBackground.BorderSizePixel = 0
    progressBackground.Parent = frame

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 1, 0)
    progress.BackgroundColor3 = accentColor
    progress.BorderSizePixel = 0
    progress.Parent = progressBackground
    CreateGradient(progress, accentColor, accentEnd, 0)

    frame.Position = UDim2.new(0, 24, 0, 0)
    Tween(frame, {
        Size = UDim2.new(1, 0, 0, targetHeight),
        Position = UDim2.new(0, 0, 0, 0),
    }, 0.28, Enum.EasingStyle.Quart)
    Tween(progress, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed or not frame.Parent then
            return
        end
        dismissed = true

        local tween = Tween(frame, {
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 18, 0, 0),
            BackgroundTransparency = 1,
        }, 0.2, Enum.EasingStyle.Quad)

        if tween then
            local done
            done = tween.Completed:Connect(function()
                if done then
                    done:Disconnect()
                end
                SafeDestroy(frame)
            end)
        else
            SafeDestroy(frame)
        end
    end

    closeButton.MouseEnter:Connect(function()
        Tween(closeButton, { TextColor3 = self.Theme.Text }, 0.12)
    end)
    closeButton.MouseLeave:Connect(function()
        Tween(closeButton, { TextColor3 = self.Theme.TextDark }, 0.12)
    end)
    closeButton.Activated:Connect(dismiss)

    task.delay(duration, dismiss)

    return {
        Dismiss = dismiss,
        Frame = frame,
    }
end

function MyUI:CreateWindow(options)
    options = options or {}

    local windowName = tostring(options.Name or "Premium Hub")
    local subtitle = tostring(options.Subtitle or "Modern UI")
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl

    local mobileButtonEnabled
    if options.MobileButton == nil then
        mobileButtonEnabled = UserInputService.TouchEnabled
    else
        mobileButtonEnabled = options.MobileButton == true
    end

    self:Unload()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MyCustomUI_ScreenV4"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
    screenGui.Parent = GetSafeGuiParent()
    self.CurrentScreenGui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.BackgroundColor3 = self.Theme.Background
    mainFrame.BackgroundTransparency = 0.015
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui
    CreateCorner(mainFrame, 14)
    local mainStroke = CreateStroke(mainFrame, self.Theme.Outline, 1, 0.05)

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 8)
    shadow.Size = UDim2.new(1, 52, 1, 52)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.34
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 0
    shadow.Parent = mainFrame

    local inner = Instance.new("Frame")
    inner.Name = "InnerContainer"
    inner.Size = UDim2.fromScale(1, 1)
    inner.BackgroundTransparency = 1
    inner.BorderSizePixel = 0
    inner.ClipsDescendants = true
    inner.ZIndex = 1
    inner.Parent = mainFrame
    CreateCorner(inner, 14)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    sidebar.Parent = inner

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.BackgroundColor3 = self.Theme.Outline
    sidebarBorder.BackgroundTransparency = 0.2
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar

    local brandFrame = Instance.new("Frame")
    brandFrame.Size = UDim2.new(1, 0, 0, 64)
    brandFrame.BackgroundTransparency = 1
    brandFrame.Parent = sidebar

    local brandIcon = Instance.new("Frame")
    brandIcon.Size = UDim2.fromOffset(34, 34)
    brandIcon.Position = UDim2.new(0, 14, 0, 15)
    brandIcon.BackgroundColor3 = self.Theme.Accent
    brandIcon.BorderSizePixel = 0
    brandIcon.Parent = brandFrame
    CreateCorner(brandIcon, 10)
    CreateGradient(brandIcon, self.Theme.Accent, self.Theme.AccentGradient, 45)

    local brandLogo = Instance.new("ImageLabel")
    brandLogo.Size = UDim2.fromOffset(20, 20)
    brandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    brandLogo.Position = UDim2.fromScale(0.5, 0.5)
    brandLogo.BackgroundTransparency = 1
    brandLogo.Image = "rbxassetid://6031265976"
    brandLogo.ImageColor3 = Color3.new(1, 1, 1)
    brandLogo.Parent = brandIcon

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -62, 0, 20)
    titleLabel.Position = UDim2.new(0, 56, 0, 13)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = windowName
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = brandFrame

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -62, 0, 18)
    subtitleLabel.Position = UDim2.new(0, 56, 0, 33)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = self.Theme.TextDark
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 10
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subtitleLabel.Parent = brandFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "TabSearch"
    searchBox.Size = UDim2.new(1, -20, 0, 32)
    searchBox.Position = UDim2.new(0, 10, 0, 68)
    searchBox.BackgroundColor3 = self.Theme.BackgroundAlt
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search tabs..."
    searchBox.PlaceholderColor3 = self.Theme.TextDark
    searchBox.TextColor3 = self.Theme.Text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 11
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = sidebar
    CreateCorner(searchBox, 8)
    CreateStroke(searchBox, self.Theme.Outline, 1, 0.15)
    CreateTextPadding(searchBox, 10, 10)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -16, 1, -154)
    tabContainer.Position = UDim2.new(0, 8, 0, 108)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 2
    tabContainer.ScrollBarImageColor3 = self.Theme.OutlineLight
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContainer.CanvasSize = UDim2.new()
    tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    tabContainer.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.Parent = tabContainer

    local unloadButton = Instance.new("TextButton")
    unloadButton.Name = "UnloadButton"
    unloadButton.Size = UDim2.new(1, -20, 0, 34)
    unloadButton.Position = UDim2.new(0, 10, 1, -44)
    unloadButton.BackgroundColor3 = self.Theme.Red
    unloadButton.BackgroundTransparency = 0.9
    unloadButton.Text = "×  Unload UI"
    unloadButton.TextColor3 = self.Theme.Red
    unloadButton.Font = Enum.Font.GothamSemibold
    unloadButton.TextSize = 11
    unloadButton.Parent = sidebar
    SetButtonUX(unloadButton)
    CreateCorner(unloadButton, 8)
    local unloadStroke = CreateStroke(unloadButton, self.Theme.Red, 1, 0.68)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.ZIndex = 2
    contentArea.Parent = inner

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 54)
    topbar.BackgroundColor3 = self.Theme.Topbar
    topbar.BackgroundTransparency = 0.18
    topbar.BorderSizePixel = 0
    topbar.Parent = contentArea

    local topbarBorder = Instance.new("Frame")
    topbarBorder.Size = UDim2.new(1, 0, 0, 1)
    topbarBorder.Position = UDim2.new(0, 0, 1, -1)
    topbarBorder.BackgroundColor3 = self.Theme.Outline
    topbarBorder.BackgroundTransparency = 0.25
    topbarBorder.BorderSizePixel = 0
    topbarBorder.Parent = topbar

    local pageTitle = Instance.new("TextLabel")
    pageTitle.Size = UDim2.new(1, -92, 0, 22)
    pageTitle.Position = UDim2.new(0, 18, 0, 9)
    pageTitle.BackgroundTransparency = 1
    pageTitle.Text = "Overview"
    pageTitle.TextColor3 = self.Theme.Text
    pageTitle.Font = Enum.Font.GothamBold
    pageTitle.TextSize = 14
    pageTitle.TextXAlignment = Enum.TextXAlignment.Left
    pageTitle.TextTruncate = Enum.TextTruncate.AtEnd
    pageTitle.Parent = topbar

    local pageHint = Instance.new("TextLabel")
    pageHint.Size = UDim2.new(1, -92, 0, 16)
    pageHint.Position = UDim2.new(0, 18, 0, 30)
    pageHint.BackgroundTransparency = 1
    pageHint.Text = "Configure options below"
    pageHint.TextColor3 = self.Theme.TextDark
    pageHint.Font = Enum.Font.Gotham
    pageHint.TextSize = 10
    pageHint.TextXAlignment = Enum.TextXAlignment.Left
    pageHint.Parent = topbar

    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.fromOffset(30, 30)
    minimizeButton.Position = UDim2.new(1, -72, 0, 12)
    minimizeButton.BackgroundColor3 = self.Theme.Element
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = self.Theme.TextDark
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = 14
    minimizeButton.Parent = topbar
    SetButtonUX(minimizeButton)
    CreateCorner(minimizeButton, 8)
    CreateStroke(minimizeButton, self.Theme.Outline, 1, 0.2)

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.fromOffset(30, 30)
    closeButton.Position = UDim2.new(1, -38, 0, 12)
    closeButton.BackgroundColor3 = self.Theme.Element
    closeButton.Text = "×"
    closeButton.TextColor3 = self.Theme.TextDark
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = topbar
    SetButtonUX(closeButton)
    CreateCorner(closeButton, 8)
    local closeStroke = CreateStroke(closeButton, self.Theme.Outline, 1, 0.2)

    local pagesHost = Instance.new("Frame")
    pagesHost.Name = "Pages"
    pagesHost.Size = UDim2.new(1, 0, 1, -54)
    pagesHost.Position = UDim2.new(0, 0, 0, 54)
    pagesHost.BackgroundTransparency = 1
    pagesHost.ClipsDescendants = true
    pagesHost.Parent = contentArea

    local windowWidth = 720
    local windowHeight = 500
    local sidebarWidth = 190
    local compactSidebar = false
    local uiVisible = true
    local tabEntries = {}

    local function updateResponsiveLayout()
        if not mainFrame.Parent then
            return
        end

        local viewport = GetViewportSize()
        windowWidth = math.min(720, math.max(280, viewport.X - 24))
        windowHeight = math.min(500, math.max(260, viewport.Y - 24))
        windowWidth = math.min(windowWidth, viewport.X)
        windowHeight = math.min(windowHeight, viewport.Y)
        compactSidebar = windowWidth < 560
        sidebarWidth = compactSidebar and 68 or 190

        if uiVisible then
            mainFrame.Size = UDim2.fromOffset(windowWidth, windowHeight)
        end

        sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
        contentArea.Size = UDim2.new(1, -sidebarWidth, 1, 0)
        contentArea.Position = UDim2.new(0, sidebarWidth, 0, 0)

        titleLabel.Visible = not compactSidebar
        subtitleLabel.Visible = not compactSidebar
        searchBox.Visible = not compactSidebar
        unloadButton.Text = compactSidebar and "×" or "×  Unload UI"
        unloadButton.Size = compactSidebar and UDim2.fromOffset(42, 34) or UDim2.new(1, -20, 0, 34)
        unloadButton.Position = compactSidebar
            and UDim2.new(0.5, -21, 1, -44)
            or UDim2.new(0, 10, 1, -44)

        tabContainer.Position = compactSidebar
            and UDim2.new(0, 8, 0, 72)
            or UDim2.new(0, 8, 0, 108)
        tabContainer.Size = compactSidebar
            and UDim2.new(1, -16, 1, -118)
            or UDim2.new(1, -16, 1, -154)

        brandIcon.Position = compactSidebar
            and UDim2.new(0.5, -17, 0, 15)
            or UDim2.new(0, 14, 0, 15)

        for _, entry in ipairs(tabEntries) do
            entry.Text.Visible = not compactSidebar
            entry.Icon.Position = compactSidebar
                and UDim2.new(0.5, -9, 0.5, -9)
                or UDim2.new(0, 14, 0.5, -9)
            entry.Indicator.Position = compactSidebar
                and UDim2.new(0, 2, 0.5, -9)
                or UDim2.new(0, 4, 0.5, -9)
        end

        local offsetX = mainFrame.Position.X.Offset
        local offsetY = mainFrame.Position.Y.Offset
        local halfW = windowWidth * 0.5
        local halfH = windowHeight * 0.5
        local centerX = viewport.X * 0.5 + offsetX
        local centerY = viewport.Y * 0.5 + offsetY

        centerX = Clamp(centerX, halfW + 8, viewport.X - halfW - 8)
        centerY = Clamp(centerY, halfH + 8, viewport.Y - halfH - 8)
        mainFrame.Position = UDim2.new(
            0.5,
            centerX - viewport.X * 0.5,
            0.5,
            centerY - viewport.Y * 0.5
        )
    end

    local camera = Workspace.CurrentCamera
    if camera then
        TrackConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout))
    end

    local hideToken = 0

    local function setUIVisible(visible)
        visible = visible == true
        if uiVisible == visible then
            return
        end

        uiVisible = visible
        hideToken += 1
        local token = hideToken

        if visible then
            mainFrame.Visible = true
            mainFrame.Size = UDim2.fromOffset(
                math.floor(windowWidth * 0.96),
                math.floor(windowHeight * 0.96)
            )
            mainFrame.BackgroundTransparency = 0.16
            mainStroke.Transparency = 0.55

            Tween(mainFrame, {
                Size = UDim2.fromOffset(windowWidth, windowHeight),
                BackgroundTransparency = 0.015,
            }, 0.22, Enum.EasingStyle.Quart)
            Tween(mainStroke, { Transparency = 0.05 }, 0.18)
        else
            if ActivePopup and ActivePopup.Close then
                ActivePopup.Close()
            end

            Tween(mainFrame, {
                Size = UDim2.fromOffset(
                    math.floor(windowWidth * 0.96),
                    math.floor(windowHeight * 0.96)
                ),
                BackgroundTransparency = 0.18,
            }, 0.18, Enum.EasingStyle.Quad)
            Tween(mainStroke, { Transparency = 0.65 }, 0.16)

            task.delay(0.18, function()
                if token == hideToken and not uiVisible and mainFrame.Parent then
                    mainFrame.Visible = false
                    mainFrame.Size = UDim2.fromOffset(windowWidth, windowHeight)
                end
            end)
        end
    end

    local dragging = false
    local dragStart
    local dragStartPosition

    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, -84, 0, 54)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Active = true
    dragHandle.ZIndex = 20
    dragHandle.Parent = topbar

    TrackConnection(dragHandle.InputBegan:Connect(function(input)
        if IsPointerInput(input) then
            dragging = true
            dragStart = input.Position
            dragStartPosition = mainFrame.Position
        end
    end))

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart or not dragStartPosition or not IsPointerMove(input) then
            return
        end

        local delta = input.Position - dragStart
        local viewport = GetViewportSize()
        local halfW = mainFrame.AbsoluteSize.X * 0.5
        local halfH = mainFrame.AbsoluteSize.Y * 0.5

        local desiredOffsetX = dragStartPosition.X.Offset + delta.X
        local desiredOffsetY = dragStartPosition.Y.Offset + delta.Y
        local centerX = viewport.X * 0.5 + desiredOffsetX
        local centerY = viewport.Y * 0.5 + desiredOffsetY

        centerX = Clamp(centerX, halfW + 8, viewport.X - halfW - 8)
        centerY = Clamp(centerY, halfH + 8, viewport.Y - halfH - 8)

        mainFrame.Position = UDim2.new(
            0.5,
            centerX - viewport.X * 0.5,
            0.5,
            centerY - viewport.Y * 0.5
        )
    end))

    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if IsPointerInput(input) then
            dragging = false
        end
    end))

    TrackConnection(UserInputService.InputBegan:Connect(function(input)
        if not IsPointerInput(input) or not ActivePopup then
            return
        end

        local frame = ActivePopup.Frame
        if not frame or not frame.Parent then
            ActivePopup.Close()
            return
        end

        local pointer = input.Position
        local pos = frame.AbsolutePosition
        local size = frame.AbsoluteSize
        local inside = pointer.X >= pos.X
            and pointer.X <= pos.X + size.X
            and pointer.Y >= pos.Y
            and pointer.Y <= pos.Y + size.Y

        if not inside then
            ActivePopup.Close()
        end
    end))

    TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            setUIVisible(not uiVisible)
        end
    end))

    unloadButton.MouseEnter:Connect(function()
        Tween(unloadButton, { BackgroundTransparency = 0.78 }, 0.14)
        Tween(unloadStroke, { Transparency = 0.35 }, 0.14)
    end)
    unloadButton.MouseLeave:Connect(function()
        Tween(unloadButton, { BackgroundTransparency = 0.9 }, 0.14)
        Tween(unloadStroke, { Transparency = 0.68 }, 0.14)
    end)
    unloadButton.Activated:Connect(function()
        MyUI:Unload()
    end)

    minimizeButton.MouseEnter:Connect(function()
        Tween(minimizeButton, {
            BackgroundColor3 = self.Theme.ElementHover,
            TextColor3 = self.Theme.Text,
        }, 0.12)
    end)
    minimizeButton.MouseLeave:Connect(function()
        Tween(minimizeButton, {
            BackgroundColor3 = self.Theme.Element,
            TextColor3 = self.Theme.TextDark,
        }, 0.12)
    end)
    minimizeButton.Activated:Connect(function()
        setUIVisible(false)
    end)

    closeButton.MouseEnter:Connect(function()
        Tween(closeButton, {
            BackgroundColor3 = Color3.fromRGB(50, 22, 30),
            TextColor3 = self.Theme.Red,
        }, 0.12)
        Tween(closeStroke, { Color = self.Theme.Red, Transparency = 0.2 }, 0.12)
    end)
    closeButton.MouseLeave:Connect(function()
        Tween(closeButton, {
            BackgroundColor3 = self.Theme.Element,
            TextColor3 = self.Theme.TextDark,
        }, 0.12)
        Tween(closeStroke, { Color = self.Theme.Outline, Transparency = 0.2 }, 0.12)
    end)
    closeButton.Activated:Connect(function()
        MyUI:Unload()
    end)

    if mobileButtonEnabled then
        local mobileButton = Instance.new("TextButton")
        mobileButton.Name = "MobileTogglePill"
        mobileButton.Size = UDim2.fromOffset(48, 48)
        mobileButton.Position = UDim2.new(1, -62, 1, -62)
        mobileButton.BackgroundColor3 = self.Theme.BackgroundAlt
        mobileButton.Text = ""
        mobileButton.ZIndex = 50
        mobileButton.Parent = screenGui
        SetButtonUX(mobileButton)
        CreateCorner(mobileButton, 16)
        CreateStroke(mobileButton, self.Theme.Accent, 1, 0.25)

        local glow = Instance.new("Frame")
        glow.Size = UDim2.fromScale(1, 1)
        glow.BackgroundTransparency = 0.78
        glow.BorderSizePixel = 0
        glow.Parent = mobileButton
        CreateCorner(glow, 16)
        CreateGradient(glow, self.Theme.Accent, self.Theme.AccentGradient, 45)

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.fromOffset(22, 22)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://6031265976"
        icon.ImageColor3 = self.Theme.Text
        icon.Parent = mobileButton

        local mobileDragging = false
        local mobileMoved = false
        local mobileStart
        local mobileStartPosition

        local function clampMobilePosition(position)
            local viewport = GetViewportSize()
            local size = mobileButton.AbsoluteSize
            local x = position.X.Scale * viewport.X + position.X.Offset
            local y = position.Y.Scale * viewport.Y + position.Y.Offset

            x = math.clamp(x, 10, math.max(10, viewport.X - size.X - 10))
            y = math.clamp(y, 10, math.max(10, viewport.Y - size.Y - 10))
            return UDim2.fromOffset(x, y)
        end

        mobileButton.InputBegan:Connect(function(input)
            if IsPointerInput(input) then
                mobileDragging = true
                mobileMoved = false
                mobileStart = input.Position
                mobileStartPosition = clampMobilePosition(mobileButton.Position)
                mobileButton.Position = mobileStartPosition
            end
        end)

        TrackConnection(UserInputService.InputChanged:Connect(function(input)
            if not mobileDragging or not mobileStart or not mobileStartPosition or not IsPointerMove(input) then
                return
            end

            local delta = input.Position - mobileStart
            if delta.Magnitude >= 5 then
                mobileMoved = true
            end

            mobileButton.Position = clampMobilePosition(UDim2.fromOffset(
                mobileStartPosition.X.Offset + delta.X,
                mobileStartPosition.Y.Offset + delta.Y
            ))
        end))

        TrackConnection(UserInputService.InputEnded:Connect(function(input)
            if IsPointerInput(input) then
                mobileDragging = false
            end
        end))

        mobileButton.Activated:Connect(function()
            if mobileMoved then
                mobileMoved = false
                return
            end

            setUIVisible(not uiVisible)
            Tween(mobileButton, { Size = UDim2.fromOffset(44, 44) }, 0.08)
            task.delay(0.08, function()
                if mobileButton.Parent then
                    Tween(mobileButton, { Size = UDim2.fromOffset(48, 48) }, 0.12)
                end
            end)
        end)
    end

    local WindowObj = {}
    local currentTab = nil
    local firstTab = true
    local switchingTab = false

    local function filterTabs()
        local query = string.lower(searchBox.Text)
        for _, entry in ipairs(tabEntries) do
            entry.Button.Visible = query == ""
                or string.find(string.lower(entry.Name), query, 1, true) ~= nil
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(filterTabs)

    function WindowObj:SetVisible(visible)
        setUIVisible(visible)
    end

    function WindowObj:Toggle()
        setUIVisible(not uiVisible)
    end

    function WindowObj:Unload()
        MyUI:Unload()
    end

    function WindowObj:CreateTab(tabName, iconId)
        tabName = tostring(tabName or "Tab")

        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 40)
        tabButton.BackgroundColor3 = firstTab and MyUI.Theme.ElementHover or MyUI.Theme.Element
        tabButton.BackgroundTransparency = firstTab and 0.12 or 1
        tabButton.Text = ""
        tabButton.Parent = tabContainer
        SetButtonUX(tabButton)
        CreateCorner(tabButton, 9)
        local tabStroke = CreateStroke(tabButton, MyUI.Theme.Outline, 1, firstTab and 0.5 or 1)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.fromOffset(3, 18)
        indicator.Position = UDim2.new(0, 4, 0.5, -9)
        indicator.BackgroundColor3 = MyUI.Theme.Accent
        indicator.BackgroundTransparency = firstTab and 0 or 1
        indicator.BorderSizePixel = 0
        indicator.Parent = tabButton
        CreateCorner(indicator, 3)
        CreateGradient(indicator, MyUI.Theme.Accent, MyUI.Theme.AccentGradient, 90)

        local tabIcon = Instance.new("ImageLabel")
        tabIcon.Size = UDim2.fromOffset(18, 18)
        tabIcon.Position = UDim2.new(0, 14, 0.5, -9)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Image = iconId or "rbxassetid://6031265976"
        tabIcon.ImageColor3 = firstTab and MyUI.Theme.Text or MyUI.Theme.TextDark
        tabIcon.Parent = tabButton

        local tabText = Instance.new("TextLabel")
        tabText.Size = UDim2.new(1, -46, 1, 0)
        tabText.Position = UDim2.new(0, 42, 0, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = tabName
        tabText.TextColor3 = firstTab and MyUI.Theme.Text or MyUI.Theme.TextDark
        tabText.Font = Enum.Font.GothamSemibold
        tabText.TextSize = 12
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.TextTruncate = Enum.TextTruncate.AtEnd
        tabText.Parent = tabButton

        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = "Page_" .. tabName
        tabPage.Size = UDim2.fromScale(1, 1)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = MyUI.Theme.OutlineLight
        tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabPage.CanvasSize = UDim2.new()
        tabPage.ScrollingDirection = Enum.ScrollingDirection.Y
        tabPage.Visible = firstTab
        tabPage.Parent = pagesHost

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = tabPage

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingLeft = UDim.new(0, 16)
        pagePadding.PaddingRight = UDim.new(0, 16)
        pagePadding.PaddingTop = UDim.new(0, 16)
        pagePadding.PaddingBottom = UDim.new(0, 18)
        pagePadding.Parent = tabPage

        local tabData = {
            Name = tabName,
            Button = tabButton,
            Text = tabText,
            Icon = tabIcon,
            Indicator = indicator,
            Stroke = tabStroke,
            Page = tabPage,
        }
        table.insert(tabEntries, tabData)

        if compactSidebar then
            tabText.Visible = false
            tabIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
            indicator.Position = UDim2.new(0, 2, 0.5, -9)
        end

        local function setTabVisual(entry, active)
            Tween(entry.Button, {
                BackgroundTransparency = active and 0.12 or 1,
                BackgroundColor3 = active and MyUI.Theme.ElementHover or MyUI.Theme.Element,
            }, 0.16)
            Tween(entry.Text, {
                TextColor3 = active and MyUI.Theme.Text or MyUI.Theme.TextDark,
            }, 0.16)
            Tween(entry.Icon, {
                ImageColor3 = active and MyUI.Theme.Text or MyUI.Theme.TextDark,
            }, 0.16)
            Tween(entry.Indicator, {
                BackgroundTransparency = active and 0 or 1,
            }, 0.16)
            Tween(entry.Stroke, {
                Transparency = active and 0.5 or 1,
            }, 0.16)
        end

        local function selectTab()
            if currentTab == tabData or switchingTab then
                return
            end

            switchingTab = true
            if ActivePopup and ActivePopup.Close then
                ActivePopup.Close()
            end

            if currentTab then
                setTabVisual(currentTab, false)
                currentTab.Page.Visible = false
            end

            currentTab = tabData
            setTabVisual(tabData, true)
            pageTitle.Text = tabName
            tabPage.Visible = true
            tabPage.Position = UDim2.new(0, 8, 0, 0)
            Tween(tabPage, { Position = UDim2.new() }, 0.18, Enum.EasingStyle.Quart)

            task.delay(0.18, function()
                switchingTab = false
            end)
        end

        tabButton.MouseEnter:Connect(function()
            if currentTab ~= tabData then
                Tween(tabButton, { BackgroundTransparency = 0.55 }, 0.12)
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if currentTab ~= tabData then
                Tween(tabButton, { BackgroundTransparency = 1 }, 0.12)
            end
        end)
        tabButton.Activated:Connect(selectTab)

        if firstTab then
            currentTab = tabData
            pageTitle.Text = tabName
            firstTab = false
        end

        local TabObj = {}

        function TabObj:Select()
            selectTab()
        end

        function TabObj:CreateLabel(text)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.BackgroundTransparency = 1
            frame.Parent = tabPage

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 0)
            label.AutomaticSize = Enum.AutomaticSize.Y
            label.BackgroundTransparency = 1
            label.Text = tostring(text or "")
            label.TextColor3 = MyUI.Theme.TextDark
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local controller = {}
            function controller:Set(newText)
                label.Text = tostring(newText or "")
            end
            return controller
        end

        function TabObj:CreateSection(sectionName)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.BackgroundTransparency = 1
            frame.Parent = tabPage

            local pill = Instance.new("Frame")
            pill.Size = UDim2.fromOffset(4, 18)
            pill.Position = UDim2.new(0, 0, 0.5, -9)
            pill.BackgroundColor3 = MyUI.Theme.Accent
            pill.BorderSizePixel = 0
            pill.Parent = frame
            CreateCorner(pill, 4)
            CreateGradient(pill, MyUI.Theme.Accent, MyUI.Theme.AccentGradient, 90)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -14, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = tostring(sectionName or "Section")
            label.TextColor3 = MyUI.Theme.Text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
        end

        function TabObj:CreateParagraph(title, description)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.BackgroundColor3 = MyUI.Theme.CardBg
            frame.BorderSizePixel = 0
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            CreateStroke(frame, MyUI.Theme.Outline, 1, 0.15)

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 14)
            padding.PaddingRight = UDim.new(0, 14)
            padding.PaddingTop = UDim.new(0, 12)
            padding.PaddingBottom = UDim.new(0, 12)
            padding.Parent = frame

            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 5)
            layout.Parent = frame

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, 0, 0, 20)
            titleText.BackgroundTransparency = 1
            titleText.Text = tostring(title or "")
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamBold
            titleText.TextSize = 13
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.LayoutOrder = 1
            titleText.Parent = frame

            local descText = Instance.new("TextLabel")
            descText.Size = UDim2.new(1, 0, 0, 0)
            descText.AutomaticSize = Enum.AutomaticSize.Y
            descText.BackgroundTransparency = 1
            descText.Text = tostring(description or "")
            descText.TextColor3 = MyUI.Theme.TextDark
            descText.Font = Enum.Font.Gotham
            descText.TextSize = 12
            descText.TextWrapped = true
            descText.TextXAlignment = Enum.TextXAlignment.Left
            descText.TextYAlignment = Enum.TextYAlignment.Top
            descText.LayoutOrder = 2
            descText.Parent = frame

            local controller = {}
            function controller:Set(newTitle, newDescription)
                if newTitle ~= nil then
                    titleText.Text = tostring(newTitle)
                end
                if newDescription ~= nil then
                    descText.Text = tostring(newDescription)
                end
            end
            return controller
        end

        function TabObj:CreateButton(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Button")
            local description = opt.Description
            local callback = opt.Callback or function() end
            local height = description and 54 or 42

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, height)
            button.BackgroundColor3 = MyUI.Theme.Element
            button.Text = ""
            button.Parent = tabPage
            SetButtonUX(button)
            CreateCorner(button, 10)
            local stroke = CreateStroke(button, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -50, 0, description and 22 or height)
            titleText.Position = UDim2.new(0, 14, 0, description and 6 or 0)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 13
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = button

            if description then
                local descText = Instance.new("TextLabel")
                descText.Size = UDim2.new(1, -50, 0, 18)
                descText.Position = UDim2.new(0, 14, 0, 29)
                descText.BackgroundTransparency = 1
                descText.Text = tostring(description)
                descText.TextColor3 = MyUI.Theme.TextDark
                descText.Font = Enum.Font.Gotham
                descText.TextSize = 10
                descText.TextXAlignment = Enum.TextXAlignment.Left
                descText.TextTruncate = Enum.TextTruncate.AtEnd
                descText.Parent = button
            end

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.fromOffset(16, 16)
            icon.Position = UDim2.new(1, -30, 0.5, -8)
            icon.BackgroundTransparency = 1
            icon.Image = "rbxassetid://6031091000"
            icon.ImageColor3 = MyUI.Theme.TextDark
            icon.Parent = button

            button.MouseEnter:Connect(function()
                Tween(button, { BackgroundColor3 = MyUI.Theme.ElementHover }, 0.14)
                Tween(stroke, { Color = MyUI.Theme.Accent, Transparency = 0.35 }, 0.14)
                Tween(icon, { ImageColor3 = MyUI.Theme.Accent }, 0.14)
            end)
            button.MouseLeave:Connect(function()
                Tween(button, { BackgroundColor3 = MyUI.Theme.Element }, 0.14)
                Tween(stroke, { Color = MyUI.Theme.Outline, Transparency = 0.12 }, 0.14)
                Tween(icon, { ImageColor3 = MyUI.Theme.TextDark }, 0.14)
            end)
            button.Activated:Connect(function()
                Tween(button, { BackgroundColor3 = MyUI.Theme.BackgroundAlt }, 0.06)
                task.delay(0.07, function()
                    if button.Parent then
                        Tween(button, { BackgroundColor3 = MyUI.Theme.ElementHover }, 0.1)
                    end
                end)
                Dispatch(callback)
            end)

            local controller = {}
            function controller:SetText(newText)
                titleText.Text = tostring(newText or "")
            end
            return controller
        end

        function TabObj:CreateToggle(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Toggle")
            local description = opt.Description
            local state = opt.CurrentValue == true
            local callback = opt.Callback or function() end
            local height = description and 54 or 42

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, height)
            button.BackgroundColor3 = MyUI.Theme.Element
            button.Text = ""
            button.Parent = tabPage
            SetButtonUX(button)
            CreateCorner(button, 10)
            local stroke = CreateStroke(button, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -78, 0, description and 22 or height)
            titleText.Position = UDim2.new(0, 14, 0, description and 6 or 0)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 13
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = button

            if description then
                local descText = Instance.new("TextLabel")
                descText.Size = UDim2.new(1, -78, 0, 18)
                descText.Position = UDim2.new(0, 14, 0, 29)
                descText.BackgroundTransparency = 1
                descText.Text = tostring(description)
                descText.TextColor3 = MyUI.Theme.TextDark
                descText.Font = Enum.Font.Gotham
                descText.TextSize = 10
                descText.TextXAlignment = Enum.TextXAlignment.Left
                descText.TextTruncate = Enum.TextTruncate.AtEnd
                descText.Parent = button
            end

            local track = Instance.new("Frame")
            track.Size = UDim2.fromOffset(44, 24)
            track.Position = UDim2.new(1, -58, 0.5, -12)
            track.BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(39, 44, 59)
            track.BorderSizePixel = 0
            track.Parent = button
            CreateCorner(track, 12)
            local gradient = CreateGradient(track, MyUI.Theme.Accent, MyUI.Theme.AccentGradient, 0)
            gradient.Enabled = state

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(18, 18)
            knob.Position = state
                and UDim2.new(1, -21, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.BorderSizePixel = 0
            knob.Parent = track
            CreateCorner(knob, 9)

            local function update(newState, skipCallback)
                state = newState == true
                gradient.Enabled = state
                Tween(track, {
                    BackgroundColor3 = state and MyUI.Theme.Accent or Color3.fromRGB(39, 44, 59),
                }, 0.18)
                Tween(knob, {
                    Position = state
                        and UDim2.new(1, -21, 0.5, -9)
                        or UDim2.new(0, 3, 0.5, -9),
                }, 0.18, Enum.EasingStyle.Back)

                if not skipCallback then
                    Dispatch(callback, state)
                end
            end

            button.MouseEnter:Connect(function()
                Tween(button, { BackgroundColor3 = MyUI.Theme.ElementHover }, 0.14)
                Tween(stroke, { Color = MyUI.Theme.OutlineLight }, 0.14)
            end)
            button.MouseLeave:Connect(function()
                Tween(button, { BackgroundColor3 = MyUI.Theme.Element }, 0.14)
                Tween(stroke, { Color = MyUI.Theme.Outline }, 0.14)
            end)
            button.Activated:Connect(function()
                update(not state, false)
            end)

            local controller = {}
            function controller:Set(value, ignoreCallback)
                update(value == true, ignoreCallback == true)
            end
            function controller:GetValue()
                return state
            end
            return controller
        end

        function TabObj:CreateSlider(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Slider")
            local range = opt.Range or { 0, 100 }
            local minimum = tonumber(range[1]) or 0
            local maximum = tonumber(range[2]) or 100
            if maximum < minimum then
                minimum, maximum = maximum, minimum
            end

            local step = math.abs(tonumber(opt.Step) or 1)
            if step <= 0 then
                step = 1
            end

            local callback = opt.Callback or function() end
            local rangeDelta = maximum - minimum
            local value = tonumber(opt.CurrentValue)
            if value == nil then
                value = minimum
            end

            local function normalize(raw)
                raw = math.clamp(tonumber(raw) or minimum, minimum, maximum)
                if rangeDelta <= 0 then
                    return minimum
                end

                local stepped = minimum + math.floor(((raw - minimum) / step) + 0.5) * step
                stepped = math.clamp(stepped, minimum, maximum)
                return stepped
            end

            value = normalize(value)

            local function decimalPlaces(number)
                local formatted = string.format("%.4f", math.abs(number))
                local fraction = string.match(formatted, "%.(%d+)") or ""
                fraction = string.gsub(fraction, "0+$", "")
                return #fraction
            end

            local valueDecimals = math.min(
                4,
                math.max(decimalPlaces(step), decimalPlaces(minimum), decimalPlaces(maximum))
            )

            local function valueToText(number)
                if valueDecimals > 0 then
                    return string.format("%." .. valueDecimals .. "f", number)
                end
                return tostring(math.floor(number + 0.0000001))
            end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 62)
            frame.BackgroundColor3 = MyUI.Theme.Element
            frame.BorderSizePixel = 0
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            CreateStroke(frame, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -84, 0, 24)
            titleText.Position = UDim2.new(0, 14, 0, 6)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 13
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = frame

            local valueBox = Instance.new("TextBox")
            valueBox.Size = UDim2.fromOffset(58, 24)
            valueBox.Position = UDim2.new(1, -72, 0, 6)
            valueBox.BackgroundColor3 = MyUI.Theme.BackgroundAlt
            valueBox.Text = valueToText(value)
            valueBox.TextColor3 = MyUI.Theme.Accent
            valueBox.Font = Enum.Font.GothamBold
            valueBox.TextSize = 11
            valueBox.ClearTextOnFocus = false
            valueBox.Parent = frame
            CreateCorner(valueBox, 6)
            local valueStroke = CreateStroke(valueBox, MyUI.Theme.Outline, 1, 0.1)
            CreateTextPadding(valueBox, 6, 6)

            local hitbox = Instance.new("TextButton")
            hitbox.Size = UDim2.new(1, -28, 0, 22)
            hitbox.Position = UDim2.new(0, 14, 0, 34)
            hitbox.BackgroundTransparency = 1
            hitbox.Text = ""
            hitbox.Parent = frame
            SetButtonUX(hitbox)

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, 0, 0, 6)
            track.Position = UDim2.new(0, 0, 0.5, -3)
            track.BackgroundColor3 = Color3.fromRGB(39, 44, 59)
            track.BorderSizePixel = 0
            track.Parent = hitbox
            CreateCorner(track, 3)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = MyUI.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            CreateCorner(fill, 3)
            CreateGradient(fill, MyUI.Theme.Accent, MyUI.Theme.AccentGradient, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = UDim2.new(1, -8, 0.5, -8)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.BorderSizePixel = 0
            knob.Parent = fill
            CreateCorner(knob, 8)
            CreateStroke(knob, MyUI.Theme.Accent, 1, 0.35)

            local function redraw(animate)
                local percent = rangeDelta > 0 and (value - minimum) / rangeDelta or 0
                percent = math.clamp(percent, 0, 1)
                valueBox.Text = valueToText(value)
                if animate then
                    Tween(fill, { Size = UDim2.new(percent, 0, 1, 0) }, 0.08)
                else
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                end
            end
            redraw(false)

            local function setValue(raw, skipCallback, animate)
                local nextValue = normalize(raw)
                local changed = nextValue ~= value
                value = nextValue
                redraw(animate ~= false)

                if changed and not skipCallback then
                    Dispatch(callback, value)
                end
            end

            local moveConnection
            local releaseConnection

            local function stopSliding()
                DisconnectConnection(moveConnection)
                DisconnectConnection(releaseConnection)
                moveConnection = nil
                releaseConnection = nil
                Tween(knob, {
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.new(1, -8, 0.5, -8),
                }, 0.12)
            end

            local function updateFromX(inputX)
                local width = track.AbsoluteSize.X
                if width <= 0 then
                    return
                end
                local x = math.clamp(inputX - track.AbsolutePosition.X, 0, width)
                local percent = x / width
                setValue(minimum + rangeDelta * percent, false, true)
            end

            hitbox.InputBegan:Connect(function(input)
                if not IsPointerInput(input) then
                    return
                end

                stopSliding()
                Tween(knob, {
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.new(1, -9, 0.5, -9),
                }, 0.1)
                updateFromX(input.Position.X)

                moveConnection = TrackConnection(UserInputService.InputChanged:Connect(function(moveInput)
                    if IsPointerMove(moveInput) then
                        updateFromX(moveInput.Position.X)
                    end
                end))

                releaseConnection = TrackConnection(UserInputService.InputEnded:Connect(function(endInput)
                    if IsPointerInput(endInput) then
                        stopSliding()
                    end
                end))
            end)

            valueBox.Focused:Connect(function()
                Tween(valueStroke, { Color = MyUI.Theme.Accent }, 0.12)
            end)
            valueBox.FocusLost:Connect(function()
                Tween(valueStroke, { Color = MyUI.Theme.Outline }, 0.12)
                local parsed = tonumber(valueBox.Text)
                if parsed == nil then
                    redraw(false)
                    return
                end
                setValue(parsed, false, true)
            end)

            local controller = {}
            function controller:Set(newValue, ignoreCallback)
                setValue(newValue, ignoreCallback == true, true)
            end
            function controller:GetValue()
                return value
            end
            return controller
        end

        function TabObj:CreateDropdown(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Dropdown")
            local optionsList = type(opt.Options) == "table" and opt.Options or {}
            local multi = opt.MultiSelection == true
            local callback = opt.Callback or function() end

            local function cloneList(source)
                local out = {}
                if type(source) == "table" then
                    for _, item in ipairs(source) do
                        table.insert(out, item)
                    end
                end
                return out
            end

            local current
            if multi then
                local raw = opt.CurrentOption or opt.CurrentValue or {}
                if type(raw) == "table" then
                    current = cloneList(raw)
                elseif raw ~= nil and raw ~= "" then
                    current = { raw }
                else
                    current = {}
                end
            else
                current = opt.CurrentOption
                if current == nil then
                    current = opt.CurrentValue
                end
                if current == nil then
                    current = optionsList[1] or ""
                end
            end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.BackgroundColor3 = MyUI.Theme.Element
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            local stroke = CreateStroke(frame, MyUI.Theme.Outline, 1, 0.12)

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, 44)
            button.BackgroundTransparency = 1
            button.Text = ""
            button.Parent = frame
            SetButtonUX(button)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -46, 1, 0)
            titleText.Position = UDim2.new(0, 14, 0, 0)
            titleText.BackgroundTransparency = 1
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 12
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = button

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.fromOffset(16, 16)
            arrow.Position = UDim2.new(1, -28, 0.5, -8)
            arrow.BackgroundTransparency = 1
            arrow.Image = "rbxassetid://6031091004"
            arrow.ImageColor3 = MyUI.Theme.TextDark
            arrow.Parent = button

            local listFrame = Instance.new("ScrollingFrame")
            listFrame.Size = UDim2.new(1, -20, 1, -52)
            listFrame.Position = UDim2.new(0, 10, 0, 48)
            listFrame.BackgroundTransparency = 1
            listFrame.BorderSizePixel = 0
            listFrame.ScrollBarThickness = 2
            listFrame.ScrollBarImageColor3 = MyUI.Theme.Accent
            listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            listFrame.CanvasSize = UDim2.new()
            listFrame.Parent = frame

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 5)
            listLayout.Parent = listFrame

            local open = false

            local function containsCurrent(item)
                if not multi then
                    return current == item
                end
                return table.find(current, item) ~= nil
            end

            local function updateTitle()
                if multi then
                    if #current == 0 then
                        titleText.Text = name .. "  ·  None selected"
                    elseif #current <= 2 then
                        local display = {}
                        for _, item in ipairs(current) do
                            table.insert(display, tostring(item))
                        end
                        titleText.Text = name .. "  ·  " .. table.concat(display, ", ")
                    else
                        titleText.Text = name .. "  ·  " .. tostring(#current) .. " selected"
                    end
                else
                    titleText.Text = name .. "  ·  " .. tostring(current)
                end
            end

            local function closeDropdown()
                if not open then
                    return
                end
                open = false
                if ActivePopup and ActivePopup.Close == closeDropdown then
                    ActivePopup = nil
                end
                Tween(arrow, {
                    Rotation = 0,
                    ImageColor3 = MyUI.Theme.TextDark,
                }, 0.16)
                Tween(stroke, { Color = MyUI.Theme.Outline }, 0.16)
                Tween(frame, { Size = UDim2.new(1, 0, 0, 44) }, 0.18)
            end

            local function openDropdown()
                if open then
                    closeDropdown()
                    return
                end

                if ActivePopup and ActivePopup.Close ~= closeDropdown then
                    ActivePopup.Close()
                end

                open = true
                ActivePopup = { Close = closeDropdown, Frame = frame }
                local contentHeight = math.clamp(#optionsList * 35, 42, 176)
                Tween(arrow, {
                    Rotation = 180,
                    ImageColor3 = MyUI.Theme.Accent,
                }, 0.16)
                Tween(stroke, { Color = MyUI.Theme.Accent }, 0.16)
                Tween(frame, {
                    Size = UDim2.new(1, 0, 0, 52 + contentHeight),
                }, 0.2)
            end

            local function rebuildList()
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for _, item in ipairs(optionsList) do
                    local selected = containsCurrent(item)
                    local optionButton = Instance.new("TextButton")
                    optionButton.Size = UDim2.new(1, 0, 0, 30)
                    optionButton.BackgroundColor3 = selected
                        and MyUI.Theme.BackgroundAlt
                        or MyUI.Theme.ElementHover
                    optionButton.BackgroundTransparency = selected and 0 or 0.35
                    optionButton.Text = ""
                    optionButton.Parent = listFrame
                    SetButtonUX(optionButton)
                    CreateCorner(optionButton, 7)

                    local optionText = Instance.new("TextLabel")
                    optionText.Size = UDim2.new(1, -34, 1, 0)
                    optionText.Position = UDim2.new(0, 10, 0, 0)
                    optionText.BackgroundTransparency = 1
                    optionText.Text = tostring(item)
                    optionText.TextColor3 = selected and MyUI.Theme.Text or MyUI.Theme.TextDark
                    optionText.Font = selected and Enum.Font.GothamSemibold or Enum.Font.Gotham
                    optionText.TextSize = 11
                    optionText.TextXAlignment = Enum.TextXAlignment.Left
                    optionText.TextTruncate = Enum.TextTruncate.AtEnd
                    optionText.Parent = optionButton

                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.fromOffset(8, 8)
                    dot.Position = UDim2.new(1, -18, 0.5, -4)
                    dot.BackgroundColor3 = selected
                        and MyUI.Theme.Accent
                        or Color3.fromRGB(49, 55, 72)
                    dot.BorderSizePixel = 0
                    dot.Parent = optionButton
                    CreateCorner(dot, 4)

                    optionButton.Activated:Connect(function()
                        if multi then
                            local found = table.find(current, item)
                            if found then
                                table.remove(current, found)
                            else
                                table.insert(current, item)
                            end
                            updateTitle()
                            rebuildList()
                            Dispatch(callback, cloneList(current))
                        else
                            current = item
                            updateTitle()
                            rebuildList()
                            closeDropdown()
                            Dispatch(callback, current)
                        end
                    end)
                end
            end

            button.MouseEnter:Connect(function()
                Tween(frame, { BackgroundColor3 = MyUI.Theme.ElementHover }, 0.12)
            end)
            button.MouseLeave:Connect(function()
                Tween(frame, { BackgroundColor3 = MyUI.Theme.Element }, 0.12)
            end)
            button.Activated:Connect(openDropdown)

            updateTitle()
            rebuildList()

            local controller = {}
            function controller:Refresh(newList, defaultOption)
                optionsList = type(newList) == "table" and newList or {}

                if defaultOption ~= nil then
                    if multi then
                        current = type(defaultOption) == "table"
                            and cloneList(defaultOption)
                            or { defaultOption }
                    else
                        current = defaultOption
                    end
                elseif multi then
                    local filtered = {}
                    for _, selected in ipairs(current) do
                        if table.find(optionsList, selected) then
                            table.insert(filtered, selected)
                        end
                    end
                    current = filtered
                else
                    if not table.find(optionsList, current) then
                        current = optionsList[1] or ""
                    end
                end

                updateTitle()
                rebuildList()
                if open then
                    local contentHeight = math.clamp(#optionsList * 35, 42, 176)
                    frame.Size = UDim2.new(1, 0, 0, 52 + contentHeight)
                end
            end

            function controller:Set(newValue, ignoreCallback)
                if multi then
                    if type(newValue) == "table" then
                        current = cloneList(newValue)
                    elseif newValue ~= nil then
                        current = { newValue }
                    else
                        current = {}
                    end
                else
                    current = newValue ~= nil and newValue or ""
                end

                updateTitle()
                rebuildList()
                if not ignoreCallback then
                    Dispatch(callback, multi and cloneList(current) or current)
                end
            end

            function controller:GetValue()
                return multi and cloneList(current) or current
            end

            return controller
        end

        function TabObj:CreateInput(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Input")
            local placeholder = tostring(opt.PlaceholderText or "Type here...")
            local clearOnFocus = opt.ClearTextOnFocus == true
            local callback = opt.Callback or function() end
            local value = opt.Default
            if value == nil then
                value = opt.CurrentValue
            end
            value = tostring(value or "")

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 46)
            frame.BackgroundColor3 = MyUI.Theme.Element
            frame.BorderSizePixel = 0
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            CreateStroke(frame, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(0.38, -8, 1, 0)
            titleText.Position = UDim2.new(0, 14, 0, 0)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 12
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.62, -22, 0, 30)
            box.Position = UDim2.new(0.38, 8, 0.5, -15)
            box.BackgroundColor3 = MyUI.Theme.BackgroundAlt
            box.Text = value
            box.PlaceholderText = placeholder
            box.PlaceholderColor3 = MyUI.Theme.TextDark
            box.TextColor3 = MyUI.Theme.Text
            box.Font = Enum.Font.Gotham
            box.TextSize = 11
            box.ClearTextOnFocus = clearOnFocus
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Parent = frame
            CreateCorner(box, 7)
            local boxStroke = CreateStroke(box, MyUI.Theme.Outline, 1, 0.1)
            CreateTextPadding(box, 10, 10)

            box.Focused:Connect(function()
                Tween(boxStroke, { Color = MyUI.Theme.Accent }, 0.12)
            end)
            box.FocusLost:Connect(function(enterPressed)
                Tween(boxStroke, { Color = MyUI.Theme.Outline }, 0.12)
                value = box.Text
                Dispatch(callback, value, enterPressed)
            end)

            local controller = {}
            function controller:Set(newText, triggerCallback)
                value = tostring(newText or "")
                box.Text = value
                if triggerCallback then
                    Dispatch(callback, value, true)
                end
            end
            function controller:GetValue()
                return box.Text
            end
            return controller
        end

        function TabObj:CreateKeybind(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Keybind")
            local currentKey = opt.CurrentKey or Enum.KeyCode.E
            local callback = opt.Callback or function() end
            local pressedCallback = opt.PressedCallback
            local listening = false
            local listenConnection

            if typeof(currentKey) ~= "EnumItem" or currentKey.EnumType ~= Enum.KeyCode then
                currentKey = Enum.KeyCode.E
            end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.BackgroundColor3 = MyUI.Theme.Element
            frame.BorderSizePixel = 0
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            CreateStroke(frame, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -122, 1, 0)
            titleText.Position = UDim2.new(0, 14, 0, 0)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 12
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = frame

            local keyButton = Instance.new("TextButton")
            keyButton.Size = UDim2.fromOffset(96, 28)
            keyButton.Position = UDim2.new(1, -108, 0.5, -14)
            keyButton.BackgroundColor3 = MyUI.Theme.BackgroundAlt
            keyButton.Text = currentKey.Name
            keyButton.TextColor3 = MyUI.Theme.Accent
            keyButton.Font = Enum.Font.GothamBold
            keyButton.TextSize = 11
            keyButton.Parent = frame
            SetButtonUX(keyButton)
            CreateCorner(keyButton, 7)
            local keyStroke = CreateStroke(keyButton, MyUI.Theme.Outline, 1, 0.1)

            local function stopListening()
                listening = false
                DisconnectConnection(listenConnection)
                listenConnection = nil
                keyButton.Text = currentKey.Name
                Tween(keyStroke, { Color = MyUI.Theme.Outline }, 0.12)
            end

            keyButton.Activated:Connect(function()
                if listening then
                    return
                end

                listening = true
                keyButton.Text = "Press a key"
                Tween(keyStroke, { Color = MyUI.Theme.Accent }, 0.12)

                listenConnection = TrackConnection(UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Escape then
                        stopListening()
                        return
                    end

                    currentKey = input.KeyCode
                    stopListening()
                    Dispatch(callback, currentKey)
                end))
            end)

            if type(pressedCallback) == "function" then
                TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and not listening and input.KeyCode == currentKey then
                        Dispatch(pressedCallback, currentKey)
                    end
                end))
            end

            local controller = {}
            function controller:Set(newKey, triggerCallback)
                if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
                    currentKey = newKey
                    keyButton.Text = currentKey.Name
                    if triggerCallback then
                        Dispatch(callback, currentKey)
                    end
                end
            end
            function controller:GetValue()
                return currentKey
            end
            return controller
        end

        function TabObj:CreateColorPicker(opt)
            opt = opt or {}
            local name = tostring(opt.Name or "Color Picker")
            local currentColor = opt.Default or opt.CurrentColor or MyUI.Theme.Accent
            local callback = opt.Callback or function() end

            if typeof(currentColor) ~= "Color3" then
                currentColor = MyUI.Theme.Accent
            end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 44)
            frame.BackgroundColor3 = MyUI.Theme.Element
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.Parent = tabPage
            CreateCorner(frame, 10)
            local stroke = CreateStroke(frame, MyUI.Theme.Outline, 1, 0.12)

            local titleText = Instance.new("TextLabel")
            titleText.Size = UDim2.new(1, -76, 0, 44)
            titleText.Position = UDim2.new(0, 14, 0, 0)
            titleText.BackgroundTransparency = 1
            titleText.Text = name
            titleText.TextColor3 = MyUI.Theme.Text
            titleText.Font = Enum.Font.GothamSemibold
            titleText.TextSize = 12
            titleText.TextXAlignment = Enum.TextXAlignment.Left
            titleText.TextTruncate = Enum.TextTruncate.AtEnd
            titleText.Parent = frame

            local swatch = Instance.new("TextButton")
            swatch.Size = UDim2.fromOffset(48, 26)
            swatch.Position = UDim2.new(1, -60, 0, 9)
            swatch.BackgroundColor3 = currentColor
            swatch.Text = ""
            swatch.Parent = frame
            SetButtonUX(swatch)
            CreateCorner(swatch, 7)
            CreateStroke(swatch, Color3.new(1, 1, 1), 1, 0.55)

            local palette = Instance.new("Frame")
            palette.Size = UDim2.new(1, -28, 0, 66)
            palette.Position = UDim2.new(0, 14, 0, 52)
            palette.BackgroundTransparency = 1
            palette.Parent = frame

            local grid = Instance.new("UIGridLayout")
            grid.CellSize = UDim2.fromOffset(30, 30)
            grid.CellPadding = UDim2.fromOffset(8, 6)
            grid.FillDirectionMaxCells = 4
            grid.SortOrder = Enum.SortOrder.LayoutOrder
            grid.Parent = palette

            local presets = opt.Presets or {
                Color3.fromRGB(99, 102, 241),
                Color3.fromRGB(139, 92, 246),
                Color3.fromRGB(59, 130, 246),
                Color3.fromRGB(6, 182, 212),
                Color3.fromRGB(34, 197, 94),
                Color3.fromRGB(245, 158, 11),
                Color3.fromRGB(244, 63, 94),
                Color3.fromRGB(248, 250, 252),
            }

            local open = false
            local function closePicker()
                if not open then
                    return
                end
                open = false
                if ActivePopup and ActivePopup.Close == closePicker then
                    ActivePopup = nil
                end
                Tween(stroke, { Color = MyUI.Theme.Outline }, 0.14)
                Tween(frame, { Size = UDim2.new(1, 0, 0, 44) }, 0.18)
            end

            local function togglePicker()
                if open then
                    closePicker()
                    return
                end
                if ActivePopup and ActivePopup.Close ~= closePicker then
                    ActivePopup.Close()
                end
                open = true
                ActivePopup = { Close = closePicker, Frame = frame }
                Tween(stroke, { Color = MyUI.Theme.Accent }, 0.14)
                Tween(frame, { Size = UDim2.new(1, 0, 0, 126) }, 0.2)
            end

            swatch.Activated:Connect(togglePicker)

            for _, color in ipairs(presets) do
                if typeof(color) == "Color3" then
                    local colorButton = Instance.new("TextButton")
                    colorButton.Size = UDim2.fromOffset(30, 30)
                    colorButton.BackgroundColor3 = color
                    colorButton.Text = ""
                    colorButton.Parent = palette
                    SetButtonUX(colorButton)
                    CreateCorner(colorButton, 9)
                    CreateStroke(colorButton, MyUI.Theme.Outline, 1, 0.15)

                    colorButton.Activated:Connect(function()
                        currentColor = color
                        Tween(swatch, { BackgroundColor3 = currentColor }, 0.14)
                        Dispatch(callback, currentColor)
                        closePicker()
                    end)
                end
            end

            local controller = {}
            function controller:Set(newColor, ignoreCallback)
                if typeof(newColor) == "Color3" then
                    currentColor = newColor
                    swatch.BackgroundColor3 = currentColor
                    if not ignoreCallback then
                        Dispatch(callback, currentColor)
                    end
                end
            end
            function controller:GetValue()
                return currentColor
            end
            return controller
        end

        return TabObj
    end

    updateResponsiveLayout()
    return WindowObj
end

return MyUI
