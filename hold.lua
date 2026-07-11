task.wait(1)
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

local OFFSET_DOWN = 20     -- Offset below the screen center (pixels)
local HOLD_DURATION = 19   -- Hold duration (seconds)

-- Check whether the player is using a PC
local isPC = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled

-- Start action notification
local noticeText = "Starting hold below the center by 20px for 19 seconds..."
if isPC then
    noticeText = "Starting hold at the center -20px and pressing [E] for 19 seconds..."
end

StarterGui:SetCore("SendNotification", {
    Title = "Auto Hold System",
    Text = noticeText,
    Duration = 3
})

-- Calculate the screen center coordinates and offset them down by 20 pixels
local centerX = Camera.ViewportSize.X / 2
local targetY = (Camera.ViewportSize.Y / 2) + OFFSET_DOWN

task.spawn(function()
    -- [STEP 1]: START HOLDING (Mouse/Touch and key E if on PC)
    -- Hold the screen position (move down 20 pixels)
    VirtualInputManager:SendMouseButtonEvent(centerX, targetY, 0, true, game, 0)
    
    -- If on PC, activate the hold for key E (Enum.KeyCode.E)
    if isPC then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    end
    
    -- [STEP 2]: MAINTAIN THE STATE FOR 19 SECONDS
    task.wait(HOLD_DURATION)
    
    -- [STEP 3]: RELEASE COMPLETELY
    -- Release the screen position
    VirtualInputManager:SendMouseButtonEvent(centerX, targetY, 0, false, game, 0)
    
    -- If on PC, release key E
    if isPC then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
    
    -- Completion notification
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Hold System",
        Text = isPC and "Released the position and key [E] successfully!" or "Held for 19 seconds and released automatically!",
        Duration = 3
    })
end)
