wait(10)
-- Wait for the game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 AUTO LOBBY LOADER] Starting the automatic load sequence into the match...")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local LobbyRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Lobby")

-- Function to trigger UI click events (fully bypassing delay on Mobile)
local function safeClick(button)
    if not button then return false end
    if getconnections then
        local clicked = false
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do connection:Fire() clicked = true end
        for _, connection in pairs(getconnections(button.Activated)) do connection:Fire() clicked = true end
        if clicked then return true end
    end
    local success = pcall(function() button.MouseButton1Click:Fire() end)
    return success
end

-- =========================================================================
-- 🏃 STEP 1: FIND AN ENTIRELY EMPTY SLOT (0 PLAYERS) TO CLAIM A SOLO ROOM
-- =========================================================================
local lobbiesFolder = Workspace:FindFirstChild("Lobbies")
local targetHitbox = nil
local selectedRoom = nil

if lobbiesFolder then
    -- Quickly scan the 10 lobby rooms
    for i = 1, 10 do
        local lobby = lobbiesFolder:FindFirstChild(tostring(i))
        if lobby then
            local labelObj = lobby:FindFirstChildWhichIsA("TextLabel", true) or lobby:FindFirstChild("Status", true)
            
            -- Check whether the room displays an empty status (0 people or "0/")
            if labelObj and (string.find(labelObj.Text, "0/") or string.find(labelObj.Text, "0 Players")) then
                local hitbox = lobby:FindFirstChild("Hitbox") or lobby:FindFirstChildWhichIsA("BasePart")
                if hitbox then
                    targetHitbox = hitbox
                    selectedRoom = i
                    break
                end
            end
        end
    end
end

-- =========================================================================
-- ⚡ STEP 2: CLAIM THE ROOM AND LOCK IT TO 1 PLAYER (SOLO BYPASS)
-- =========================================================================
if targetHitbox then
    print("[💎] Found an empty room number " .. selectedRoom .. "! Claiming the room...")
    
    local char = localPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        -- Instantly move the character to the lobby hitbox to trigger the physical room join event
        rootPart.CFrame = targetHitbox.CFrame
        task.wait(0.3) -- Wait for the network response to sync
    end
    
    -- Send the Remote request to create an independent lobby party
    pcall(function()
        LobbyRemotes.CreateParty:InvokeServer()
    end)
    
    task.wait(1.2) -- Wait for the "CreateParty" UI to appear fully on screen
    
    -- FORCE THE SERVER: reduce the room size limit to 1 player to prevent others from joining
    print("[⚙️] Forcing the server to reduce the room limit to 1 player to lock Solo...")
    pcall(function()
        LobbyRemotes.SetPartySize:InvokeServer(1)
    end)
    
    task.wait(0.5) -- Wait for the server data to update the room limit to 1/1
    
    -- Locate the "Create" button in the UI to load the map
    local createButton = playerGui:FindFirstChild("Main") 
        and playerGui.Main:FindFirstChild("CreateParty") 
        and playerGui.Main.CreateParty:FindFirstChild("Create")
    
    if createButton then
        print("[🔥] Solo room lock successful! Pressing the button to start loading the map...")
        safeClick(createButton)
    else
        -- Fallback mechanism: if the UI is hidden or the button cannot be found, force the server to load the solo match via Remote
        print("[⚠️] The UI button was not found, sending a Remote command to force the solo match to start...")
        pcall(function()
            LobbyRemotes.JoinLobby:InvokeServer("")
        end)
    end
else
    -- =========================================================================
    -- 🚨 FALLBACK MECHANISM: CREATE AN ISOLATED ROOM WHEN THE LOBBY HAS NO EMPTY SLOTS
    -- =========================================================================
    warn("[⚠️] The entire lobby is full! Activating the emergency isolated solo room protocol...")
    
    pcall(function()
        LobbyRemotes.CreateParty:InvokeServer()
        task.wait(0.5)
        LobbyRemotes.SetPartySize:InvokeServer(1)
        task.wait(0.5)
        LobbyRemotes.JoinLobby:InvokeServer("")
    end)
end

return true
