local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- CAMERA CONFIGURATION FOR THE POWER BOX
local CAMERA_DISTANCE = 8  -- Distance from the camera to the Power Box
local CAMERA_HEIGHT = 4     -- Camera height relative to the Power Box position
local TRIGGER_DISTANCE = 7  -- Maximum distance (in studs) for the camera to start affecting the view

-- Function to find the nearest Power Box to the character and return both the Part and the distance
local function getClosestPowerBox(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil, math.huge end

	local closestBox = nil
	local shortestDistance = math.huge

	-- Scan all objects in Workspace to find objects named "Power Box"
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name == "Power Box" then
			local boxPart = nil
			if obj:IsA("BasePart") then
				boxPart = obj
			elseif obj:IsA("Model") then
				boxPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
			end

			if boxPart then
				local distance = (rootPart.Position - boxPart.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestBox = boxPart
				end
			end
		end
	end
	return closestBox, shortestDistance
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then 
		camera.CameraType = Enum.CameraType.Custom
		return 
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if rootPart and humanoid and humanoid.Health > 0 then
		-- Get the nearest Power Box and the current distance from the character to it
		local closestBox, currentDistance = getClosestPowerBox(character)
		
		-- ONLY ACTIVATE WHEN CLOSE TO THE POWER BOX (DISTANCE <= 7 STUDS)
		if closestBox and currentDistance <= TRIGGER_DISTANCE then
			camera.CameraType = Enum.CameraType.Scriptable
			
			local boxPos = closestBox.Position
			local boxLookVector = closestBox.CFrame.LookVector
			
			-- Calculate the position in front of the Power Box
			local targetCameraPos = boxPos + (boxLookVector * CAMERA_DISTANCE) + Vector3.new(0, CAMERA_HEIGHT, 0)
			
			-- Lock the view directly toward the Power Box
			camera.CFrame = CFrame.lookAt(targetCameraPos, boxPos)
		else
			-- IF FAR AWAY (> 7 STUDS): Return the camera to the player's default mode and stop overriding the view
			if camera.CameraType ~= Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	else
		-- If the character is dead or not fully loaded yet, return the camera to the default mode
		camera.CameraType = Enum.CameraType.Custom
	end
end)
