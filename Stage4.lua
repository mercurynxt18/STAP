local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[📡 PROMPT DETECTOR] Đang khởi chạy trình dò và ép kích hoạt nút E tương tác (Cấu hình: Lặp 10 lần)...");

-- =========================================================================
-- 🔍 HÀM QUÉT TẤT CẢ NÚT INTERACT CỦA POWER BOX
-- =========================================================================
local function findPowerBoxPrompt()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        
        -- Điều kiện 1: Khóa mục tiêu đúng Model có tên là "Power Box"
        if obj:IsA("Model") and obj.Name == "Power Box" then
            -- Điều kiện 2: Quét sâu bên trong để tìm ProximityPrompt tiềm ẩn
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            -- Nếu không tìm thấy ProximityPrompt gốc, kiểm tra xem Part "Prompt" có chứa Prompt ẩn không
            if not prompt then
                local promptPart = obj:FindFirstChild("Prompt")
                if promptPart then
                    prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt")
                end
            end
            
            if prompt then
                return prompt, prompt.Parent -- Trả về khối prompt và Part chứa nó
            end
        end
    end
    return nil, nil
end

-- =========================================================================
-- 🔥 LUỒNG THỰC THI LẶP LẠI 10 LẦN RỒI NGƯNG
-- =========================================================================
for loopCount = 1, 10 do
    print(string.format("\n[🔄 LƯỢT %d / 10] Đang tiến hành quét mục tiêu...", loopCount))
    
    local targetPrompt, parentPart = findPowerBoxPrompt()

    if targetPrompt and parentPart then
        print(string.format("[🎯 DETECTED - LƯỢT %d] Đã phát hiện nút E tại: %s", loopCount, targetPrompt:GetFullName()))
        
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root and parentPart:IsA("BasePart") then
            -- Ép nhân vật dịch chuyển đứng khít vào tọa độ nút để thỏa mãn kiểm tra khoảng cách (Distance Check) của Server
            root.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.1)
        end
        
        -- Kích nổ sự kiện giữ phím E giả lập trên hệ thống mạng
        pcall(function()
            targetPrompt:InputHoldBegin() -- Khởi động trạng thái giữ
        end)
        
        -- Lệnh tối thượng bypass trên cả thiết bị Mobile và PC
        if fireproximityprompt then
            fireproximityprompt(targetPrompt)
            print("[⚡] Đã gửi lệnh fireproximityprompt thành công!")
        end
        
        -- Đồng bộ thông báo kích hoạt lên toàn hệ thống Client
        pcall(function()
            ProximityPromptService:NotifyPromptTriggered(targetPrompt)
        end)
        
        -- Theo dõi cho đến khi máy phát được sửa xong (Vật thể biến mất) ở lượt này
        local maxDuration = 15
        local elapsed = 0
        while targetPrompt and targetPrompt.Parent and elapsed < maxDuration do
            task.wait(0.2)
            elapsed = elapsed + 0.2
        end
        
        -- Giải phóng trạng thái nhấn giữ sau khi hoàn thành lượt
        pcall(function()
            targetPrompt:InputHoldEnd()
        end)
        print(string.format("[🎉] Kết thúc tương tác lượt thứ %d!", loopCount));
    else
        warn(string.format("[⚠️ NOT FOUND - LƯỢT %d] Không thấy đối tượng Power Box nào xuất hiện.", loopCount));
    end
    
    -- Khoảng nghỉ ngắn (0.5 giây) giữa các lượt lặp để tránh spam quá nhanh gây drop FPS hoặc check từ server
    task.wait(0.5)
end

print("\n[🏁 HOÀN THÀNH] Đã chạy đủ 10 lần lập định. Hệ thống tự động dừng script.");
