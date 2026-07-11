wait(10)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat" -- Double-check the weapon name to make sure it is actually "Bat"
local HP_THRESHOLD_PERCENT = 90 -- Equip only when HP is below 40%

print("[⚔️ SYSTEM] Starting Auto Equip - ONLY activates when HP is below 40%...")

-- Function to check and equip the weapon
local function attemptEquip()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        -- Calculate the current health percentage
        local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100

        -- ONLY perform this if health is below or equal to 40%
        if healthPercent <= HP_THRESHOLD_PERCENT then
            -- If the weapon is already equipped, do nothing
            if char:FindFirstChild(WEAPON_NAME) then return end

            local backpack = localPlayer:FindFirstChild("Backpack")
            if backpack then
                local weapon = backpack:FindFirstChild(WEAPON_NAME)
                if weapon and weapon:IsA("Tool") then
                    humanoid:EquipTool(weapon)
                    print("[⚔️ PROTECTION] Low health (" .. math.floor(healthPercent) .. "%). Automatically equipped: " .. WEAPON_NAME)
                end
            end
        end
    end)
end

-- =========================================================================
-- MONITORING AND ACTIVATION MECHANISM
-- =========================================================================

-- Function to listen for changes in the character's health
local function monitorHealth(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        -- Whenever health increases or decreases, check whether it is below 40% to equip the weapon
        humanoid.HealthChanged:Connect(function()
            attemptEquip()
        end)
    end
end

-- 1. Monitor when the character respawns or a new character is assigned
localPlayer.CharacterAdded:Connect(function(char)
    monitorHealth(char)
end)

-- Enable monitoring immediately if the character is already present in the game
if localPlayer.Character then
    monitorHealth(localPlayer.Character)
end

-- 2. Safety scan loop (in case of connection issues or lag)
-- This loop also follows the same condition: only equip the weapon when HP is below 40%
task.spawn(function()
    while true do
        attemptEquip()
        task.wait(3) -- Scan again every 3 seconds
    end
end)

-- Test immediately when the script starts
attemptEquip()

return true
