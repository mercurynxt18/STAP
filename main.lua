wait(10)
-- ts file was generated at discord.gg/25ms (Cleaned Version)
local fenv = getfenv()

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end
print('[SYSTEM] Khoi dong Main Loader Mobile Compatible - Fixed Syntax!')

-- =========================================================
-- ส่วนที่ 1: โค้ดจาก Stage0_ZHUB.lua
-- =========================================================
task.spawn(function()
    local stage0_raw = [[
        -- [เอาโค้ดทั้งหมดที่อยู่ในไฟล์ Stage0_ZHUB.lua มาวางตรงนี้]
        print("Stage0 ZHUB Running...")
    ]]
    
    -- ทำการแทนที่คำสั่งตามต้นฉบับดิม
    stage0_raw = string.gsub(stage0_raw, 'Enum%.PathJointAction', 'Enum.PathWaypointAction')
    stage0_raw = string.gsub(stage0_raw, 'PathJointAction', 'PathWaypointAction')

    print('[RUNNING] Cau phan: Stage0_ZHUB.lua')
    
    local func, err = loadstring(stage0_raw)
    if func then 
        func() 
    else 
        warn("Stage0 Error: ", err) 
    end
end)

-- =========================================================
-- ส่วนที่ 2: โค้ดจาก join_map.lua
-- =========================================================
task.spawn(function()
    local join_map_raw = [[
        -- [เอาโค้ดทั้งหมดที่อยู่ในไฟล์ join_map.lua มาวางตรงนี้]
        print("Join Map Running...")
    ]]

    local func, err = loadstring(join_map_raw)
    if func then 
        func() 
    else 
        warn("Join Map Error: ", err) 
    end

    -- ปิดท้ายด้วย Error หลอกตามต้นฉบับ
    error('internal 583: <25ms: infinitelooperror>')
end)