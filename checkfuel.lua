wait(10)
-- ====================================================================
-- STEP CHECK: CHECK FUEL (WITH TIMEOUT MECHANISM TO RETURN TO STAGE 1)
-- ====================================================================

local TIMEOUT_DURATION = 10 -- Timeout limit of 10 seconds
local hasTriggered = false
local startTime = tick()

-- Function to return to Stage 1 when the timeout expires
local function abortAndReturnToStage1()
    if hasTriggered then return end
    hasTriggered = true
    
    warn("⏳ [TIMEOUT] CrateOpened was not found within " .. TIMEOUT_DURATION .. "s. Returning to STAGE 1...")
    
    -- Clean up the UI
    local player = game:GetService("Players").LocalPlayer
    local ui = player.PlayerGui:FindFirstChild("CheckFuelUI")
    if ui then ui:Destroy() end
    
    -- Return to Stage 1
    _G.CurrentStage = 1
end

-- Function to transition to Stage 3 (keep the existing logic)
local function loadStage3()
    if hasTriggered then return end
    hasTriggered = true 
    
    print("🚨 [CHECK FUEL SUCCESS] CrateOpened signal detected!")
    -- ... (giữ nguyên đoạn code loadStage3 của bạn ở đây) ...
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/Stage3_RepairBox.lua"))()
        end)
        if not success then warn("Failed to load Stage 3: " .. tostring(err)) end
    end)
end

-- ADD A TIME CHECK LOOP (TIMEOUT MONITOR)
task.spawn(function()
    while not hasTriggered do
        task.wait(1)
        if (tick() - startTime) > TIMEOUT_DURATION then
            abortAndReturnToStage1()
            break
        end
    end
end)

-- ... (Keep the existing metatable hook or map scan logic here) ...
