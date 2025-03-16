-- 用户配置
UserConfig = {
    -- 基础力度 5%-1 制退器8%-2 消焰器10%-3 补偿器15%-5
    -- 裸枪/消焰器 ：scar-16/14 akm/m4/qbz-19/15 ace-21/17 aug-23/19 beryl-28/23
    -- 裸枪：PP19-10 tomson-16 ump-13 vector-21/14 mp5-14
    -- m249-7 dp dp28-8
    power = 14,
    powerRatio = 5,
    -- 脱敏度
    desensitize = 320,
    -- 启动控制 (scrolllock, capslock, numlock)
    startControl = "numlock",
    -- 倍镜系数 默认一倍
    scope = 1,
    -- 0 无 1线性 2二次函数
    dynamicType = 2,
    -- 0 通用 >0为定制
    customType = 0,
    -- 自动根据蹲起跳转power
    auto = {
        squat = 0,
        aim = 1
    },
    -- 随机偏差范围
    randomDeviation = {
        x = 1,
        y = 1,
        interval = 1,
        ratio = 5
    },
    -- 屏幕分辨率
    screenResolution = {
        width = 2560,
        height = 1440
    },
    -- 是否开启重新开镜
    refreshAds = 0,
    -- 移动时间间隔
    -- 时间间隔
    interval = {
        move = 10,
        ads = 1000
    },
    debug = 0,
    printCustom = 0,
}

-- 开发时使用的工具
-- dofile("E:\\Lynch Bel\\github\\Soldier76\\tools\\console.lua")

-- 运行缓存
RunningCache = {
    -- 偏差像素 (± userConfig.randomDeviation)
    deviationPX = 0,
    -- 累计偏差像素
    deviationCounterPX = 0,
    -- 上一次的 Y 轴位置
    lastY = 0,
    -- 按下右键时的时间戳
    rightMouseDownTimestamp = 0,
    power = 0,
    scope = 1,
    squat = 0,
    customList = {}
}

-- 启用鼠标按键 1 事件报告
EnablePrimaryMouseButtonEvents(true)
-- 设置随机数种子
math.randomseed(GetRunningTime())

-- 入口函数
function OnEvent (event, arg, family)
    -- if UserConfig.debug == 1 then
    --     OutputLogMessage("event = %s, arg = %s, family = %s \n", event, arg, family)
    -- end
    -- 与 IsMouseButtonPressed 方法统一
    if arg == 2 then arg = 3 elseif arg == 3 then arg = 2 end

    -- 未启动直接跳过 (安全锁，防止脚本进入死循环后无法退出)
    if not IsStart() then return end

    -- 进入压枪循环
    Main(event, arg, family)

    -- 修改参数
    UpdateArgs(event, arg, family)

    -- 释放所有占用的按键
    if event == "PROFILE_DEACTIVATED" then
		EnablePrimaryMouseButtonEvents(false)
		ReleaseKey("lshift")
		ReleaseKey("lctrl")
		ReleaseKey("lalt")
		ReleaseKey("rshift")
		ReleaseKey("rctrl")
		ReleaseKey("ralt")
		-- ClearLog()
	end
end

-- 主体功能 （压枪循环）
function Main (event, arg, family)
    if event == "MOUSE_BUTTON_PRESSED" and (arg == 1 or arg == 3) and family == "mouse" then
        -- 获取鼠标位置
        -- if UserConfig.debug == 1 then
        --     local x, y = GetMousePosition()
        --     OutputLogMessage("x = %d, y = %d \n", x, y)
        -- end

        local start = GetRunningTime()
        -- ClearLog()
        local index = 1
        while (IsStart() and IsPressed(1) and (IsPressed(3) or IsPressed("lctrl"))) do

            -- 力度/移动距离 (px) (基础 + 偏差)
            local powerPX = GetRandomPower(index)
            -- local status, result = pcall(GetRandomPower(index))
            -- local powerPX = result
            -- debug.traceback(result)

            -- if UserConfig.debug == 1 then
            --     OutputLogMessage("powerPX = %d\n", powerPX)
            -- end

            -- 获取倍镜系数
            powerPX = GetScopeMultiple(powerPX)

            local dvtX =  GetRandomDeviation(UserConfig.randomDeviation.x)
            -- 移动鼠标
            MoveMouseRelative(dvtX, powerPX)

            Sleep(GetRandomInterval(index))

            -- 偏差像素
            -- if UserConfig.debug == 1 then
            --     OutputLogMessage("偏差像素 %f \n", powerPX)
            -- end

            -- 累计偏差像素
            -- if UserConfig.debug == 1 then
            --     RunningCache.deviationCounterPX = RunningCache.deviationCounterPX + powerPX
            --     OutputLogMessage("累计偏差像素 %f \n", RunningCache.deviationCounterPX)
            -- end

            -- 模拟重新开镜
            -- local now = GetRunningTime()
            -- if UserConfig.refreshAds == 1 and (now - start) >= UserConfig.internal.ads then
            --     ReleaseMouseButton(3)
            --     PressMouseButton(3)
            --     start = now
            -- end
            index = index + 1
            if UserConfig.printCustom == 1 then
                table.insert(RunningCache.customList, {UserConfig.interval.move, powerPX})
            end
        end

        if UserConfig.printCustom == 1 then
            -- 循环遍历数组
            for i = 1, #RunningCache.customList do
                OutputLogMessage("{%d, %d},\n", RunningCache.customList[i][1], RunningCache.customList[i][2])
            end
        end
        -- 重置缓存
        RunningCache.customList = {}
        RunningCache.deviationPX = 0
        RunningCache.deviationCounterPX = 0
    end
end

-- 是否启动
function IsStart ()
    return IsKeyLockOn(UserConfig.startControl)
end

-- 判断是否按下
function IsPressed (key)
    if type(key) == "number" then
		return IsMouseButtonPressed(key)
	elseif type(key) == "string" then
		return IsModifierPressed(key)
    else
        return false
    end
end

-- 四舍五入
function Round (num) return math.floor(num + 0.5) end

-- 获取随机力度 (px)
function GetRandomPower (index)
    local power = UserConfig.power
    local custom = UserConfig.customType
    local dynamicType = UserConfig.dynamicType
    local dynamic = 0
    local dvt =  GetRandomDeviation(UserConfig.randomDeviation.y)
    -- local dvt =  0
    if custom == 0 then
        if dynamicType == 1 then
            dynamic = math.min(index * power // UserConfig.desensitize, power*2//3);
        elseif dynamicType == 2 then
            -- dynamic = math.min(Round(index * index * power / UserConfig.desensitize), Round(power*4/5));
            dynamic = math.min(index * index // UserConfig.desensitize, power*2//3);
        end
        -- if UserConfig.debug == 1 then
        --     OutputLogMessage("dynamic = %f \n", dynamic)
        -- end
        if index < 5 then
            power = power * 2
        end
        return GetInfactPower(power + dynamic, index) + dvt
    else
        local len = #CustomList[custom]
        dynamic = CustomList[custom][math.min(index, len)][2]
        return GetInfactPower(power, index) + dynamic + dvt
    end
end

function GetInfactPower (power, index)
    local ratio = UserConfig.powerRatio
    local divided = power // ratio
    local remainderPower = power % ratio
    local remainderIndex = index % ratio
    if remainderPower + remainderIndex > ratio then
        return divided + 1
    end
    return divided
end

-- 获取随机间隔 (px)
function GetRandomInterval (index)
    local interval = 0
    local custom = UserConfig.customType
    if custom == 0 then
        interval = UserConfig.interval.move
    else
        local len = #CustomList[custom]
        interval = CustomList[custom][math.min(index, len)][1]
    end
    local dvt = UserConfig.randomDeviation.interval
    -- if UserConfig.debug == 1 then
    --     OutputLogMessage("interval = %f \n", interval)
    -- end
    return interval + GetRandomDeviation(dvt)
end

-- 获取倍镜系数
function GetScopeMultiple (powerPX)
    local currentScope = UserConfig.scope
    return Round(powerPX * ScopeList[currentScope])
end

-- 获取随机偏差
function GetRandomDeviation (dvt)
    local probability = math.random(1, 100)
    if probability <= UserConfig.randomDeviation.ratio then
        return math.random(-dvt, dvt)
    end
    return 0
end

function UpdateArgsScope(step)
    local len = #ScopeList
    local index = UserConfig.scope + step
    if index > len then
        index = len
    elseif index < 1 then
        index = 1
    end
    UserConfig.scope = index
end


function UpdateArgsCustome(step)
    local len = #CustomList
    local index = UserConfig.customType + step
    if index > len then
        index = len
        UserConfig.customType = index
    elseif index == 0 then
        UserConfig.power = RunningCache.power
        RunningCache.power = 0
        UserConfig.customType = index
    elseif index < 0 then
        index = 0
    else
        UserConfig.customType = index
        if RunningCache.power == 0 then RunningCache.power = UserConfig.power end
        UserConfig.power = 0
    end
end

-- 调整参数
function UpdateArgs (event, arg, family)
    if event == "MOUSE_BUTTON_PRESSED" and family == "mouse" then
        if arg == 7 then
            if IsModifierPressed("lctrl") then
                UpdateArgsScope(-1)
            elseif IsModifierPressed("lalt") then
                UpdateArgsCustome(-1)
            else
                UserConfig.power = UserConfig.power - 1
            end
            PrintArgs()
        elseif arg == 8 then
            if IsModifierPressed("lctrl") then
                UpdateArgsScope(1)
            elseif IsModifierPressed("lalt") then
                UpdateArgsCustome(1)
            else
                UserConfig.power = UserConfig.power + 1
            end
            PrintArgs()
        elseif arg == 3 and IsModifierPressed("lalt") then
            if UserConfig.scope == 1 and RunningCache.scope ~= 1 then
                UserConfig.scope = RunningCache.scope
            else
                RunningCache.scope = UserConfig.scope
                UserConfig.scope = 1
            end
            PrintArgs()
        end
    end
end

function PrintArgs ()
    OutputLogMessage("power = %d scope = %d customType = %d \n", UserConfig.power, UserConfig.scope, UserConfig.customType)
end

--倍镜倍数大约为1.5
ScopeList = {1, 1.5, 2.2, 3.3}

CustomList = {
    {
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 6},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 3},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 4},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 4},
        {10, 4},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 4},
        {10, 4},
        {10, 4},
        {10, 4},
        {10, 5},
        {10, 4},
        {10, 4},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 5},
        {10, 5},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 5},
        {10, 7},
        {10, 7},
        {10, 7},
        {10, 7},
        {10, 7},
        {10, 7},
        {10, 6},
        {10, 6},
        {10, 6},
        {10, 7},
        {10, 7},
        {10, 6},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 9},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 9},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 9},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 6},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 7},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8},
        {10, 8}
    }
}