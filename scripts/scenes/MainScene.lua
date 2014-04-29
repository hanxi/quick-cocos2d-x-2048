local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local function onTouch(event, x, y)
    if event=='began' then
        touchStart={x,y}
    elseif event=='ended' then
        local tx,ty=x-touchStart[1],y-touchStart[2]
        if tx==0 then
            tx = tx+1
            ty = ty+1
        end
        local dt = ty/tx
        local op_list = nil
        if dt>=-1 and dt<=1 then
            if tx>0 then
                print("right")
                op_list,score,totalScore,win = touch_op(grid,'right')
            else
                print("left")
                op_list,score,totalScore,win = touch_op(grid,'left')
            end
        else
            if ty>0 then
                print('up')
                op_list,score,totalScore,win = touch_op(grid,'up')
            else
                print('down')
                op_list,score,totalScore,win = touch_op(grid,'down')
            end
        end
        doOpList(op_list)
        print(string.format("score=%s,totalScore=%d",score,totalScore))
        if win then
            WINSTR = "YOUR ARE WINER"
        end
        scoreLabel:setString(string.format("SCORE:%d    \n%s",totalScore,WINSTR or ""))
    end
    return true
end

function doOpList(op_list)
    for _,op in ipairs(op_list or {}) do
        local o = op[1]
        if o=='setnum' then
            local i,j,num = op[2],op[3],op[4]
            setnum(gridShow[i][j],num,i,j)
        end
    end
end

function MainScene:createTitle(title)
    cc.ui.UILabel.new({text = "*** " .. title .. " ***", size = 24, color = display.COLOR_BLACK})
        :align(display.CENTER, display.cx, display.top - 20)
        :addTo(self)
    scoreLabel = cc.ui.UILabel.new({
        text = "SCORE:0",
        size = 44,
        color = display.COLOR_BLUE,
    })
    scoreLabel:align(display.CENTER,display.cx,display.top - 100):addTo(self)
end

function MainScene:ctor()
    grid = initGrid(4,4)

    display.newColorLayer(ccc4(0xfa,0xf8,0xef, 255)):addTo(self)
    self:createTouchLayer()
    self:createNextButton()

    self:createTitle("2048")
end

function MainScene:onEnter()
    if device.platform ~= "android" then return end

    -- avoid unmeant back
    self:performWithDelay(function()
        -- keypad layer, for android
        local layer = display.newLayer()
        layer:addKeypadEventListener(function(event)
            if event == "back" then game.exit() end
        end)
        self:addChild(layer)

        layer:setKeypadEnabled(true)
    end, 0.5)
end

function getPosFormIdx(mx,my)
    local cellsize=150   -- 格子的大小
    local cdis = 2*cellsize-cellsize/2
    local origin = {x=display.cx-cdis,y=display.cy+cdis}
    local x = (my-1)*cellsize+origin.x
    local y = -(mx-1)*cellsize+origin.y
    return x,y
end
function show(self,mx,my)
    local x,y = getPosFormIdx(mx,my)
    local bsz = self.backgroundsize/2
    self.background:setPosition(ccp(x-bsz,y-bsz))
    self.layer:addChild(self.background)
    self.num:align(display.CENTER,x,y):addTo(self.layer)
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

function MainScene:createTouchLayer()
    local layer = display.newLayer()
	layer:setTouchEnabled(true)
    layer:registerScriptTouchHandler(onTouch)
    self:addChild(layer)

    gridShow = {}
    for tmp=0,15 do
        local i,j = math.floor(tmp/4)+1,math.floor(tmp%4)+1
        local num = grid[i][j]
        local s = tostring(num)
--        s = s.."("..i..","..j..")"
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
            layer = layer,
        }
        gridShow[i][j] = cell
        show(gridShow[i][j],i,j)
    end

end

function MainScene:restartGame()
    grid = initGrid(4,4)
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        for j=1,n do
            setnum(gridShow[i][j],grid[i][j])
        end
    end
    totalScore = 0
    WINSTR = ""
    scoreLabel:setString(string.format("SCORE:%d         \n",totalScore))
end

function MainScene:createNextButton()
    local images = {
        normal = "GreenButton.png",
        pressed = "GreenScale9Block.png",
        disabled = "GreenButton.png",
    }
    cc.ui.UIPushButton.new(images, {scale9 = true})
        :setButtonSize(240, 60)
        :setButtonLabel("normal", ui.newTTFLabel({
            text = "New Game",
            size = 32
        }))
        :onButtonClicked(function(event)
            self:restartGame()
        end)
        :align(display.RIGHT_BOTTOM, display.right - 20, display.bottom + 20)
        :addTo(self)
end

return MainScene
