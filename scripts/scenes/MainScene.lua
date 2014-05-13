--[[=============================================================================
#     FileName: MainScene.lua
#         Desc: mainScene for 2048 game
#               full edition in https://github.com/hanxi/quick-cocos2d-x-2048/tree/release
#       Author: hanxi
#        Email: hanxi.info@gmail.com
#     HomePage: http://www.hanxi.info
#      Version: 0.0.1
#   LastChange: 2014-05-09 09:13:11
#      History:
=============================================================================]]

local totalScore = 0
local bestScore = 0
local WINSTR = ""
local touchStart = {0,0}
local configFile = device.writablePath.."hxgame.config"
local javaClassName = "com.hx2048.luajavabridge.Luajavabridge"
local isOver = false
local shareImgName = "share.png"

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local function dialogFunc1()
    game.mainScene:restartGame()
    game.mainScene:showFullAds()
end

local function dialogFunc2()
    game.mainScene:screen(showShareDialog)
end

function showShareDialog()
    if device.platform ~= "android" then return end

    local javaMethodName = "share"
    local javaParams = {
        "hx2048 share",
        string.format("my hx2048 score is %d. from wandoujia download : http://apps.wandoujia.com/apps/com.hx2048.luajavabridge/download ",totalScore),
        shareImgName,
    }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

function showDialog(title,txt,btn,func,btn2,func2)
    if device.platform ~= "android" then return end

    local javaMethodName = "showDialog"
    local javaParams = {
        title,
        txt,
        btn or "ok",
        func or function(event)
            printf("Java method callback value is [%s]", event)
        end,
        btn2 or "",
        func2 or function(event)
            printf("Java method callback value is [%s]", event)
        end,
    }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;I)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

local function showMyDialog()
    showDialog("GAME OVER","YOUR SCORE "..totalScore,
        "Try Again", dialogFunc1,
        "Share", dialogFunc2)
end

local function doOpList(op_list)
    for _,op in ipairs(op_list or {}) do
        local o = op[1]
        if o=='setnum' then
            local i,j,num = op[2],op[3],op[4]
            setnum(gridShow[i][j],num,i,j)
        end
    end
end

function getPosFormIdx(mx,my)
    local cellsize=150   -- cell size
    local cdis = 2*cellsize-cellsize/2
    local origin = {x=display.cx-cdis,y=display.cy+cdis}
    local x = (my-1)*cellsize+origin.x
    local y = -(mx-1)*cellsize+origin.y - 100
    return x,y
end

function MainScene:show(cell,mx,my)
    local x,y = getPosFormIdx(mx,my)
    local bsz = cell.backgroundsize/2
    cell.background:setPosition(ccp(x-bsz,y-bsz))
    self:addChild(cell.background)
    cell.num:align(display.CENTER,x,y):addTo(self)
end

local colors = {
    [-1]   = ccc4(0xee, 0xe4, 0xda, 100),
    [0]    = ccc3(0xee, 0xe4, 0xda),
    [2]    = ccc3(0xee, 0xe4, 0xda),
    [4]    = ccc3(0xed, 0xe0, 0xc8),
    [8]    = ccc3(0xf2, 0xb1, 0x79),
    [16]   = ccc3(0xf5, 0x95, 0x63),
    [32]   = ccc3(0xf6, 0x7c, 0x5f),
    [64]   = ccc3(0xf6, 0x5e, 0x3b),
    [128]  = ccc3(0xed, 0xcf, 0x72),
    [256]  = ccc3(0xed, 0xcc, 0x61),
    [512]  = ccc3(0xed, 0xc8, 0x50),
    [1024] = ccc3(0xed, 0xc5, 0x3f),
    [2048] = ccc3(0xed, 0xc2, 0x2e),
    [4096] = ccc3(0x3c, 0x3a, 0x32),
}
local numcolors = {
    [0] = ccc3(0x77,0x6e,0x65),
    [2] = ccc3(0x77,0x6e,0x65),
    [4] = ccc3(0x77,0x6e,0x65),
    [8] = ccc3(0x77,0x6e,0x65),
    [16] = ccc3(0x77,0x6e,0x65),
    [32] = ccc3(0x77,0x6e,0x65),
    [64] = ccc3(0x77,0x6e,0x65),
    [128] = ccc3(0x77,0x6e,0x65),
}

function setnum(self,num,i,j)
    local s = tostring(num)
    --s = s.."("..i..","..j..")"
    if s=='0' then 
        s=''
        self.background:setOpacity(100)
    else
        self.background:setOpacity(255)
    end
    local c=colors[num]
    if not c then
        c=colors[4096]
    end
    self.num:setString(s)
    self.background:setColor(c)
    local nc = numcolors[num]
    if not nc then
        nc = numcolors[128]
    end
    self.num:setColor(nc)
end

function saveStatus()
    local gridstr = serialize(grid)
    local isOverstr = "false"
    if isOver then isOverstr = "true" end
    local str = string.format("do local grid,bestScore,totalScore,WINSTR,isOver \
                              =%s,%d,%d,\'%s\',%s return grid,bestScore,totalScore,WINSTR,isOver end",
                              gridstr,bestScore,totalScore,WINSTR,isOverstr)
    io.writefile(configFile,str)
end

function MainScene:loadStatus()
    if io.exists(configFile) then
        local str = io.readfile(configFile)
        if str then
            local f = loadstring(str)
            local _grid,_bestScore,_totalScore,_WINSTR,_isOver = f()
            if _grid and _bestScore and _totalScore and _WINSTR then
                grid,bestScore,totalScore,WINSTR,isOver = _grid,_bestScore,_totalScore,_WINSTR,_isOver
            end
        end
    end
    self:reLoadGame()
end

function MainScene:createLabel(title)
    cc.ui.UILabel.new({text = "== " .. title .. " ==", size = 20, color = display.COLOR_BLACK})
        :align(display.CENTER, display.cx, display.top - 20)
        :addTo(self)
    self.scoreLabel = cc.ui.UILabel.new({
        text = "SCORE:0",
        size = 30,
        color = display.COLOR_BLUE,
    })
    self.scoreLabel:align(display.CENTER,display.cx,display.top - 100):addTo(self)
end

function MainScene:onTouch(event, x, y)
    if isOver then
        return true
    end

    if event=='began' then
        touchStart={x,y}
    elseif event=='ended' then
        local tx,ty=x-touchStart[1],y-touchStart[2]
        if tx==0 then
            tx = tx+1
            ty = ty+1
        end
        local dis = tx*tx+ty*ty
        if dis<3 then   -- touch move too short will ignore
            return true
        end
        local dt = ty/tx
        local op_list,score,win
        if dt>=-1 and dt<=1 then
            if tx>0 then
                op_list,score,win = touch_op(grid,'right')
            else
                op_list,score,win = touch_op(grid,'left')
            end
        else
            if ty>0 then
                op_list,score,win = touch_op(grid,'up')
            else
                op_list,score,win = touch_op(grid,'down')
            end
        end
        doOpList(op_list)
        if win then
            WINSTR = "YOUR ARE WINER"
        end
        totalScore = totalScore + score
        if totalScore>bestScore then
            bestScore = totalScore
        end
        self.scoreLabel:setString(string.format("BEST:%d     \nSCORE:%d    \n%s",bestScore,totalScore,WINSTR or ""))
        isOver = not canMove(grid)
        if isOver then
            showMyDialog()
        end
        saveStatus()
    end
    return true
end

function MainScene:createGridShow()
    gridShow = {}
    for tmp=0,15 do
        local i,j = math.floor(tmp/4)+1,math.floor(tmp%4)+1
        local num = grid[i][j]
        local s = tostring(num)
        --s = s.."("..i..","..j..")"
        if s=='0' then
            s=''
        end
        if not gridShow[i] then
            gridShow[i] = {}
        end
        local cell = {
            backgroundsize = 140,
            background = CCLayerColor:create(colors[-1], 140, 140),
            num = cc.ui.UILabel.new({
                text = s,
                size = 40,
                color = numcolors[0],
            }),
        }
        gridShow[i][j] = cell
        self:show(gridShow[i][j],i,j)
    end

end

function MainScene:reLoadGame()
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        for j=1,n do
            setnum(gridShow[i][j],grid[i][j],i,j)
        end
    end
    self.scoreLabel:setString(string.format("BEST:%d     \nSCORE:%d    \n%s",bestScore,totalScore,WINSTR or ""))
end

function MainScene:restartGame()
    grid = initGrid(4,4)
    totalScore = 0
    WINSTR = ""
    isOver = false
    self:reLoadGame()
    saveStatus()
end

function MainScene:showHelpView()
    if device.platform ~= "android" then return end

    local x = 0 
    local y = 0 
    local w = display.widthInPixels
    local h = display.heightInPixels
    local javaMethodName = "displayWebView"
    local javaParams = {
        "file:///android_asset/html/help.html",
        x,y,w,h,
    }
    local javaMethodSig = "(Ljava/lang/String;IIII)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

function MainScene:showFullAds()
    self:performWithDelay(function()
        local javaMethodName = "showFullAds"
        local javaParams = {"079aa215250529a05350b937ab5d8302",}
        local javaMethodSig = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        end,0.1)
end

function MainScene:showListAds()
    self:performWithDelay(function()
        local javaMethodName = "showListAds"
        local javaParams = {"2c2b1de82393306026f9b5577d2a7e0c"}
        local javaMethodSig = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        end,0.1)
end

function MainScene:createButtons()
    local images = {
        normal = "GreenButton.png",
        pressed = "GreenScale9Block.png",
        disabled = "GreenButton.png",
    }

    cc.ui.UIPushButton.new(images, {scale9 = true})
        :setButtonSize(100, 60)
        :setButtonLabel("normal", ui.newTTFLabel({
            text = "Help",
            size = 32
        }))
        :onButtonClicked(function(event)
            self:showHelpView()
        end)
        :align(display.LEFT_TOP, display.left + 20, display.top - 170)
        :addTo(self)

    cc.ui.UIPushButton.new(images, {scale9 = true})
        :setButtonSize(100, 60)
        :setButtonLabel("normal", ui.newTTFLabel({
            text = "Share",
            size = 32
        }))
        :onButtonClicked(function(event)
            dialogFunc2()
        end)
        :align(display.CENTER_TOP, display.left + 220, display.top - 170)
        :addTo(self)

    cc.ui.UIPushButton.new(images, {scale9 = true})
        :setButtonSize(100, 60)
        :setButtonLabel("normal", ui.newTTFLabel({
            text = "New",
            size = 32
        }))
        :onButtonClicked(function(event)
            self:restartGame()
            self:showFullAds()
        end)
        :align(display.RIGHT_TOP, display.right - 180, display.top - 170)
        :addTo(self)

    cc.ui.UIPushButton.new(images, {scale9 = true})
        :setButtonSize(100, 60)
        :setButtonLabel("normal", ui.newTTFLabel({
            text = "More",
            size = 32
        }))
        :onButtonClicked(function(event)
            self:showListAds()
        end)
        :align(display.RIGHT_TOP, display.right - 20, display.top - 170)
        :addTo(self)
end

function MainScene:ctor()
    WINSTR = ""
    display.newColorLayer(ccc4(0xfa,0xf8,0xef, 255)):addTo(self)
    grid = initGrid(4,4)

    self:createLabel("2048")
    self:createGridShow()
    self:createButtons()

    self:loadStatus()
    if isOver then
        self:restartGame()
    end
end

function MainScene:onEnter()
    local layer = display.newLayer()
    layer:addTouchEventListener(function (event,x,y)
        return self:onTouch(event,x,y)
    end)
    layer:setTouchEnabled(true)
    self:addChild(layer)

    if device.platform ~= "android" then return end

    -- avoid unmeant back
    self:performWithDelay(function()
        -- keypad layer, for android
        local layer = display.newLayer()
        layer:addKeypadEventListener(function(event)
            if event == "back" then
                game.exit()
            end
        end)
        self:addChild(layer)
        layer:setKeypadEnabled(true)
      end, 0.5)
end

--截屏代码 有一个咔嚓的动画
function MainScene:screen(callbackfunc)
    local size = CCDirector:sharedDirector():getWinSize()
    local screen = CCRenderTexture:create(size.width, size.height, kCCTexture2DPixelFormat_RGBA8888)
    screen:begin()
    self:visit()
    screen:endToLua()
    screen:saveToFile(shareImgName,kCCImageFormatPNG)

    if device.platform=="android" then
        local fname = device.writablePath..shareImgName
        local javaMethodName = "chmod"
        local javaParams = {
            fname,
            "777",
        }
        local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
    end

    local colorLayer1 = display.newColorLayer(ccc4(0, 0, 0, 125)):addTo(self)
    colorLayer1:setAnchorPoint(ccp(0, 0))
    colorLayer1:setPosition(ccp(0, display.height))

    local colorLayer2 = display.newColorLayer(ccc4(0, 0, 0, 125)):addTo(self)
    colorLayer2:setAnchorPoint(ccp(0, 0))
    colorLayer2:setPosition(ccp(0, - display.height))

    transition.moveTo(colorLayer1, {y = display.cy, time = 0.3,})
    self:performWithDelay(function () 
        transition.moveTo(colorLayer1, {y = display.height, time = 0.2})
    end, 0.3) 

    transition.moveTo(colorLayer2, {y = -display.cy, time = 0.3})
    self:performWithDelay(function () 
        transition.moveTo(colorLayer2, {y = -display.height, time = 0.2})
    end, 0.3) 

    self:performWithDelay(function () 
        callbackfunc()
    end, 0.6) 
end

return MainScene
