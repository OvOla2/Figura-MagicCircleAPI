---- MagicCircleAPI.lua
---- 通过按键激活魔法阵
---- Author: Gakuto1112 OvOla2 DeepSeek AI
---- License: MIT

---@class MagicCircleAPI 魔法阵控制API
MagicCircleAPI = {
    isActive = false,         -- 魔法阵是否激活
    _initialized = false,     -- API是否初始化
    circleTimer = 0,          -- 魔法阵持续时间计时器
    circlePosition = nil,     -- 魔法阵中心位置
    circleRadius = 12.0,      -- 魔法阵半径12
    starRotation = 0          -- 新增：五芒星旋转角度（弧度）
}

-- 魔法阵参数
local MAGIC_CIRCLE_DURATION = 10000  -- 持续时间 (20tick/秒)
local ROTATION_SPEED = 0.005         -- 新增：旋转速度（弧度/帧）

--- 绘制魔法阵
local function drawMagicCircle()
    local centerX, centerY, centerZ = MagicCircleAPI.circlePosition.x, 
                                      MagicCircleAPI.circlePosition.y + 0.2,
                                      MagicCircleAPI.circlePosition.z
    
    local radius = MagicCircleAPI.circleRadius
    local rotation = MagicCircleAPI.starRotation  -- 获取当前旋转角度
    
    -- 1. 绘制外环 - 使用电火花粒子效果
    local ringParticles = 9  -- 外环粒子数量增加（半径增大）
    for i = 0, ringParticles - 1 do
        local angle = math.rad(i * (360 / ringParticles))
        local x = centerX + radius * math.cos(angle)
        local z = centerZ + radius * math.sin(angle)
        particles:newParticle(
            "electric_spark",  -- 电火花粒子效果
            x, centerY, z,
            0, 0, 0  -- 零速度保持位置
        )
    end
    
    -- 2. 绘制五芒星（添加旋转效果）
    local segments = 5
    for i = 0, segments - 1 do
        -- 应用旋转角度
        local angle = math.rad(i * 72) + rotation
        local x = centerX + radius * 0.75 * math.cos(angle)  -- 内圈半径减小
        local z = centerZ + radius * 0.75 * math.sin(angle)
        particles:newParticle(
            "minecraft:witch",  -- 魔法粒子
            x, centerY, z,
            0, 0, 0  -- 零速度保持位置
        )
    end
    
    -- 3. 绘制五芒星连线 - 使用火粒子效果（添加旋转效果）
    local connectionOrder = {1, 3, 5, 2, 4, 1}
    for i = 1, #connectionOrder - 1 do
        local startIdx = connectionOrder[i]
        local endIdx = connectionOrder[i + 1]
        
        -- 应用旋转角度
        local startAngle = math.rad((startIdx - 1) * 72) + rotation
        local endAngle = math.rad((endIdx - 1) * 72) + rotation
        
        local startX = centerX + radius * 0.75 * math.cos(startAngle)
        local startZ = centerZ + radius * 0.75 * math.sin(startAngle)
        local endX = centerX + radius * 0.75 * math.cos(endAngle)
        local endZ = centerZ + radius * 0.75 * math.sin(endAngle)
        
        -- 在两点间生成连线粒子
        local steps = 20  -- 每条线的粒子数增加（半径增大）
        for j = 0, steps do
            local t = j / steps
            local x = startX * (1 - t) + endX * t
            local z = startZ * (1 - t) + endZ * t
            particles:newParticle(
                "minecraft:flame",  -- 火粒子效果
                x, centerY, z,
                0, 0, 0  -- 零速度保持位置
            )
        end
    end
    
    -- 4. 中心魔法阵特效 - 增强效果
    for _ = 1, 24 do  -- 粒子数量加倍
        particles:newParticle(
            "lava",  -- 能量（熔岩）粒子
            centerX, centerY, centerZ,
            0, 0, 0  -- 零速度保持位置
        )
    end
    
    -- 5. 添加符文粒子在环上流动 - 使用电火花粒子
    for i = 0, 7 do  -- 粒子数量加倍
        -- 旋转效果（保持原有流动效果）
        local flowAngle = math.rad((i * 45) + (MagicCircleAPI.circleTimer * 5)) 
        local x = centerX + radius * math.cos(flowAngle)
        local z = centerZ + radius * math.sin(flowAngle)
        particles:newParticle(
            "electric_spark",  -- 电火花粒子
            x, centerY, z,
            0, 0, 0  -- 零速度保持位置
        )
    end
end

--- 初始化API
function MagicCircleAPI.init()
    if MagicCircleAPI._initialized then return end

    -- 注册按键绑定 (X键)
    keybinds:newKeybind("激活魔法阵", "key.keyboard.x")
        :onPress(function()
            if MagicCircleAPI.isActive then
                MagicCircleAPI.deactivate()
            else
                MagicCircleAPI.activate()
            end
        end)

    -- 处理魔法阵显示
    events.TICK:register(function()
        if MagicCircleAPI.circleTimer > 0 then
            -- 更新旋转角度（仅当魔法阵激活时）
            MagicCircleAPI.starRotation = (MagicCircleAPI.starRotation + ROTATION_SPEED) % (2 * math.pi)
            
            drawMagicCircle()
            MagicCircleAPI.circleTimer = MagicCircleAPI.circleTimer - 1
        else
            MagicCircleAPI.isActive = false
        end
    end)

    MagicCircleAPI._initialized = true
end

--- 激活魔法阵
function MagicCircleAPI.activate()
    MagicCircleAPI.isActive = true
    MagicCircleAPI.circlePosition = player:getPos()
    MagicCircleAPI.circleTimer = MAGIC_CIRCLE_DURATION
    MagicCircleAPI.starRotation = 0  -- 重置旋转角度
    
    -- 播放激活音效
    sounds:playSound("entity.lightning_bolt.impact", player:getPos())
end

--- 关闭魔法阵
function MagicCircleAPI.deactivate()
    MagicCircleAPI.isActive = false
    MagicCircleAPI.circleTimer = 0
    
    -- 播放关闭音效
    sounds:playSound("entity.lightning_bolt.thunder", player:getPos())
end

--- 获取当前状态
function MagicCircleAPI.getState()
    return MagicCircleAPI.isActive
end

--- 设置魔法阵半径
function MagicCircleAPI.setRadius(radius)
    MagicCircleAPI.circleRadius = math.max(1.0, math.min(radius, 15.0))  -- 最大半径增加到15.0
end

return MagicCircleAPI
