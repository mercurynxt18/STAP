-- =========================================================================
-- 🚀 DISCORD WEBHOOK LOG - CHỈ GỬI ĐÚNG 1 LẦN DUY NHẤT (ANTI-SPAM)
-- =========================================================================

-- Sử dụng biến toàn cục để kiểm tra xem script này đã từng chạy trong server này chưa
if _G.Webhook_Already_Sent then 
    print("[WEBHOOK] He thong da gui thong bao truoc do. Bo qua de tranh spam!")
    return 
end

local request = http_request or request or syn.request
if request then
    task.spawn(function()
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        
        while not localPlayer do
            task.wait(0.5)
            localPlayer = players.LocalPlayer
        end
        
        -- Chờ PlayerGui xuất hiện ổn định
        local playerGui = localPlayer:WaitForChild("PlayerGui", 20)
        if not playerGui then return end

        -- Tìm và đợi giao diện MainUI hiển thị số lượng Gem
        local mainUI = playerGui:WaitForChild("MainUI", 20)
        local gemCount = nil
        
        if mainUI then
            gemCount = mainUI:FindFirstChild("GemDisplay") and mainUI.GemDisplay:FindFirstChild("Count")
            local timeout = 0
            while not gemCount and timeout < 10 do
                pcall(function()
                    gemCount = playerGui.MainUI.GemDisplay.Count
                end)
                if gemCount then break end
                task.wait(0.5)
                timeout = timeout + 0.5
            end
        end

        -- Lấy văn bản Gem hiển thị thực tế trên màn hình
        local currentGem = "0"
        if gemCount then
            currentGem = gemCount.Text
        end

        -- Khởi tạo cấu trúc Embed gửi Discord chỉn chu
        local payload = {
            ["embeds"] = {{
                ["title"] = "💎 THÔNG BÁO SỐ LƯỢNG GEM 💎",
                ["color"] = 65430, -- Màu xanh Neon
                ["fields"] = {
                    {
    ["name"] = "👤 Tên nhân vật:",
    -- Thêm || ở đầu và cuối để tạo hiệu ứng ẩn chữ trên Discord
    ["value"] = "||`" .. localPlayer.Name .. "`||",
    ["inline"] = true
},

                    {
                        ["name"] = "💎 Số lượng Gem hiện tại:",
                        ["value"] = "**" .. tostring(currentGem) .. "**",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🎮 Game ID:",
                        ["value"] = "||`" .. tostring(game.PlaceId) .. "`||",
                        ["inline"] = true
                    }
                },
                ["footer"] = {
                    ["text"] = "Hệ thống vận hành tự động"
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }}
        }

        -- Đánh dấu trạng thái ĐÃ GỬI ngay lập tức trước khi request thực hiện xong (Khóa luồng)
        _G.Webhook_Already_Sent = true

        pcall(function()
            request({
                Url = _G.Customer_Webhook,
                Method = "POST",
                Headers = {["content-type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(payload)
            })
            print("[🚀 SYSTEM] Webhook chuan da keu thanh cong (Duy nhat 1 lan)!")
        end)
    end)
end
