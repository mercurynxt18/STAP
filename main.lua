wait(5)
-- =========================================================================
-- [ส่วนที่ 1] สคริปต์เก็บเพชรรายวัน (Daily Reward Automator)
-- =========================================================================
print("[SYSTEM] เริ่มทำงานสคริปต์เก็บเพชรรายวัน...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ฟังก์ชันสำหรับกดรับรางวัล
local function claimDailyReward()
    local success, err = pcall(function()
        -- อ้างอิงไปยัง Remote ตามโครงสร้างที่คุณให้มา
        local weeklyBonus = Workspace:WaitForChild("WeeklyBonus", 5)
        if weeklyBonus then
            local dailyPrompt = weeklyBonus:WaitForChild("DailyPromptTriggered", 5)
            if dailyPrompt and dailyPrompt:IsA("RemoteFunction") then
                -- ส่งสัญญาณไปยัง Server เพื่อรับรางวัล
                dailyPrompt:InvokeServer()
                print("[Reward Automator]: กดรับ Daily Reward สำเร็จแล้ว!")
            else
                print("[Reward Automator]: ไม่พบ RemoteFunction หรือโครงสร้างเปลี่ยนไป")
            end
        else
            print("[Reward Automator]: ไม่พบโฟลเดอร์ WeeklyBonus")
        end
    end)
    
    if not success then
        warn("[Reward Automator] เกิดข้อผิดพลาด: ", err)
    end
end

-- รันเก็บเพชรทันที
claimDailyReward()

-- วนลูปเช็คทุกๆ 1 ชั่วโมง เผื่อกรณีที่คุณเปิดเกมทิ้งไว้นานๆ (ทำงานเบื้องหลัง)
task.spawn(function()
    while task.wait(3600) do 
        claimDailyReward()
    end
end)

-- =========================================================================
-- [รอยต่อ] รอ 3 วินาทีก่อนเริ่มสคริปต์หลัก
-- =========================================================================
print("[SYSTEM] กำลังรอ 3 วินาที เพื่อเริ่มสคริปต์หลัก...")
task.wait(3)

-- =========================================================================
-- [ส่วนที่ 2] สคริปต์หลัก (Main Loader)
-- =========================================================================
-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Ghi lai moc thoi gian bat dau chay Script
local startTimeGlobal = os.clock()
local isForcedRejoining = false 

print("[SYSTEM] Khoi dong Main Loader Mobile Compatible - Fixed Syntax!");

local baseUrl = "https://raw.githubusercontent.com/mercurynxt18/STAP/refs/heads/main/"

-- Định nghĩa các Game ID mục tiêu (Check cả GameId và PlaceId)
local stageGameId = 116139828947259
local joinMapGameId = 90148635862803

local isStageGame = (game.GameId == stageGameId or game.PlaceId == stageGameId)
local isJoinMapGame = (game.GameId == joinMapGameId or game.PlaceId == joinMapGameId)

-- HÀM BYPASS HTTP GET CHO MOBILE (Tự động chọn phương thức tối ưu nhất)
local function customHttpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result and result ~= "" then
        return result
    end
    
    -- Phương án dự phòng nếu game:HttpGet bị lỗi trên Mobile Executor
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httpRequest then
        local resSuccess, response = pcall(function()
            return httpRequest({ Url = url, Method = "GET" })
        end)
        if resSuccess and response and response.Body then
            return response.Body
        end
    end
    return nil
end

-- 🪝 LUỒNG TỰ ĐỘNG LOAD SCRIPT WEBHOOK 
task.spawn(function()
    if _G.Customer_Webhook and _G.Customer_Webhook ~= "" and _G.Customer_Webhook ~= "DAN_URL_WEBHOOK" then
        local content = customHttpGet(baseUrl .. "webhook.lua")
        
        if content and content ~= "" and not string.find(content, "404: Not Found") then
            local func, err = loadstring(content)
            if func then
                func()
            else
                warn("[WEBHOOK] Loi bien dich file webhook.lua: " .. tostring(err))
            end
        else
            warn("[WEBHOOK] Khong the tai file webhook.lua!")
        end
    else
        print("[WEBHOOK] Khong tim thay Webhook hop le. Bo qua buoc gui log.")
    end
end)

-- LUONG EP REJOIN KHAN CAP DUNG 2 PHUT (Tối ưu hóa tránh sập Mobile)
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    while not isForcedRejoining do
        local elapsed = os.clock() - startTimeGlobal
        
        if elapsed >= 120 then
            isForcedRejoining = true
            print("[TIMEOUT] Da cham moc 2 phut!");
            
            local PlayerGui = localPlayer:WaitForChild("PlayerGui", 5)
            if PlayerGui then
                for _, obj in pairs(PlayerGui:GetDescendants()) do
                    if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                        if obj.Visible then
                            pcall(function()
                                if getconnections then
                                    for _, connection in pairs(getconnections(obj.MouseButton1Click)) do 
                                        connection:Fire() 
                                    end
                                end
                            end)
                            obj.MouseButton1Click:Fire()
                            break
                        end
                    end
                end
            end
            
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = game.JobId
            while true do
                pcall(function()
                    TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
                end)
                task.wait(2)
            end
            break
        end
        task.wait(0.5)
    end
end)

-- Ham nap file tu GitHub
local function runFile(fileName)
    if isForcedRejoining then return end

    local content = customHttpGet(baseUrl .. fileName)
    
    if content and content ~= "" then
        content = string.gsub(content, "Enum%.PathJointAction", "Enum.PathWaypointAction")
        content = string.gsub(content, "PathJointAction", "PathWaypointAction")
        
        local func, err = loadstring(content)
        if func then
            print("[RUNNING] Cau phan: " .. fileName)
            func()
        else
            warn("Loi bien dich cau phan: " .. fileName .. " | " .. tostring(err))
        end
    else
        warn("Khong the tai file tu GitHub qua cac cong HTTP: " .. fileName)
    end
end

-- NẠP CÁC FILE ĐIỀU KHIỂN NỀN
task.spawn(function() runFile("Stage0_ZHUB.lua") end)
task.spawn(function() runFile("join_map.lua") end)
task.spawn(function() runFile("camera.lua") end)
task.spawn(function() runFile("AutoEquip.lua") end)
task.spawn(function() runFile("checker.lua") end)

-- STAGE 5 (HÀM XỬ LÝ NÚT PLAY AGAIN KHU VỰC CUỐI TRẬN)
local function runOptimizedStage5()
    if isForcedRejoining then return end
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer

    local PlayerGui = localPlayer:WaitForChild("PlayerGui", 5)
    if not PlayerGui then return end
    
    local foundButton = nil
    local startTime = os.clock()
    
    while not foundButton and (os.clock() - startTime) < 5 and not isForcedRejoining do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                if obj.Visible then
                    foundButton = obj
                    break
                end
            end
        end
        if foundButton then break end
        RunService.Heartbeat:Wait()
    end
    
    if foundButton and not isForcedRejoining then
        pcall(function()
            if getconnections then
                for _, connection in pairs(getconnections(foundButton.MouseButton1Click)) do 
                    connection:Fire() 
                end
            end
        end)
        foundButton.MouseButton1Click:Fire()
        
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
    end
end

-- LUỒNG VẬN HÀNH TUẦN TỰ CHÍNH CỦA GAME
task.spawn(function()
    task.wait(1.0)
    
    if isStageGame then
        print("[SYSTEM] Mobile OK - Chay chuoi Game ID: " .. tostring(stageGameId));
        
        runFile("Stage1_GetFuel.lua")   
        runFile("Stage2_ReturnGen.lua")
        runFile("checkjump.lua")
        runFile("Stage3_RepairBox.lua") 
        runFile("hold.lua")
        
        print("[SYSTEM] Hoan thanh chuoi stage. Chuyen giao sang luong Stage 5!");
        task.wait(15)
        for i = 1, 10 do
            if isForcedRejoining then break end
            print("[ENDGAME] Kiem tra Play Again lan thu: " .. i .. "/10")
            runOptimizedStage5()
            task.wait(1.0)
        end
        
    elseif isJoinMapGame then
        print("[SYSTEM] Mobile OK - Chay Game ID dac biet: " .. tostring(joinMapGameId));
        runFile("join_map.lua")
        
    else
        print("[SYSTEM] ID khong trung khop danh sach target.");
    end
end)
