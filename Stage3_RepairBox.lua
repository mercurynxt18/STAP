-- SERVICES --
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService") -- Thêm dịch vụ tính đường
 
-- --- CONFIGURATION & REFERENCES ---
local LocalPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local PermanentNoclipEnabled = true
 
-- --- Safety First Lads ---
local function evacuateServer(reason)
    warn("[CRITICAL EVACUATION]: " .. reason)
    task.spawn(function()
        local PlayAgainRemote = ReplicatedStorage:FindFirstChild("Remotes") 
            and ReplicatedStorage.Remotes:FindFirstChild("Misc") 
            and ReplicatedStorage.Remotes.Misc:FindFirstChild("VotePlayAgain")

        if PlayAgainRemote and PlayAgainRemote:IsA("RemoteEvent") then
            pcall(function()
                PlayAgainRemote:FireServer()
            end)
            print("ESCAPING BY PLAYING AGAIN")
            task.wait(1.0)
        end
        LocalPlayer:Kick("[WARNING] UNKNOWN PLAYER DETECTED!")
    end)
    error("Script execution terminated.")
end

if #Players:GetPlayers() > 1 then
    evacuateServer("Pre-existing player DETECTED!")
end

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer ~= LocalPlayer then
        evacuateServer("Player entry detected (" .. newPlayer.Name .. "). Executing immediate escape.")
    end
end)
 
-- --- BACKGROUND SERVICE: PERMANENT NOCLIP ENGINE ---
local function StartPermanentNoclip()
    local noclipConnection = nil
 
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
 
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                return
            end
 
            local character = LocalPlayer.Character
            if character then
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                    end
                end
 
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
 
    ConnectNoclip()
 
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1)
        ConnectNoclip()
    end)
end

StartPermanentNoclip()
 
-- TRAVEL COMPONENT (ปรับปรุงเพื่อเพิ่มความเร็วในการทะลุกำแพง)
local function adaptiveCrawlTo(targetPos, humanoidRootPart, character)
    local finalTarget = targetPos + Vector3.new(0, 3, 0)
 
    local FAST_SPEED = 50 -- เพิ่มความเร็วเมื่อทะลุกำแพง (เดิม 35)
    local SLOW_SPEED = 20 -- (เดิม 20)
    local STEP_DISTANCE = 0.5 -- เพิ่มระยะทางต่อการเทเลพอร์ต (เดิม 0.25)
 
    local CLEARANCE_COOLDOWN = 0.25 -- ลดระยะเวลาการรอก่อนทะลุ (เดิม 0.5)
    local lastWallDetectedTime = 0
 
    local lockedYHeight = humanoidRootPart.Position.Y
 
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character} 
 
    while true do
        if not humanoidRootPart or not humanoidRootPart.Parent then break end
        local currentPos = humanoidRootPart.Position
        local flatTarget = Vector3.new(finalTarget.X, lockedYHeight, finalTarget.Z)
        local remainingVector = flatTarget - currentPos
        local totalDistance = remainingVector.Magnitude
 
        if totalDistance <= 2 or totalDistance <= STEP_DISTANCE then
            humanoidRootPart.CFrame = CFrame.new(finalTarget)
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
 
            humanoidRootPart.Anchored = true
            task.wait(0.05)
            humanoidRootPart.Anchored = false 
            break
        end
 
        local direction = remainingVector.Unit
        local lookAheadDistance = 5
        local rayResult = Workspace:Raycast(currentPos, direction * lookAheadDistance, raycastParams)
 
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end
 
        local activeStepDistance = 0.5 -- เพิ่มระยะทางต่อการเทเลพอร์ต (เดิม 0.25)
        local currentAllowedSpeed = SLOW_SPEED
        if os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN then
            activeStepDistance = 2.0 -- เพิ่มระยะทางต่อการเทเลพอร์ตเมื่อทะลุ (เดิม 1.4)
            currentAllowedSpeed = FAST_SPEED -- เพิ่มความเร็วเมื่อทะลุ
        end
 
        local delayInterval = activeStepDistance / currentAllowedSpeed
        local nextPosition = currentPos + (direction * activeStepDistance)
        local flattenedPosition = Vector3.new(nextPosition.X, lockedYHeight, nextPosition.Z)
 
        humanoidRootPart.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
    end
end

-- --- HÀM TÍNH ĐƯỜNG THÔNG MINH + CHECK KẸT 3 GIÂY ĐỂ BẬT ADAPTIVECRAWLTO ---
local function smartMoveTo(targetPos, humanoidRootPart, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoidRootPart then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false
    })
    
    path:ComputeAsync(humanoidRootPart.Position, targetPos)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local lastPosition = humanoidRootPart.Position
        local lastTimeMoved = os.clock()

        for _, waypoint in ipairs(waypoints) do
            humanoid:MoveTo(waypoint.Position)
            
            while (humanoidRootPart.Position - waypoint.Position).Magnitude > 2.5 do
                task.wait(0.1)
                
                local currentPos = humanoidRootPart.Position
                if (currentPos - lastPosition).Magnitude > 0.5 then
                    lastPosition = currentPos
                    lastTimeMoved = os.clock()
                elseif os.clock() - lastTimeMoved >= 3.0 then
                    print("[STUCK] Stuck detected for 3s! Triggering 100% adaptiveCrawlTo...")
                    adaptiveCrawlTo(targetPos, humanoidRootPart, character)
                    return
                end
            end
        end
    else
        print("[Path Blocked] Forcing adaptiveCrawlTo...")
        adaptiveCrawlTo(targetPos, humanoidRootPart, character)
    end
end
 
-- --- PIPELINE EXECUTION ENGINE ---
local function runPipeline()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
 
    print("[Pipeline] Initiating Power Box Sequence Only...")
    task.wait(0.3)
 
    -- CHỈ GIỮ LẠI BƯỚC 3: QUÉT VÀ DI CHUYỂN TỚI POWER BOX GẦN NHẤT
    print("[Step 3] Scanning for closest Power Box model...")
    local powerBoxData = {}
    local interactionSuccess = false
 
    if MapFolder and MapFolder:FindFirstChild("Tiles") then
        for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
            if child.Name == "Power Plant" then
                local powerBox = child:FindFirstChild("Power Box")
                if powerBox and powerBox:IsA("Model") then
                    table.insert(powerBoxData, {
                        Instance = powerBox,
                        Position = powerBox:GetPivot().Position
                    })
                end
            end
        end
    end
 
    if #powerBoxData > 0 then
        local currentPos = humanoidRootPart.Position
        table.sort(powerBoxData, function(a, b)
            return (currentPos - a.Position).Magnitude < (currentPos - b.Position).Magnitude
        end)
 
        local chosenBox = powerBoxData[1].Instance
        local finalBoxTarget = powerBoxData[1].Position
 
        print("[Step 3] Heading directly to closest Power Box using Smart Move.")
        smartMoveTo(finalBoxTarget, humanoidRootPart, character) -- Sử dụng Agent di chuyển thông minh
        task.wait(0.5)
 
        if (humanoidRootPart.Position - finalBoxTarget).Magnitude < 15 then
            local prompt = chosenBox:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                for i = 1, 3 do
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.05)
                        prompt:InputHoldEnd()
                    end
                    task.wait(0.1)
                end
                print("[Pipeline] Interaction successfully forced!")
                interactionSuccess = true
            end
        end
    end
 
    -- --- VOTE PLAY AGAIN SEQUENCE ---
    task.wait(0.5) 
    if interactionSuccess then
        local PlayAgainRemote = ReplicatedStorage:FindFirstChild("Remotes") 
            and ReplicatedStorage.Remotes:FindFirstChild("Misc") 
            and ReplicatedStorage.Remotes.Misc:FindFirstChild("VotePlayAgain")
 
        if PlayAgainRemote and PlayAgainRemote:IsA("RemoteEvent") then
            pcall(function()
                PlayAgainRemote:FireServer()
            end)
            print("[Play Again] Sequence executed successfully.")
        end
    end
end

runPipeline()

-- Watchdog Timeout
task.spawn(function()
    task.wait(60.0)
    local PlayAgainRemote = ReplicatedStorage:FindFirstChild("Remotes") 
        and ReplicatedStorage.Remotes:FindFirstChild("Misc") 
        and ReplicatedStorage.Remotes.Misc:FindFirstChild("VotePlayAgain")

    if PlayAgainRemote then
        print("[Watchdog Warning] Match timeout reached. Forcing server rotation.")
        pcall(function()
            PlayAgainRemote:FireServer()
        end)
    end
end)
