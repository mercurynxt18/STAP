wait(10)
-- =========================================================================
-- ⚙️ SYSTEM CONFIGURATION (CONFIG) - EDIT HERE
-- =========================================================================
local CONFIG = {
    -- [BLACKLIST OF RUIN AREAS TO AVOID]
    RUINS_NAMES = {"Broken1", "Broken2", "Assets"}, -- Names of the ruin models from your image
    MIN_DISTANCE_FROM_RUINS = 8, -- Minimum safe distance (studs) from fuel to the ruin pile

    -- [AUTO-REORIENT AFTER TIMEOUT]
    MAX_TARGET_TIME = 10,      -- AUTO-REORIENT: After 10 seconds without picking up this can, skip it immediately!

    -- [MOVEMENT & TWEEN]
    TWEEN_SPEED = 28,          -- Movement speed
    
    -- [PATHFINDING - AVOID OBSTACLES]
    AGENT_RADIUS = 5.5,        -- Obstacle avoidance radius (to avoid scraping walls)
    AGENT_HEIGHT = 5.0,        -- Simulated character height
    AGENT_CAN_JUMP = true,     -- Allow jumping when computing the path
    
    -- [RAYCAST SCANNING TO AVOID WALLS]
    RAY_CHECK_DISTANCE = 2.8,  -- Distance for scanning walls ahead (studs)
    RAY_ANGLE = 25,            -- Spread angle of the two diagonal rays (degrees)
    LEG_HEIGHT_LIMIT = 1.8,    -- Lower leg height: below this level, climbing is allowed
    
    -- [DISTANCE TO STOP PICKING UP ITEMS]
    STOP_DISTANCE = 3.3,       -- Distance from the fuel to stop and pick it up (studs)
    FINAL_REACH_DIST = 4.0,    -- Maximum acceptable distance to consider the path complete
    
    -- [MAIN LOOP]
    TOTAL_CYCLES = 2,          -- Number of fuel cans to collect
    MAX_STUCK_ATTEMPTS = 3,    -- Maximum number of stuck attempts on one fuel can before deciding to skip it
}

-- =========================================================================
-- INITIALIZE ROBLOX SERVICES
-- =========================================================================
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local path = PathfindingService:CreatePath({
    AgentRadius = CONFIG.AGENT_RADIUS,    
    AgentHeight = CONFIG.AGENT_HEIGHT, 
    AgentCanJump = CONFIG.AGENT_CAN_JUMP
})
local ignoredFuels = {}

-- =========================================================================
-- 🛠️ FUNCTION TO CHECK WHETHER FUEL IS INSIDE OR NEAR A DANGEROUS RUIN AREA
-- =========================================================================
local function isInsideOrNearRuins(fuelPart)
    -- 1. Check whether the fuel is a descendant of a ruin pile
    for _, ruinName in ipairs(CONFIG.RUINS_NAMES) do
        if fuelPart:FindFirstAncestor(ruinName) then
            return true -- Inside the ruin structure -> SKIP!
        end
    end
    
    -- 2. Check the physical distance around the area for any ruin pile
    for _, obj in pairs(Workspace:GetDescendants()) do
        for _, ruinName in ipairs(CONFIG.RUINS_NAMES) do
            if obj.Name == ruinName and (obj:IsA("Model") or obj:IsA("Folder")) then
                -- Find a central Part to calculate the distance
                local pivotPart = obj:IsA("Model") and obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if pivotPart then
                    local distToRuin = (fuelPart.Position - pivotPart.Position).Magnitude
                    if distToRuin <= CONFIG.MIN_DISTANCE_FROM_RUINS then
                        return true -- Too close to a hazardous ruin area -> SKIP!
                    end
                end
            end
        end
    end
    
    return false
end

-- Function to locate the nearest fuel (with ruin-avoidance filtering built in)
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and obj:IsA("Model") and not ignoredFuels[obj] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                -- CHECK THE RUIN FILTER
                if not isInsideOrNearRuins(part) then
                    local dist = (rootPosition - part.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        nearestFuel = part
                    end
                else
                    -- If the fuel is detected inside a ruin area, add it to the blacklist to reduce future scanning
                    ignoredFuels[obj] = true
                    print("[-] Detected and actively avoided a fuel can inside a rough ruin area!")
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- 🕵️ 3-RAY RAYCAST VISION - FILTER OUT OBSTACLES LOWER THAN HALF THE LEG HEIGHT
-- =========================================================================
local function isWallInFront(rootPart, targetPosition, checkDistance)
    local origin = rootPart.Position + Vector3.new(0, CONFIG.LEG_HEIGHT_LIMIT - 2, 0)
    local mainDirection = (targetPosition - rootPart.Position).Unit
    
    local directions = {
        mainDirection,
        (CFrame.Angles(0, math.rad(CONFIG.RAY_ANGLE), 0) * mainDirection),
        (CFrame.Angles(0, math.rad(-CONFIG.RAY_ANGLE), 0) * mainDirection)
    }
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {rootPart.Parent}
    
    for _, dir in ipairs(directions) do
        local raycastResult = Workspace:Raycast(origin, dir * checkDistance, raycastParams)
        if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
            if raycastResult.Instance.Name ~= "Fuel" and raycastResult.Instance.Parent.Name ~= "Fuel" then
                local hitHeight = raycastResult.Position.Y - (rootPart.Position.Y - 2.5)
                if hitHeight > CONFIG.LEG_HEIGHT_LIMIT then
                    return true
                end
            end
        end
    end
    return false
end

-- =========================================================================
-- 🔥 SMART MOVEMENT FUNCTION - WITH EMERGENCY TIMEOUT COUNTER
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart, startTime)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        local i = 1
        while i <= totalWaypoints do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- CHECK THE GLOBAL TIMEOUT (10 SECONDS)
            if (os.clock() - startTime) >= CONFIG.MAX_TARGET_TIME then
                print("[⏳ TIMEOUT] The time limit for this fuel can has expired, changing direction immediately!")
                return false
            end
            
            -- CONDITION 1: Check the stopping distance continuously
            local distanceToFuel = (rootPart.Position - targetPart.Position).Magnitude
            if distanceToFuel <= CONFIG.STOP_DISTANCE then
                return true 
            end
            
            local waypoint = waypoints[i]
            local targetPos = Vector3.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - targetPos).Magnitude
            
            local expectedCFrame = CFrame.new(targetPos, Vector3.new(waypoint.Position.X, rootPart.Position.Y, waypoint.Position.Z))
            
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / CONFIG.TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                if connection then connection:Disconnect() end
            end)
            
            local lastPosition = rootPart.Position
            local checkTimer = os.clock()
            local loopTimeout = os.clock()
            local needRecalculate = false
            
            while not tweenCompleted do
                if (os.clock() - startTime) >= CONFIG.MAX_TARGET_TIME then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    return false
                end

                local liveDist = (rootPart.Position - targetPart.Position).Magnitude
                if liveDist <= CONFIG.STOP_DISTANCE then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    return true
                end
                
                -- CONDITION 2: Detect corner-blocking walls using a lower-sensitivity raycast
                if isWallInFront(rootPart, waypoint.Position, CONFIG.RAY_CHECK_DISTANCE) then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    
                    local escapeDirection = -rootPart.CFrame.LookVector
                    rootPart.CFrame = rootPart.CFrame + (escapeDirection * 1.8) + Vector3.new(0, 1.2, 0)
                    
                    needRecalculate = true
                    break
                end
                
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                if i < totalWaypoints and currentDist < 3.0 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                end
                
                -- CONDITION 3: Check for mechanical stalling
                if (os.clock() - checkTimer) > 0.15 then
                    if (rootPart.Position - lastPosition).Magnitude < 0.4 then 
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-1,1) * 2, 2.0, 1.5)
                        needRecalculate = true
                        break
                    end
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 2.5 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    needRecalculate = true
                    break 
                end
                
                RunService.Heartbeat:Wait()
            end
            
            -- Handle reorientation and recalculate the path more intelligently
            if needRecalculate then
                task.wait(0.15) 
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 
                else
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-3, 3), 1.5, math.random(2, 4))
                    return false
                end
            else
                i = i + 1
            end
        end
        
        return (rootPart.Position - targetPart.Position).Magnitude <= CONFIG.FINAL_REACH_DIST
    else
        rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-2, 2), 1.5, math.random(-2, 2))
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- MAIN CONTROL LOOP
-- =========================================================================
print("[STAGE 1] System is running - automatically locating and fully avoiding the ruin area...")
local cycle = 1
local stuckCounter = 0

while cycle <= CONFIG.TOTAL_CYCLES do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelModel = targetFuel.Parent
        local startTime = os.clock()
        
        local success = walkPathToTarget(root, targetFuel, startTime)
        
        if success then
            local actualDist = (root.Position - targetFuel.Position).Magnitude
            print(string.format("[🎉] Success! Safely reached the fuel can. Picking it up %d/%d...", cycle, CONFIG.TOTAL_CYCLES))
            
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelModel] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.5)
        else
            stuckCounter = stuckCounter + 1
            local timeElapsed = os.clock() - startTime
            if timeElapsed >= CONFIG.MAX_TARGET_TIME or stuckCounter >= CONFIG.MAX_STUCK_ATTEMPTS then
                print("[⚠️] AUTO-REORIENT: Skipping this stuck or hard-to-reach fuel can and switching to a clearer target!")
                ignoredFuels[fuelModel] = true
                stuckCounter = 0
            end
            task.wait(0.1)
        end
    else
        print("[-] Scanning for fuel cans in a safe area...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] COMPLETED SUCCESSFULLY - MOVING TO STAGE 2!")
_G.CurrentStage = 2
return true
