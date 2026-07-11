wait(10)
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (GENERATOR)
-- =========================================================================
local function getGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

-- =========================================================================
-- 🔥 HÀM TWEEN DÒ ĐƯỜNG AN TOÀN TỚI MÁY PHÁT ĐIỆN
-- =========================================================================
local function tweenToGenerator(rootPart, genPart)
    if not rootPart or not genPart then return false end
    
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, genPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local dist = (rootPart.Position - waypoint.Position).Magnitude
            local tween = TweenService:Create(rootPart, TweenInfo.new(dist / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
        end
        return true
    else
        -- Nếu Pathfinding lỗi thì Teleport thẳng tới máy phát điện để chữa cháy
        rootPart.CFrame = CFrame.new(genPart.Position + Vector3.new(0, 2, 0))
        return true
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang tìm kiếm và tiến về phía máy phát điện...");

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    
    if genPart then
        -- 1. Tính khoảng cách và di chuyển đến máy phát điện
        local distance = (root.Position - genPart.Position).Magnitude
        if distance > 4 then
            print("[STAGE 2] Đang di chuyển tới máy phát điện...")
            tweenToGenerator(root, genPart)
        end
        
        -- 2. Đã đến nơi thành công -> Chuyển thẳng sang Stage 3
        print("[🎯 STAGE 2 SUCCESS] Đã đến vị trí máy phát điện. Chuyển sang STAGE 3!")
        task.wait(0.3) -- Delay nhỏ để nhân vật đứng vững ổn định vị trí
        _G.CurrentStage = 3
        return true
    else
        -- Trường hợp KHÔNG tìm thấy máy phát điện trên map
        warn("[⚠️ STAGE 2 ERROR] Không tìm thấy máy phát điện trên Map! Quay lại Stage 1...")
        _G.CurrentStage = 1
        return false
    end
else
    warn("[⚠️ STAGE 2 ERROR] Không tìm thấy HumanoidRootPart của nhân vật!")
    return false
end
