wait(10)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local jumpCount = 0
local stage5Activated = false -- Flag to prevent duplicate activation

-- Base link to your repository (keep in sync with main.lua)
local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"

local function onCharacterAdded(character)
    -- Wait for Humanoid to fully load
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    
    -- FIX TYPO: change "humanid" to "humanoid" to avoid crashing the script
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            jumpCount = jumpCount + 1
            
            -- Notify the current jump count
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Jump Counter",
                Text = "You have jumped: " .. tostring(jumpCount) .. "/60 times!",
                Duration = 1.5
            })
            
            -- Check if the player has jumped at least 60 times and Stage 5 has not been activated yet
            if jumpCount >= 60 and not stage5Activated then
                stage5Activated = true
                
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "SYSTEM",
                    Text = "You have reached 60 jumps! Activating Stage 5...",
                    Duration = 3
                })
                
                -- Execute Stage5.lua remotely via loadstring
                task.spawn(function()
                    local success, err = pcall(function()
                        return loadstring(game:HttpGet(baseUrl .. "Stage5.lua"))()
                    end)
                    
                    if not success then
                        warn("[ERROR] Unable to load Stage5: " .. tostring(err))
                        -- If there is an error, reset the flag so it can be retried on the next jump
                        stage5Activated = false 
                    end
                end)
            end
        end
    end)
end

-- Start checking the current character and subsequent respawns
if localPlayer.Character then
    task.spawn(onCharacterAdded, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
