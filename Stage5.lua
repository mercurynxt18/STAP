local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- =========================================================================
-- 🔥 HÀM CLICK THẦN TỐC (BYPASS HOÀN TOÀN TRỄ)
-- =========================================================================
local function secureClickThantoc(button)
    if not button then return false end
    if not button.Visible or button.AbsoluteSize.X == 0 or button.AbsoluteSize.Y == 0 then
        return false
    end

    print("[Action] Kích hoạt chuỗi click thần tốc cho: " .. button.Name)
    
    -- Gửi tín hiệu kích nổ sự kiện click đồng thời để không bị nuốt lệnh
    if getconnections then
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do connection:Fire() end
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do connection:Fire() end
    end
    button.MouseButton1Click:Fire()
    return true
end

-- =========================================================================
-- ⏳ LUỒNG THEO DÕI GIAO DIỆN VÀ REJOIN SIÊU TỐC
-- =========================================================================
print("[⏳ STAGE 5] Kích hoạt quét UI và Rejoin siêu tốc...")

task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local startTime = os.clock()
    
    -- Quét tần suất cực cao bằng Heartbeat (Bắt trúng khung hình nút xuất hiện sớm nhất)
    while not foundButton and (os.clock() - startTime) < 20 do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                if obj.Visible and obj.AbsolutePosition.Y > 0 then
                    foundButton = obj
                    break
                end
            end
        end
        if foundButton then break end
        RunService.Heartbeat:Wait() -- Chờ theo mili-giây thay vì task.wait(0.3) lề mề cũ
    end
    
    -- Xử lý Rejoin ngay lập tức khi phát hiện ra nút
    if foundButton then
        print("[🎯 SUCCESS] Tìm thấy nút Play Again. Nhấn và nhảy server tức thì...")
        
        -- Gọi hàm click không delay
        secureClickThantoc(foundButton)
        
        -- Thực hiện Rejoin ép về đúng phòng (Server Instance) hiện tại ngay lập tức
        print("[🚀] Thực hiện Rejoin Bypass...")
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        
        local success, err = pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
        
        if not success then 
            warn("[Error] Lỗi Rejoin: " .. tostring(err)) 
        end
    else
        warn("[Timeout] Quá 20 giây chờ nhưng không thấy nút Play Again xuất hiện!")
    end
end)
