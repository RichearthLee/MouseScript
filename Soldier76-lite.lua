-- 用户配置
UserConfig = {
    -- 基础力度
    power = 13,
    -- 脱敏度
    desensitize = 1000,
    -- 启动控制 (scrolllock, capslock, numlock)
    startControl = "numlock",
    -- 0 通用 >0为定制
    customType = 0,
    -- 随机偏差范围
    randomDeviation = {
        x = 1,
        y = 1,
        interval = 1
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
        move = 50,
        ads = 500
    },
    debug = 1
}
--倍镜akm 14 24 36   berl 18 29 40
customFile = {
    {
        {85,20},
        {85,20}
    },
    {
        {100,25},
        {100,25}
    }
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
    rightMouseDownTimestamp = 0
}

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
function GetRandomPower ()
    local dynamic = math.min(Round(RunningCache.deviationCounterPX * RunningCache.deviationCounterPX / UserConfig.desensitize), UserConfig.power - 6);
    if UserConfig.debug == 1 then
        OutputLogMessage("dynamic = %f \n", dynamic)
    end
    return UserConfig.power + RunningCache.deviationPX + dynamic
    -- return UserConfig.power + RunningCache.deviationPX
end

-- 主体功能 （压枪循环）
function Main (event, arg, family)
    if event == "MOUSE_BUTTON_PRESSED" and arg == 1 and family == "mouse" then
        -- 启动前先获取一次 Y 轴位置
        local x, y = GetMousePosition()
        RunningCache.lastY = y
        ClearLog()

        local start = GetRunningTime()

        while (IsStart() and IsPressed(1) and IsPressed(3)) do
        -- while (IsStart() and IsPressed(1)) do
            -- ConsoleLog("-------------------------------")
            -- 调整偏差 ± userConfig.randomDeviation (px)
            -- RunningCache.deviationPX = math.max(
            --     -UserConfig.randomDeviation,
            --     math.min(
            --         UserConfig.randomDeviation,
            --         RunningCache.deviationPX + math.random(-1, 1) -- 随机偏差 ±1
            --     )
            -- )
            local dvtY =  UserConfig.randomDeviation.y
            RunningCache.deviationPX = math.random(-dvtY, dvtY)
            -- OutputLogMessage("随机偏差 %d \n", RunningCache.deviationPX)

            -- 力度/移动距离 (px) (基础 + 偏差)
            local powerPX = GetRandomPower()
            -- ConsoleLog(table.concat({ "力度/移动距离: ", power, "px" }))
            
            local dvtX =  UserConfig.randomDeviation.x
            -- 移动鼠标
            MoveMouseRelative(math.random(-dvtX, dvtX), powerPX)

            local interval = UserConfig.interval.move
            local intervalDvt = UserConfig.randomDeviation.interval
            Sleep(interval + math.random(-intervalDvt, intervalDvt))

            -- 获取鼠标位置
            -- local x, y = GetMousePosition()
            -- if UserConfig.debug == 1 then
            --     OutputLogMessage("x = %d, y = %d \n", x, y)
            -- end

            -- 实际移动像素
            -- local movedPX = Round((y - RunningCache.lastY) / 65535 * UserConfig.screenResolution.height + 1)
            local movedPX = powerPX

            -- 偏差像素
            -- local deviationCounterPX = movedPX - powerPX
            local deviationCounterPX = movedPX / 2
            if UserConfig.debug == 1 then
                OutputLogMessage("偏差像素 %f \n", deviationCounterPX)
            end
            -- ConsoleLog({ "偏差像素: ", deviationCounterPX })

            -- 累计偏差像素
            RunningCache.deviationCounterPX = RunningCache.deviationCounterPX + deviationCounterPX
            if UserConfig.debug == 1 then
                OutputLogMessage("累计偏差像素 %f \n", RunningCache.deviationCounterPX)
            end
            -- ConsoleLog({ "累计偏差像素:", RunningCache.deviationCounterPX })

            -- 记录 Y 轴位置
            -- RunningCache.lastY = y

            -- 预计下一次移动的距离 (px)
            -- local nextUnitDistance = GetRandomPower()
            -- ConsoleLog(table.concat({ "预计下一次移动的距离: ", nextUnitDistance, "px" }))

            -- 底部安全距离
            -- local safeDistance = (nextUnitDistance + UserConfig.randomDeviation) / UserConfig.screenResolution.height * 65535
            -- ConsoleLog(table.concat({ "底部安全距离: ", safeDistance, "px" }))

            -- 当鼠标移到底部，距离底部小于安全距离时，调整到顶部 （小于安全距离会影响下一次计算）
            -- if (y >= 65535 - safeDistance) then
            --     MoveMouseTo(x, 1)
            --     RunningCache.lastY = 1
            --     --break
            -- end

            -- ClearLog()
            -- ConsoleLog(RunningCache)

            -- 模拟重新开镜
            -- local now = GetRunningTime()
            -- if userConfig.refreshAds == 1 and (now - start) >= userConfig.internal.ads then
            --     ReleaseMouseButton(3)
            --     PressMouseButton(3)
            -- end
        end

        -- 重置缓存
        RunningCache.deviationPX = 0
        RunningCache.deviationCounterPX = 0
    end
end

-- 调整参数
function updateArgs (event, arg, family)
    if event == "MOUSE_BUTTON_PRESSED" and family == "mouse" then
        if arg == 7 then
            UserConfig.power = UserConfig.power - 1
            OutputLogMessage("current power = %d \n", UserConfig.power)
        elseif arg == 8 then
            UserConfig.power = UserConfig.power + 1 
            OutputLogMessage("current power = %d \n", UserConfig.power)
        end
    end
end

-- 入口函数
function OnEvent (event, arg, family)
    if UserConfig.debug == 1 then
        OutputLogMessage("event = %s, arg = %s, family = %s \n", event, arg, family)
    end
    -- 与 IsMouseButtonPressed 方法统一
    if arg == 2 then arg = 3 elseif arg == 3 then arg = 2 end

    -- 未启动直接跳过 (安全锁，防止脚本进入死循环后无法退出)
    if not IsStart() then return end

    -- 进入压枪循环
    Main(event, arg, family)
    -- 右键长按 300ms 以上，认定为开镜了，放开右键后，按下 tab 两次，重置鼠标位置
    -- if event == "MOUSE_BUTTON_PRESSED" and arg == 3 and family == "mouse" then
    --     RunningCache.rightMouseDownTimestamp = GetRunningTime()
    -- end

    -- if event == "MOUSE_BUTTON_RELEASED" and arg == 3 and family == "mouse" then
    --     -- 右键按下时长
    --     local rightMouseDownDuration = GetRunningTime() - RunningCache.rightMouseDownTimestamp
    --     -- ConsoleLog({ "右键按下时长: ", rightMouseDownDuration, "ms" })

    --     -- 重置鼠标位置
    --     if (rightMouseDownDuration >= 300 and not IsPressed(1)) then
    --         PressAndReleaseKey('tab')
    --         PressAndReleaseKey('tab')
    --     end
    -- end
    updateArgs(event, arg, family)

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

-- 启用鼠标按键 1 事件报告
EnablePrimaryMouseButtonEvents(true)
-- 设置随机数种子
math.randomseed(GetRunningTime())
