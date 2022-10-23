local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local exNPC = require("extraNPCProperties")

local stoplight = require("stoplight")

local car = {}


car.sharedSettings = {
    gfxwidth = 110,
	gfxheight = 36,

	gfxoffsetx = 0,
	gfxoffsety = 2,

	width = 58,
	height = 32,

	frames = 3,
	framestyle = 1,
	framespeed = 8,

	speed = 1,

	npcblock = false,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,


    drivingSpeed = 4,
    acceleration = 0.125,
    deceleration = 0.25,

    bounceAnimationSpeed = 32,

    fallingStretchMax = 0.15,
    fallingStetchSpeed = 0.05,

    squashAnimationDuration = 24,

    colors = 4,

    frontWheelsXPositions = {15,-29},

    flameEmittersXOffset = 4,
    flameEmittersYOffset = -4,

    headLightXOffset = 32,
    headLightYOffset = -14,
    headLightBrightness = 2,
    headLightAngle = 20,
    headLightRadius = 160,
}


car.idList = {}
car.idMap  = {}


local explosionParticle = Particles.Emitter(0,0,Misc.resolveFile("car_explosion.ini"))

local customExplosion = Explosion.register(64,176,Misc.resolveSoundFile("nitro"),true,false)


local beepSFXList = {}
for i = 1, 3 do
  table.insert(beepSFXList, Audio.SfxOpen(Misc.resolveFile("beep-"..i..".ogg")))
end

local downSFXList = {}
for i = 1, 5 do
  table.insert(downSFXList, Audio.SfxOpen(Misc.resolveFile("down-"..i..".ogg")))
end

local upSFXList = {}
for i = 1, 5 do
  table.insert(upSFXList, Audio.SfxOpen(Misc.resolveFile("up-"..i..".ogg")))
end

function car.register(npcID)
	npcManager.registerEvent(npcID, car, "onTickEndNPC")
    npcManager.registerEvent(npcID, car, "onDrawNPC")

    table.insert(car.idList,npcID)
    car.idMap[npcID] = true
end


local function initialise(v,data,config)
    data.initialized = true

    data.existanceTimer = 0

    data.stretch = 1
    data.bounceTimer = 0

    data.flightTimer = 0

    data.squashAnimationTimer = 0

    data.wasStoodOn = false
    data.airTime = 0

    if v.spawnId > 0 then
        -- Ones that respawn get consistent colors
        local rngObj = RNG.new(v.spawnX*2000 + v.spawnY*v.spawnY*100)

        data.color = rngObj:randomInt(1,config.colors)
    else
        data.color = RNG.randomInt(1,config.colors)
    end

    data.headLight = Darkness.Light{
        radius = config.headLightRadius,spotangle = config.headLightAngle,brightness = config.headLightBrightness,
        type = Darkness.lighttype.SPOT,
        x = 0,y = 0,
    }
    Darkness.addLight(data.headLight)


    data.emitters = {}
    if config.nogravity then
        for i = 1,#config.frontWheelsXPositions do
            local emitter = Particles.Emitter(0,0,Misc.resolveFile("car_flames.ini"))

            table.insert(data.emitters,emitter)
        end
    end
end


local function isOnCamera(v)
    for _,c in ipairs(Camera.get()) do
        if v.x+v.width > c.x and v.x < c.x+c.width and v.y+v.height > c.y and v.y < c.y+c.height then
            return true
        end
    end

    return false
end



local function explodeWithVaryingLevelsOfViolence(v,violent)
    if v.x+v.width <= camera.x or v.x >= camera.x+camera.width or v.y+v.height <= camera.y or v.y >= camera.y+camera.height then
        v:kill(HARM_TYPE_VANISH)
        return
    end

    local config = NPC.config[v.id]
    local data = v.data

    explosionParticle.x = v.x + v.width*0.5
    explosionParticle.y = v.y + v.height*0.5

    if violent then
        explosionParticle:emit(200)
    else
        explosionParticle:emit(15)
    end

    Explosion.spawn(v.x + v.width*0.5,v.y + v.height*0.5,customExplosion)

    v:kill(HARM_TYPE_NPC)
end


function car.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data

	if v.despawnTimer <= 0 then
		data.initialized = false

        if data.headLight ~= nil and data.headLight.isValid then
            data.headLight:destroy()
        end

		return
	end

    local config = NPC.config[v.id]

	if not data.initialized then
		initialise(v,data,config)
	end


    local isGrounded = false

    if v:mem(0x138,FIELD_WORD) == 0 and not v:mem(0x136,FIELD_BOOL) then
        if stoplight.currentColor ~= "red" and not v.friendly then
            if exNPC.getData(v).tagsList[1] ~= "mario_car" then
                v.speedX = math.clamp(v.speedX + config.acceleration*v.direction,-config.drivingSpeed,config.drivingSpeed)
                data.bounceTimer = data.bounceTimer + math.abs(v.speedX)
            end
        elseif v.collidesBlockBottom or config.nogravity then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - config.deceleration)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + config.deceleration)
            end

            if v.friendly then
                data.bounceTimer = data.bounceTimer + 1
            elseif math.abs(v.speedX) > 0.5 and not config.nogravity then
                if lunatime.tick()%4 == 0 then
                    for _,xOffset in ipairs(config.frontWheelsXPositions) do
                        local e = Effect.spawn(74,v.x + v.width*0.5 + xOffset*v.direction,v.y + v.height)

                        e.x = e.x - e.width*0.5
                        e.y = e.y - e.height*0.5
                    end
                end

                data.bounceTimer = data.bounceTimer + math.abs(v.speedX)*2
            else
                data.bounceTimer = 0
            end
        end

        if v:mem(0x120,FIELD_BOOL) and data.existanceTimer > 1 then
            explodeWithVaryingLevelsOfViolence(v,false)
        end

        data.existanceTimer = data.existanceTimer + 1

        if config.nogravity then
            data.flightTimer = data.flightTimer + 1
            v.speedY = math.cos(data.flightTimer / 8) * 0.3
        end

        isGrounded = (v.collidesBlockBottom or config.nogravity)
    else
        data.bounceTimer = data.bounceTimer + 2
        data.existanceTimer = 0
        isGrounded = true
    end


    -- Check if it's stood on
    local isStoodOn = false

    for _,p in ipairs(Player.get()) do
        if p.standingNPC == v then
            isStoodOn = true
            break
        end
    end

    if isStoodOn and not data.wasStoodOn then
        data.squashAnimationTimer = config.squashAnimationDuration
        SFX.play(RNG.irandomEntry(beepSFXList),0.5)
        SFX.play(RNG.irandomEntry(downSFXList))
    elseif not isStoodOn and data.wasStoodOn then
        data.squashAnimationTimer = config.squashAnimationDuration*0.5
        SFX.play(RNG.irandomEntry(upSFXList))
    end
    data.wasStoodOn = isStoodOn


    if isGrounded then
        if data.airTime >= 6 then
            data.squashAnimationTimer = config.squashAnimationDuration
        end

        if config.nogravity then
            data.bounceTimer = 0
        end

        data.airTime = 0
    else
        data.bounceTimer = 0
        data.airTime = data.airTime + 1
    end


    if data.squashAnimationTimer > 0 then
        local t = (data.squashAnimationTimer / config.squashAnimationDuration)
        data.stretch = math.cos(t * math.pi * 2) * t * -0.3

        data.squashAnimationTimer = math.max(0,data.squashAnimationTimer - 1)
    elseif not isGrounded then
        data.stretch = math.min(config.fallingStretchMax,data.stretch + config.fallingStetchSpeed)
    else
        data.stretch = 0
    end


	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = 0})
end


local lowPriorityStates = table.map{1,3,4}

function car.onDrawNPC(v)
    if v.despawnTimer <= 0 or v.isHidden then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.initialized then
		initialise(v,data,config)
	end


    local texture = Graphics.sprites.npc[v.id].img
    local frames = vector(config.colors,npcutils.getTotalFramesByFramestyle(v))

    if data.wheelsSprite == nil then
        data.wheelsSprite = Sprite{texture = texture,frames = frames,pivot = Sprite.align.BOTTOM}
        data.bodySprite = Sprite{texture = texture,frames = frames,pivot = Sprite.align.BOTTOM}

        data.bodySprite.transform:setParent(data.wheelsSprite.transform)
    end

    local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (config.foreground and -15) or -45
    local baseFrame = npcutils.getFrameByFramestyle(v,{frame = 0})


    for i,emitter in ipairs(data.emitters) do
        emitter.x = v.x + v.width*0.5 + (config.frontWheelsXPositions[i] + config.flameEmittersXOffset)*v.direction
        emitter.y = v.y + v.height + config.flameEmittersYOffset
        emitter:Draw(priority)
    end


    data.wheelsSprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    data.wheelsSprite.y = v.y + v.height + config.gfxoffsety

    data.wheelsSprite.scale = vector(math.lerp(1,0,data.stretch),math.lerp(1,2,data.stretch))

    if data.bounceTimer%config.bounceAnimationSpeed < config.bounceAnimationSpeed*0.5 then
        data.bodySprite.y = 2
    else
        data.bodySprite.y = 0
    end

    data.wheelsSprite:draw{frame = vector(data.color,baseFrame + 3),priority = priority,sceneCoords = true}
    data.bodySprite:draw{frame = vector(data.color,baseFrame + 2),priority = priority,sceneCoords = true}


    if data.headLight ~= nil and data.headLight.isValid then
        data.headLight.x = data.bodySprite.wposition.x + config.headLightXOffset*data.bodySprite.wscale.x*v.direction
        data.headLight.y = data.bodySprite.wposition.y + config.headLightYOffset*data.bodySprite.wscale.y
        data.headLight.dir = vector(v.direction,0)
    end


    npcutils.hideNPC(v)
end



local innocentDrivers = {4,7,8,9,186,197}
local rareDrivers = {14,25,29,199}
local superRareDrivers = {50,150}

function car.onPostNPCKill(v,reason)
    if not car.idMap[v.id] then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.initialized then
		initialise(v,data,config)
	end


    if data.headLight ~= nil and data.headLight.isValid then
        data.headLight:destroy()
    end


    if reason == HARM_TYPE_NPC then
        local e = Effect.spawn(config.deathEffectID,v.x + v.width*0.5,v.y + v.height*0.5,data.color)

        e.direction = v.direction
        e.speedX = -3 * e.direction
        e.speedY = -12
        e.rotation = -18 * e.direction


        local id
        if RNG.randomInt(1, 1800) == 1 then
            id = 201  -- ultra super rare driver
        elseif RNG.randomInt(1,50) == 1 then
            id = RNG.irandomEntry(superRareDrivers)
        elseif RNG.randomInt(1,3) == 1 then
            id = RNG.irandomEntry(rareDrivers)
        else
            id = RNG.irandomEntry(innocentDrivers)
        end

        local e = Effect.spawn(id,v.x + v.width*0.5,v.y + v.height)

        e.x = e.x - e.width *0.5
        e.y = e.y - e.height*0.5

        e.direction = v.direction
        e.speedX = -1.5 * e.direction
        e.speedY = -14
    end
end


function car.onPostPlayerHarm(p)
    local x1 = p.x - 4
    local y1 = p.y - 4
    local x2 = p.x + p.width + 4
    local y2 = p.y + p.height + 4

    for _,npc in NPC.iterateIntersecting(x1,y1,x2,y2) do
        if car.idMap[npc.id] and not npc.isGenerator and npc.despawnTimer > 0 and p.standingNPC ~= npc and not npc.data.hasExploded then
          npc.data.hasExploded = true -- it looks like sometimes this would trigger multiple times and cause an overflow with particles
            explodeWithVaryingLevelsOfViolence(npc,true)
        end
    end
end


function car.onDraw()
    if explosionParticle:Count() > 0 then
        explosionParticle:Draw(-5)
    end
end

function car.onStopLight(color)
    for k, v in ipairs(car.idList) do
        NPC.config[v].nohurt = (color == "red")
    end
end

function car.onInitAPI()
    registerEvent(car,"onPostNPCKill")
    registerEvent(car,"onPostPlayerHarm")

    registerEvent(car,"onDraw")
    registerEvent(car,"onStopLight")
end


return car
