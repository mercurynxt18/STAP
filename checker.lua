-- =========================================================================
-- 💎 ULTIMATE SCI-FI FULLSCREEN HUB (WITH TOGGLE BUTTON)
-- =========================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Đường dẫn link ảnh RAW từ GitHub của bạn
local GitHub_Image_URL = ""
local Local_File_Name = ""
local Asset_ID = ""

-- [XỬ LÝ TẢI ẢNH NGOÀI ROBLOX]
local success, err = pcall(function()
    if writefile and readfile and getcustomasset then
        if not isfile(Local_File_Name) then
            writefile(Local_File_Name, game:HttpGet(GitHub_Image_URL))
        end
        Asset_ID = getcustomasset(Local_File_Name)
    else
        Asset_ID = "" 
    end
end)

if not success or Asset_ID == "" then
    Asset_ID = ""
end

-- 1. TẠO KHUNG CHÍNH (SCREEN GUI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Gemini_UltimateToggleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Tràn viền hoàn toàn
ScreenGui.Parent = PlayerGui

-- Khung chứa toàn bộ nội dung Hub (Dùng để ẩn/hiện hàng loạt)
local HubContent = Instance.new("Frame")
HubContent.Size = UDim2.new(1, 0, 1, 0)
HubContent.BackgroundTransparency = 1
HubContent.BorderSizePixel = 0
HubContent.Visible = true -- Trạng thái mặc định là hiển thị
HubContent.Parent = ScreenGui

-- 2. HÌNH NỀN FULLSCREEN
local AnimeBackground = Instance.new("ImageLabel")
AnimeBackground.Size = UDim2.new(1, 0, 1, 0)
AnimeBackground.Image = Asset_ID
AnimeBackground.ScaleType = Enum.ScaleType.Crop
AnimeBackground.Parent = HubContent

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
DarkOverlay.BackgroundTransparency = 0.4
DarkOverlay.BorderSizePixel = 0
DarkOverlay.Parent = HubContent

-- 3. TRUNG TÂM ĐIỀU KHIỂN & THEO DÕI THÔNG SỐ (CENTER PANEL)
local InfoArea = Instance.new("Frame")
InfoArea.Size = UDim2.new(0, 400, 0, 150)
InfoArea.Position = UDim2.new(0.5, -200, 0.75, -75)
InfoArea.BackgroundColor3 = Color3.fromRGB(15, 22, 28)
InfoArea.BackgroundTransparency = 0.25
InfoArea.BorderSizePixel = 0
InfoArea.Parent = HubContent

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 12)
InfoCorner.Parent = InfoArea

local InfoStroke = Instance.new("UIStroke")
InfoStroke.Color = Color3.fromRGB(0, 230, 255)
InfoStroke.Thickness = 1.5
InfoStroke.Parent = InfoArea

local SystemTag = Instance.new("TextLabel")
SystemTag.Size = UDim2.new(1, -30, 0, 25)
SystemTag.Position = UDim2.new(0, 20, 0, 15)
SystemTag.Text = "♦ tinhub"
SystemTag.TextColor3 = Color3.fromRGB(140, 160, 180)
SystemTag.TextSize = 11
SystemTag.Font = Enum.Font.Code
SystemTag.TextXAlignment = Enum.TextXAlignment.Left
SystemTag.BackgroundTransparency = 1
SystemTag.Parent = InfoArea

local GemValueLabel = Instance.new("TextLabel")
GemValueLabel.Size = UDim2.new(1, -30, 0, 50)
GemValueLabel.Position = UDim2.new(0, 20, 0, 40)
GemValueLabel.Text = "💎 Loading..."
GemValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GemValueLabel.TextSize = 36
GemValueLabel.Font = Enum.Font.GothamBold
GemValueLabel.TextXAlignment = Enum.TextXAlignment.Left
GemValueLabel.BackgroundTransparency = 1
GemValueLabel.Parent = InfoArea

local TextStroke = Instance.new("UIStroke")
TextStroke.Color = Color3.fromRGB(0, 230, 255)
TextStroke.Thickness = 0.5
TextStroke.Transparency = 0.5
TextStroke.Parent = GemValueLabel

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -40, 0, 3)
StatusBar.Position = UDim2.new(0, 20, 0, 95)
StatusBar.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = InfoArea

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(0, 2)
BarCorner.Parent = StatusBar

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -30, 0, 20)
StatusText.Position = UDim2.new(0, 20, 0, 105)
StatusText.Text = "STATUS: INITIALIZING GAME LINK..."
StatusText.TextColor3 = Color3.fromRGB(0, 230, 255)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.Code
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.BackgroundTransparency = 1
StatusText.Parent = InfoArea

-- =========================================================================
-- 4. NÚT BẤM ẨN / HIỆN TẤT CẢ (TOGGLE BUTTON)
-- =========================================================================
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 80, 0, 30)
ToggleButton.Position = UDim2.new(0, 20, 0, 40) 
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 22, 28)
ToggleButton.Text = "ẨN HUB"
ToggleButton.TextColor3 = Color3.fromRGB(0, 230, 255)
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ScreenGui

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = ToggleButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Color = Color3.fromRGB(0, 230, 255)
ButtonStroke.Thickness = 1
ButtonStroke.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    if HubContent.Visible == true then
        HubContent.Visible = false
        ToggleButton.Text = "HIỆN HUB"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ButtonStroke.Color = Color3.fromRGB(100, 100, 100)
    else
        HubContent.Visible = true
        ToggleButton.Text = "ẨN HUB"
        ToggleButton.TextColor3 = Color3.fromRGB(0, 230, 255)
        ButtonStroke.Color = Color3.fromRGB(0, 230, 255)
    end
end)

-- =========================================================================
-- LOGIC ĐỒNG BỘ GEM GỐC (CHỈ ĐỌC DỮ LIỆU TỪ GAME)
-- =========================================================================
local function updateGemDisplay(text)
    GemValueLabel.Text = "💎 " .. tostring(text)
end

task.spawn(function()
    -- Hệ thống đợi tìm UI chứa chỉ số Gem của game (Tối đa 15 giây)
    local mainUI = PlayerGui:WaitForChild("MainUI", 15)
    local gemDisplay = mainUI and mainUI:WaitForChild("GemDisplay", 15)
    local gemCountObject = gemDisplay and gemDisplay:WaitForChild("Count", 15)

    -- Vòng lặp quét dự phòng nếu game tải UI chậm
    while not gemCountObject do
        pcall(function()
            gemCountObject = PlayerGui.MainUI.GemDisplay.Count
        end)
        if gemCountObject then break end
        task.wait(0.5)
    end

    -- Nếu tìm thấy đúng đối tượng chứa dữ liệu Gem
    if gemCountObject then
        -- Cập nhật dữ liệu hiện tại ngay lập tức
        updateGemDisplay(gemCountObject.Text)
        StatusText.Text = "STATUS: ACTIVE // LIVE_DATA_CONNECTED"
        
        -- Lắng nghe sự thay đổi: Mỗi khi game thay đổi số Gem, Hub tự cập nhật theo (Chỉ đọc)
        gemCountObject:GetPropertyChangedSignal("Text"):Connect(function()
            updateGemDisplay(gemCountObject.Text)
        end)
        print("[🚀 SYSTEM] Đã kết nối thành công dữ liệu Gem thực tế!");
    else
        -- Trường hợp không tìm thấy UI (Ví dụ: Sai game hoặc UI đã thay đổi cấu trúc)
        GemValueLabel.Text = "💎 NOT FOUND";
        GemValueLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
        StatusText.Text = "STATUS: ERROR // CANNOT_LINK_GEM_DATA"
    end
end)
