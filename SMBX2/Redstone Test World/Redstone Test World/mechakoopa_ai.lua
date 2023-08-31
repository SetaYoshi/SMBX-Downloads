--[[

	Written by MrDoubleA
	Please give credit!

	Credit to Novarender for helping with the logic for the movement of the bullets

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local mechakoopa = {}

-- THE WALK-INATORS! EVERYONE WILL BE WALKING IN THE WHOLE TRI-STATE-AREA!!! (thanks novarender)
mechakoopa.TYPE_NORMAL  = 0
mechakoopa.TYPE_LASER   = 1
mechakoopa.TYPE_BLASTER = 2
mechakoopa.TYPE_KNOCKED = 3 -- AND THE SNOOZINATORS!


mechakoopa.idList  = {}
mechakoopa.typeMap = {}

mechakoopa.bulletIDList = {}
mechakoopa.bulletIDMap  = {}


local STATE_WALK    = 0
local STATE_PREPARE = 1
local STATE_ATTACK  = 2
local STATE_RETURN  = 3

local colBox = Colliders.Box(0,0,0,0)

local function tableMultiInsert(tbl,tbl2) -- I suppose that I now use this any time I use glDraw, huh
    for _,v in ipairs(tbl2) do
        table.insert(tbl,v)
    end
end

local function getAnimationFrame(v)
    local config = NPC.config[v.id]
    local data = v.data

    local attackFrames = 0
    if mechakoopa.typeMap[v.id] == mechakoopa.TYPE_LASER then
        attackFrames = 6*(config.frames/10)
    elseif mechakoopa.typeMap[v.id] == mechakoopa.TYPE_BLASTER then
        attackFrames = 8*(config.frames/12)
    end

    local f = 0

    if mechakoopa.typeMap[v.id] == mechakoopa.TYPE_KNOCKED then
        if data.timer > config.recoverTime/2 then -- Recovering animation
            f = (math.floor((config.recoverTime-data.timer)/config.framespeed))
        else
            f = (math.floor(data.timer/config.framespeed))
        end

        f = math.clamp(f,0,config.frames-1)
    elseif data.state == STATE_WALK then
        f = (math.floor(data.animationTimer/config.framespeed)%(config.frames-attackFrames))
    elseif data.state == STATE_PREPARE then
        f = math.min(config.frames-1,math.floor((data.timer/config.attackPrepareTime)*(attackFrames-1))+(config.frames-attackFrames))
    elseif data.state == STATE_ATTACK then
        f = (config.frames-1)
    elseif data.state == STATE_RETURN then
        f = math.min(config.frames-1,math.floor(((config.attackReturnTime-data.timer)/config.attackReturnTime)*(attackFrames-1))+(config.frames-attackFrames))
    end

    return npcutils.getFrameByFramestyle(v,{frame = f})
end

local function solidNPCFilter(v) -- Filter for Colliders.getColliding to only return NPCs that are solid to NPCs
    return (not v.isGenerator and not v.isHidden and not v.friendly and (NPC.config[v.id] and NPC.config[v.id].npcblock))
end

local laserSpeed = 16
local function doLaserLogic(v,dangerous)
    local config = NPC.config[v.id]
    local data = v.data

    data.laserProgress = data.laserProgress or 0

    local maxMoves = 48
    if dangerous then
        data.laserProgress = math.min(maxMoves,data.laserProgress + 1)
        maxMoves = data.laserProgress
    end

    for move=0,maxMoves-1 do
        colBox.x = (v.x+(v.width/2))+((move*laserSpeed)*v.direction)-(laserSpeed/2)
        colBox.y = (v.y+(v.height/2))-(v.height*0.375)
        colBox.width,colBox.height = laserSpeed,(v.height*0.75)

        local hit = false

        -- Account for blocks
        for _,w in ipairs(Colliders.getColliding{a = colBox,b = Block.SOLID.. Block.PLAYER.. Block.MEGA_SMASH,btype = Colliders.BLOCK}) do
            if Block.MEGA_SMASH_MAP[w.id] and dangerous then
                w:remove(true)
            end

            hit = true
        end

        -- Account for NPCs
        hit = hit or (#Colliders.getColliding{a = colBox,btype = Colliders.NPC,filter = solidNPCFilter} > 0)

        if hit then
            data.laserProgress = move
            return true
        end
    end

    data.laserProgress = maxMoves

    -- Hurt players
    if dangerous then
        local width,height = (data.laserProgress*laserSpeed),(v.height*0.75)
        local x,y = v.x+(v.width/2)-(width/2)+((width/2)*v.direction),v.y+(v.height/2)-(v.height*0.375)

        Graphics.drawBox{x = x, y = y, width = width, height = height, sceneCoords = true, color = Color.black, priority = 5}
        for _,w in ipairs(Player.getIntersecting(x,y,x+width,y+height)) do
            w:harm()
        end
    end

    return false
end

function mechakoopa.register(id,type)
    npcManager.registerEvent(id,mechakoopa,"onTickEndNPC","onTickEndMechakoopa")
    npcManager.registerEvent(id,mechakoopa,"onDrawNPC"   ,"onDrawMechakoopa"   )

    table.insert(mechakoopa.idList,id)
    mechakoopa.typeMap[id] = type or true
end

function mechakoopa.registerBullet(id)
    npcManager.registerEvent(id,mechakoopa,"onTickEndNPC","onTickEndBullet")
    npcManager.registerEvent(id,mechakoopa,"onDrawNPC"   ,"onDrawBullet"   )

    table.insert(mechakoopa.bulletIDList,id)
    mechakoopa.bulletIDMap[id] = true
end


function mechakoopa.onInitAPI()
    registerEvent(mechakoopa,"onNPCHarm")
    registerEvent(mechakoopa,"onNPCKill") -- onPostNPCKill would probably be a bit better, but the default death effects use onNPCKill so
end

local knockableHarmTypes = table.map{HARM_TYPE_JUMP,HARM_TYPE_SPINJUMP,HARM_TYPE_TAIL,HARM_TYPE_SWORD}
function mechakoopa.onNPCHarm(eventObj,v,reason,culprit)
    if not mechakoopa.typeMap[v.id] or not knockableHarmTypes[reason] then return end

    local config = NPC.config[v.id]
    local data = v.data

    if mechakoopa.typeMap[v.id] ~= mechakoopa.TYPE_KNOCKED and config.transformID then
        v:transform(config.transformID)
    end

    data.state = STATE_WALK
    data.timer = 0

    data.laserProgress = nil -- Used by zappa mechakoopas
    data.laserOpacity = nil
    data.laserHeight = nil

    data.turnTimer = 0

    if culprit then
        v.direction = -math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2)))
    end

    v.speedX = v.direction*5
    v.speedY = -3.5

    SFX.play(9)

    eventObj.cancelled = true
end

mechakoopa.effectVariants = {1,2,3,3,4}
function mechakoopa.onNPCKill(eventObj,v,reason)
    if not mechakoopa.typeMap[v.id] or (reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN or reason == HARM_TYPE_SWORD) then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not mechakoopa.effectVariants or not config.deathEffectID then return end

    for _,variant in ipairs(mechakoopa.effectVariants) do
        local e = Effect.spawn(config.deathEffectID,v.x+(v.width/2),v.y+(v.height/2),variant,v.id,false)

        e.direction = v.direction
    end
end

function mechakoopa.onTickEndMechakoopa(v)
	if Defines.levelFreeze then return end

    local config = NPC.config[v.id]
	local data = v.data

	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
        data.state = STATE_WALK
        data.timer = 0

        data.turnTimer = 0

        data.laserProgress = nil -- Used by zappa mechakoopas
        data.laserOpacity = nil
        data.laserHeight = nil

        data.animationTimer = 0
    end

    data.animationTimer = data.animationTimer + 1

    if v:mem(0x138,FIELD_WORD) > 0 or (mechakoopa.typeMap[v.id] ~= mechakoopa.TYPE_KNOCKED and (v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL))) then
        if mechakoopa.typeMap[v.id] ~= mechakoopa.TYPE_KNOCKED and v:mem(0x138,FIELD_WORD) == 5 and config.transformID then
            v:transform(config.transformID)
        end

        data.state = STATE_WALK
        data.timer = 0

        data.turnTimer = 0

        data.laserProgress,data.laserOpacity,data.laserHeight = nil,nil,nil

        v.animationFrame = getAnimationFrame(v)
        return
    end

    local n = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2))
    local playerDistanceX,playerDistanceY,playerDistance = math.huge,math.huge,math.huge

    if n then
        playerDistanceX = (n.x+(n.width /2))-(v.x+(v.width /2))
        playerDistanceY = (n.y+(n.height/2))-(v.y+(v.height/2))
        playerDistance  = math.abs(playerDistanceX)+math.abs(playerDistanceY)
    end

    if mechakoopa.typeMap[v.id] == mechakoopa.TYPE_KNOCKED then
        data.timer = data.timer + 1

        if data.timer > config.recoverTime then
            data.state = STATE_WALK
            data.timer = 0

            if v:mem(0x12C,FIELD_WORD) > 0 then -- If being held
                local p = Player(v:mem(0x12C,FIELD_WORD)) -- Player holding this npc

                p:mem(0x154,FIELD_WORD,0)
                p:harm()

                v:mem(0x12C,FIELD_WORD,0)
            end

            if config.transformID then
                v:transform(config.transformID)
            end
        elseif data.timer > (config.recoverTime*0.75) and data.timer < (config.recoverTime*0.95) then
            if data.timer%2 == 0 then
                v.x = v.x - 2
            else
                v.x = v.x + 2
            end
        end

        -- Get knocked by players
        if v:mem(0x12C,FIELD_WORD) == 0 and v:mem(0x12E,FIELD_WORD) == 0 then -- If not grabbed
            for _,w in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
                if w.forcedState == 0 and w.deathTimer == 0 and not w:mem(0x13C,FIELD_BOOL) then -- If the player is tangible
                    v.speedX = -math.sign((w.x+(w.width/2))-(v.x+(v.width/2)))*3
                    if v.collidesBlockBottom then
                        v.speedY = -2
                    end

                    SFX.play(9)
                end
            end

            -- Deaccelerate
            if v.collidesBlockBottom and v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.35)
            elseif v.collidesBlockBottom and v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.35)
            end
        end
    elseif data.state == STATE_WALK then
        if mechakoopa.typeMap[v.id] ~= mechakoopa.TYPE_NORMAL and n and playerDistance < config.attackDistance then
            data.timer = data.timer + 1

            if data.timer > config.attackStartTime then
                data.state = STATE_PREPARE
                data.timer = 0

                v.direction = math.sign(playerDistanceX)

                if config.prepareSFX then
                    SFX.play(config.prepareSFX)
                end
            end
        else
            data.timer = 0
        end
        if n and v.direction ~= math.sign(playerDistanceX) then -- Begin turning to the player
            data.turnTimer = data.turnTimer + 1

            if data.turnTimer > config.turnTime then
                v.direction = math.sign(playerDistanceX)
                data.turnTimer = 0
            end
        else
            data.turnTimer = 0
        end

        v.speedX = 0.75*v.direction
    elseif data.state == STATE_PREPARE then
        data.timer = data.timer + 1

        if data.timer > config.attackPrepareTime then
            data.state = STATE_ATTACK
            data.timer = 0
        end

        v.speedX = 0
    elseif data.state == STATE_ATTACK then
        data.timer = data.timer + 1

        if mechakoopa.typeMap[v.id] == mechakoopa.TYPE_LASER then
            if data.timer > config.attackTime then
                data.state = STATE_RETURN
                data.timer = 0

                data.laserProgress = nil
                data.laserOpacity = nil
                data.laserHeight = nil
            elseif data.timer == (config.attackTime/2) then
                data.laserProgress = 0

                if config.fireSFX then
                    SFX.play(config.fireSFX)
                end
            elseif data.timer > (config.attackTime/2) then
                doLaserLogic(v,true)
            else
                doLaserLogic(v,false)

                data.laserHeight = math.max(0,(data.laserHeight or (v.height*0.75))-((data.timer/v.height)*0.4))
                data.laserOpacity = math.min(0.65,(data.laserOpacity or 0) + 0.1)
            end
        elseif mechakoopa.typeMap[v.id] == mechakoopa.TYPE_BLASTER then
            if data.timer > config.attackTime then
                data.state = STATE_RETURN
                data.timer = 0
            elseif data.timer == (config.attackTime/2) then
                if config.projectileID then
                    -- Spawn NPC
                    local w = NPC.spawn(config.projectileID,v.x+(v.width/2)+((v.width/2)*v.direction),v.y+(v.height/2),v.section,false,true)

                    w.direction = v.direction
                    w.speedX = 3*v.direction

                    if not NPC.config[w.id].nogravity then
                        w.speedY = -4
                    end

                    -- Spawn effect
                    local e = Effect.spawn(10,0,0)

                    e.x = (v.x+(v.width /2))+((v.width/2)*v.direction)-(e.width /2)
                    e.y = (v.y+(v.height/2))                          -(e.height/2)
                end

                if config.fireSFX then
                    SFX.play(config.fireSFX)
                end
            end
        end

        v.speedX = 0
    elseif data.state == STATE_RETURN then
        data.timer = data.timer + 1

        if data.timer > config.attackReturnTime then
            data.state = STATE_WALK
            data.timer = 0
        end

        v.speedX = 0
    end

    v.animationFrame = getAnimationFrame(v)
end

function mechakoopa.onDrawMechakoopa(v)
    if v.despawnTimer <= 0 then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.laserProgress then return end -- If the laser isn't out yet

    -- Get priority for the laser
    local priority = -45
    if config.priority then
        priority = -15
    end

    local color = config.laserColor or Color.white
    if type(color) == "number" then
        color = Color.fromHexRGBA(color)
    end

    -- Laser beam
    local laserWidth = (data.laserProgress*laserSpeed)

    if data.timer > (config.attackTime/2) then -- Actual beam
        local vertexCoords,textureCoords = {},{}

        local colorMultiplier = (math.abs(math.cos(data.timer/16))+0.5)*2
        local laserColor = Color(color.r*colorMultiplier,color.g*colorMultiplier,color.b*colorMultiplier,color.a)


        -- Middle part
        local middleFrame = (math.floor(data.timer/4)%3)

        local i = 0
        while i <= laserWidth do
            local segmentWidth = math.min(config.laserMiddleGFX.width,laserWidth-i)

            tableMultiInsert(vertexCoords,{
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)-(config.laserMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)-(config.laserMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)+(config.laserMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)+(config.laserMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)-(config.laserMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)+(config.laserMiddleGFX.height/6)),
            })
            tableMultiInsert(textureCoords,{
                (0                                       ),((middleFrame  )/3),
                (segmentWidth/config.laserMiddleGFX.width),((middleFrame  )/3),
                (0                                       ),((middleFrame+1)/3),
                (0                                       ),((middleFrame+1)/3),
                (segmentWidth/config.laserMiddleGFX.width),((middleFrame  )/3),
                (segmentWidth/config.laserMiddleGFX.width),((middleFrame+1)/3),
            })

            i = i + (config.laserMiddleGFX.width)
        end

        Graphics.glDraw{texture = config.laserMiddleGFX,vertexCoords = vertexCoords,textureCoords = textureCoords,color = laserColor,priority = priority+0.01,sceneCoords = true}


        -- Start and end points
        local pointFrame = (math.floor(data.timer/4)%2)

        for i=0,1 do
            Graphics.drawBox{
                texture = config.laserPointGFX,x = v.x+(v.width/2)+(((v.width*0.4)*v.direction)*((i+1)%2))-(config.laserPointGFX.width/2)+((i*laserWidth)*v.direction),y = v.y+(v.height/2)-(config.laserPointGFX.height/4),
                width = (config.laserPointGFX.width),height = (config.laserPointGFX.height/2),color = laserColor,priority = priority+0.01,sceneCoords = true,
                textureCoords = {
                    (0),((pointFrame  )/2),
                    (1),((pointFrame  )/2),
                    (1),((pointFrame+1)/2),
                    (0),((pointFrame+1)/2),
                },
            }
        end
    else -- Warning beam
        Graphics.drawBox{x = v.x+(v.width/2)-(laserWidth/2)+((laserWidth/2)*v.direction),y = (v.y+(v.height/2))-(data.laserHeight/2),width = laserWidth,height = data.laserHeight,color = color.. data.laserOpacity,priority = priority-0.01,sceneCoords = true}

        -- Weird little specs and stuff
        local rng = RNG.new(2)
        for i=1,(laserWidth/6) do
            local height = data.laserHeight/(v.height*0.15)
            Graphics.drawBox{
                --x = v.x+(v.width/2)+(((rng:random(0,laserWidth)*v.direction)+data.timer-1)%laserWidth),
                x = v.x+(v.width/2)+(((rng:random(0,laserWidth)-data.timer)%laserWidth)*v.direction)-1,
                y = v.y+(v.height/2)+(rng:random(-data.laserHeight/2,data.laserHeight/2))-(height/2),
                width = 2,height = height,color = Color(color.r*1.25,color.g*1.25,color.b*1.25,data.laserOpacity),priority = priority-0.01,sceneCoords = true,
            }
        end
    end
end



function mechakoopa.onTickEndBullet(v)
    if Defines.levelFreeze then return end

    local config = NPC.config[v.id]
	local data = v.data

	if v.despawnTimer <= 0 then
		data.timer = nil
		return
	end

	if not data.timer then
        data.timer = 0
        data.rotation = ((math.pi*1.5)+((math.pi*0.5)*v.direction))%(math.pi*2)

        data.belongsToPlayer = false
    end

    -- Get animation frame
    if data.timer > (config.lifetime*0.65) and ((config.lifetime*0.65)-data.timer)%(config.lifetime*0.08) < (config.lifetime*0.04) then -- Yellow
        v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = (config.frames/2)+(math.floor(data.timer/config.framespeed)%(config.frames/2))})
    else
        v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = (math.floor(data.timer/config.framespeed)%(config.frames/2))})
    end

	if v:mem(0x12C,FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136,FIELD_BOOL)        --Thrown
	or v:mem(0x138,FIELD_WORD) > 0    --Contained within
    then
        if v:mem(0x12C,FIELD_WORD) > 0 then
            data.belongsToPlayer = true
        elseif data.belongsToPlayer then
            v:mem(0x136,FIELD_BOOL,false)
        end

        data.rotation = ((math.pi*1.5)+((math.pi*0.5)*v.direction))%(math.pi*2)
        return
    end

    data.timer = data.timer + 1
    if data.timer > config.lifetime then -- Explosion
        v:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN) -- Kill the NPC in a slightly unorthodox way, to avoid points being given by the explosion

        if config.explosionType then
            Explosion.spawn(v.x+(v.width/2),v.y+(v.height/2),config.explosionType)
        end
    elseif (data.timer%math.floor(24-(v.speedX+v.speedY))) == 0 then
        local e = Effect.spawn(10,0,0)

        e.x = v.x+(v.width /2)-(math.cos(data.rotation)*(v.width *0.4))-(e.width /2)
        e.y = v.y+(v.height/2)-(math.sin(data.rotation)*(v.height*0.4))-(e.height/2)
    end

    -- Home in on target
    local n -- Player/enemy to home in one

    if data.belongsToPlayer then
        -- Get the nearest enemy
        for _,w in ipairs(NPC.get(NPC.HITTABLE)) do
            if w.idx ~= v.idx and not w.isGenerator and not w.isHidden and w.despawnTimer > 0 and not w.friendly and not NPC.config[w.id].nohurt
            and ((not n) or math.abs((w.x+(w.width/2))-(v.x+(v.width/2)))+math.abs((w.y+(w.height/2))-(v.y+(v.height/2))) < math.abs((n.x+(n.width/2))-(v.x+(v.width/2)))+math.abs((n.y+(n.height/2))-(v.y+(v.height/2))))
            then
                n = w
            end
        end
    else
        n = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2)) -- Get the nearest player
    end

    local rotationSpeed = 0

    if n then
        local angle = math.atan2((n.y+(n.height/2))-(v.y+(v.height/2)),(n.x+(n.width/2))-(v.x+(v.width/2)))%(math.pi*2)

        local normalDistance = math.abs(angle-data.rotation) -- How far it'd have to rotate to turn around normallt
        local loopDistance = math.min(math.abs(angle-(data.rotation+(math.pi*2))),math.abs(angle-(data.rotation-(math.pi*2)))) -- How far it'd have to rotate to loop around

        rotationSpeed = math.min(normalDistance,loopDistance)*config.rotationSpeed

		if (data.rotation > angle) ~= (normalDistance > loopDistance) then
			data.rotation = (data.rotation-rotationSpeed)%(math.pi*2) -- CCW
		else
			data.rotation = (data.rotation+rotationSpeed)%(math.pi*2) -- CW
		end
    end

    -- Move in the appropriate direction
    v.speedX = math.cos(data.rotation)*math.max(0,1-(math.abs(rotationSpeed)*20))*1.75
    v.speedY = math.sin(data.rotation)*math.max(0,1-(math.abs(rotationSpeed)*20))*1.75*config.speed
end

function mechakoopa.onDrawBullet(v)
    if v.despawnTimer <= 0 then return end

    local config = NPC.config[v.id]
	local data = v.data

	if not data.sprite then
		data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v)}
	end

	local priority = -45
	if config.priority then
		priority = -15
	end

	data.sprite.x = v.x+(v.width/2)
	data.sprite.y = v.y+v.height-(config.gfxheight/2)

	data.sprite.rotation = math.deg(data.rotation or 0)

	data.sprite.pivot = Sprite.align.CENTRE
	data.sprite.texpivot = Sprite.align.CENTRE

	data.sprite:draw{frame = v.animationFrame+1,priority = priority,sceneCoords = true}

	npcutils.hideNPC(v)
end



return mechakoopa
