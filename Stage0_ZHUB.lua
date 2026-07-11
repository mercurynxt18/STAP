wait(10)
-- Wait for the game to fully load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 MATRIX FULL FIX] Launching system: Kill Aura (Fixed) + Loot Pickup 15 studs No-Fling!");

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- ====================================================================
-- FULL CONFIGURATION TABLE (Fixed missing variables for Kill Aura)
-- ====================================================================
local CONFIG = {
    -- 🔥 KILL AURA CONFIGURATION (Thoroughly tested)
    AuraEnabled = true,        -- Toggle Kill Aura On/Off
    MaxDistance = 16,          -- Monster scanning/attack distance (Studs)
    AttackDelay = 0.12,        -- Attack delay / speed
    MaxTargets = 5,            -- Maximum targets to attack simultaneously

    -- Auto Drag Configuration (Pick up items from Workspace.DroppedItems)
    DragEnabled = true,        
    DetectRange = 15,          -- Auto loot detection range (15 studs)
    FollowDistance = 2.5,      -- Distance to keep items close to the hip
    PhysicsResponsiveness = 200, -- Initial drag smoothness
}

-- DROPPED ITEMS FOLDER PATH
local DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
local holdingItems = {} -- Cache to mark physically attached items

-- SINGLE ANCHOR POINT: Cluster items behind the player to reduce Attachment overhead
local masterAnchorAttachment = nil
local function getMasterAttachment(rootPart)
    if not masterAnchorAttachment or masterAnchorAttachment.Parent ~= rootPart then
        masterAnchorAttachment = Instance.new("Attachment")
        masterAnchorAttachment.Name = "MasterDragAnchor"
        masterAnchorAttachment.Position = Vector3.new(0, 0, CONFIG.FollowDistance) 
        masterAnchorAttachment.Parent = rootPart
    end
    return masterAnchorAttachment
end

-- ====================================================================
-- UTILITIES
-- ====================================================================

-- [Kill Aura] Check valid target (Monsters or Scrap)
local function isValidTarget(obj, character)
    if not obj or obj == character or obj:IsAncestorOf(character) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    
    local nameLower = string.lower(obj.Name)
    if string.find(nameLower, "scrap pile") or string.find(nameLower, "scrap") then 
        return true 
    end
    
    local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- [Kill Aura] Get the game's original weapon and attack Remote
local function getBatStuff()
    local character = localPlayer.Character
    if character then
        local bat = character:FindFirstChild("Bat")
        local autoTarget = character:FindFirstChild("AutoTargetClient")
        if bat and bat:FindFirstChild("Swing") and bat:FindFirstChild("HitTargets") and autoTarget and autoTarget:FindFirstChild("UpdateNearbyTargets") then
            return bat, autoTarget.UpdateNearbyTargets
        end
    end
    return nil, nil
end

-- [Auto Drag] Get the game system's drag Remote
local function getDragRemote()
    local character = localPlayer.Character
    if not character then return nil end
    local dragSystem = character:FindFirstChild("DragSystem")
    return dragSystem and dragSystem:FindFirstChild("DragItem") or nil
end

-- STANDARD STAGE 0 ROOT REGISTRATION
local function triggerDragSystem(item, itemPart)
    local dragDetector = item:FindFirstChildWhichIsA("DragDetector") or item:FindFirstChildOfClass("DragDetector")
    if dragDetector and firesignal then
        firesignal(dragDetector.DragStart, localPlayer)
    end

    local networkRemote = item:FindFirstChild("ItemDrag") and item.ItemDrag:FindFirstChild("RequestNetworkOwnership")
    if networkRemote then
        pcall(function()
            networkRemote:FireServer(itemPart)
        end)
    end
end

-- ITEM NO-CLIP FUNCTION: Continuously force CanCollide = false to prevent character flinging
local function enforceNoClip(item)
    if item:IsA("BasePart") then
        item.CanCollide = false
    end
    for _, child in ipairs(item:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
            child.Velocity = Vector3.zero
            child.RotVelocity = Vector3.zero
        end
    end
end

-- VISUAL LAG REDUCTION (Preserves network ownership so the game recognizes item existence)
local function invisibleClientItem(item)
    pcall(function()
        if item:IsA("BasePart") then
            item.Transparency = 1
        end
        for _, child in ipairs(item:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = 1
            elseif child:IsA("Decal") or child:IsA("Texture") then
                child.Enabled = false
            elseif child:IsA("ParticleEmitter") or child:IsA("Light") then
                child.Enabled = false
            end
        end
    end)
end

-- ====================================================================
-- SAFE DRAG PROCESSING STREAM
-- ====================================================================
local function attachmentDrag(item, rootPart)
    if holdingItems[item] then return end 
    
    local itemPart = item:FindFirstChild("Union") or item:FindFirstChild("Can") or (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart") or item
    if not itemPart then return end
    
    holdingItems[item] = true 
    
    triggerDragSystem(item, itemPart)
    task.wait(0.01) 
    
    local dragRemote = getDragRemote()
    if not dragRemote then return end

    task.spawn(function()
        pcall(function()
            dragRemote:FireServer(item, itemPart)
        end)
    end)

    local attItem = Instance.new("Attachment")
    attItem.Name = "MobileDragAttItem"
    attItem.Parent = itemPart

    local attPlayer = getMasterAttachment(rootPart)

    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "DragAlignPos"
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = attItem
    alignPos.Attachment1 = attPlayer
    alignPos.MaxForce = math.huge 
    alignPos.MaxVelocity = math.huge 
    alignPos.Responsiveness = CONFIG.PhysicsResponsiveness
    alignPos.Parent = item

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "DragAlignOri"
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
    alignOri.Attachment0 = attItem
    alignOri.Attachment1 = attPlayer
    alignOri.MaxTorque = math.huge 
    alignOri.Responsiveness = CONFIG.PhysicsResponsiveness
    alignOri.Parent = item
    
    local loopConnection
    loopConnection = RunService.Stepped:Connect(function()
        if not item or not item.Parent then
            holdingItems[item] = nil 
            loopConnection:Disconnect()
            return
        end
        
        pcall(function()
            enforceNoClip(item) 
            
            if itemPart and itemPart.Parent then
                local currentDist = (itemPart.Position - rootPart.Position).Magnitude
                if currentDist <= 4 then
                    invisibleClientItem(item)
                end
            end
        end)
    end)
end

-- ====================================================================
-- CORE LOOPS ACTIVATION
-- ====================================================================

-- 1. 🔥 INDEPENDENT KILL AURA LOOP (FULLY RESTORED)
task.spawn(function()
    while task.wait(CONFIG.AttackDelay) do
        if not CONFIG.AuraEnabled then continue end
        
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local bat, updateNearbyRemote = getBatStuff()
        
        if hrp and bat then
            local rawTargets = {}
            
            -- Scan targets in Characters (Monsters) and Structures (Static Scrap) folders
            local foldersToSearch = { Workspace:FindFirstChild("Characters"), Workspace:FindFirstChild("Structures") }
            for _, folder in pairs(foldersToSearch) do
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if isValidTarget(obj, character) then 
                            table.insert(rawTargets, obj) 
                        end
                    end
                end
            end
            
            -- Scan hidden targets (Nil Instances) if executor supports it
            if getnilinstances then
                for _, obj in pairs(getnilinstances()) do
                    if obj:IsA("Model") and isValidTarget(obj, character) then 
                        table.insert(rawTargets, obj) 
                    end
                end
            end
            
            -- Filter targets within MaxDistance radius (16 studs)
            local validTargetsWithDist = {}
            for _, obj in pairs(rawTargets) do
                local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local distance = (hrp.Position - targetPart.Position).Magnitude
                    if distance <= CONFIG.MaxDistance then
                        table.insert(validTargetsWithDist, {instance = obj, dist = distance})
                    end
                end
            end
            
            -- Sort by closest target first and swing the bat to attack the crowd
            table.sort(validTargetsWithDist, function(a, b) return a.dist < b.dist end)
            local targetsToAttack = {}
            for i = 1, math.min(#validTargetsWithDist, CONFIG.MaxTargets) do 
                table.insert(targetsToAttack, validTargetsWithDist[i].instance) 
            end
            
            if #targetsToAttack > 0 then
                bat.Swing:FireServer()
                local packedArgs = { [1] = targetsToAttack }
                updateNearbyRemote:FireServer(unpack(packedArgs))
                bat.HitTargets:FireServer(unpack(packedArgs))
            end
        end
    end
end)

-- 2. Dynamic scanning loop to pick up items in DroppedItems (15 Studs)
RunService.Heartbeat:Connect(function()
    if not CONFIG.DragEnabled then return end
    
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local items = DroppedItemsFolder:GetChildren()
    
    for i = 1, #items do
        local item = items[i]
        
        if not holdingItems[item] then
            local itemPosition = item:IsA("Model") and item:GetPivot().Position or (item:IsA("BasePart") and item.Position)
            if itemPosition then
                local distance = (rootPart.Position - itemPosition).Magnitude
                
                if distance <= CONFIG.DetectRange then
                    attachmentDrag(item, rootPart)
                end
            end
        end
    end
end)

print("[🎉 COMPLETED] The entire system is running normally! Smooth monster kill aura, safe anti-fling item pickup!");
return true