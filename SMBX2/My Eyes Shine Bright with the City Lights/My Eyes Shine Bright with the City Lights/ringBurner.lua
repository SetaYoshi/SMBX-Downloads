-- This version is modified. I do not suggest you use this library and instead download the NPC yourself

local rb = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sl = require("stoplight")


local sh = Shader()
sh:compileFromFile(nil, Misc.resolveFile("ringburner.frag"))

local pt = require("particles")
local sparkEmitter = pt.Emitter(0,0,Misc.resolveFile("p_ringburner.ini"))

function rb.onInitAPI()
    registerEvent(rb, "onDraw")
end

function rb.onDraw()
    sparkEmitter:Draw(-44.99999, true)
end

function rb.register(id)
    npcManager.registerEvent(id, rb, "onTickEndNPC")
    npcManager.registerEvent(id, rb, "onDrawNPC")
end

local STATE = {
    IDLE = 0,
    WINDDOWN = 1
}

local function cFalloff(x)
    return 1 - x
end

function rb.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    local data = v.data

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        data.init = false
        return
    end

    if not data.init then
        data.init = true
        data.timer = 0
        data.state = STATE.IDLE
        data.radius = 0
        data.ringspeed = 0
        data.angle = 0
        data.scale = 1
        data.opacity = 1
        data.angularSpeed = 0
        if data.col == nil then
            data.col = {
                inner = Colliders.Circle(0,0,0),
                outer = Colliders.Circle(0,0,0),
            }
            data.pf = pt.PointField(0,0,0,100, cFalloff)
            data.pf:addEmitter(sparkEmitter, false)
        end
    end

    local cfg = NPC.config[v.id]

    data.timer = data.timer + 1
    if data.state == STATE.IDLE and sl.currentColor ~= "green" then
      data.timer = 0
    end

    if data.state == STATE.IDLE then
        if data.timer >= cfg.windup then
            data.state = STATE.WINDDOWN
            data.angularSpeed = 20 * v.direction
            data.radius = 0
            data.opacity = 1
            data.timer = 0
            data.scale = 1.2
            data.ringspeed = cfg.pulsespeed
            SFX.play("sfx_ringburner_fire.ogg")
        elseif data.timer == cfg.windup - 16 then
            data.angle = -20 * v.direction
            data.scale = 1.2
            SFX.play("sfx_ringburner_lock.ogg")
        end
    else
        local limit = cfg.radius
        local s = math.abs(cfg.pulsespeed)
        local anticipationTime = (s * s) / (2 * math.abs(cfg.pulsedrag))

        local cx = v.x + 0.5 * v.width
        local cy = v.y + 0.5 * v.height

        data.radius = data.radius + data.ringspeed

        data.col.outer.x = cx
        data.col.outer.y = cy

        data.col.inner.x = cx
        data.col.inner.y = cy

        data.col.outer.radius = math.max(data.radius - 2, 0)
        data.col.inner.radius = math.max(data.radius - 6, 0)

        if data.radius > limit - anticipationTime then
            data.ringspeed = data.ringspeed - cfg.pulsedrag
            data.opacity = data.ringspeed / cfg.pulsespeed
        end

        if data.radius < limit - 16 then
            for k,p in ipairs(Player.get()) do
                if Colliders.collide(p, data.col.outer) then
                    if data.radius < p.height then
                        player:harm()
                    else
                        if Colliders.collide(p, data.col.inner) then
                            local pts = 0
                            for k,p in ipairs({{0,0}, {p.width,0}, {0,p.height}, {p.width,p.height}}) do
                                local point = Colliders.Point(player.x + p[1], player.y + p[2])
                                if Colliders.collide(point, data.col.inner) then
                                    pts = pts + 1
                                else
                                    break
                                end
                            end
                            if pts < 4 then
                                player:harm()
                            end
                        else
                            player:harm()
                        end
                    end
                end
            end

            sparkEmitter.x = cx
            sparkEmitter.y = cy

            data.pf.x = cx
            data.pf.y = cy

            data.pf.radius = data.radius
            sparkEmitter:setParam("radOffset", data.radius .. ":" .. data.radius)
            sparkEmitter:Emit(1)
        end

        if  math.abs(data.angularSpeed) <= 1 then
            if data.angularSpeed ~= 0 then
                data.angle = 0
                data.scale = 1.1
                data.angularSpeed = 0
                SFX.play("sfx_ringburner_lock.ogg")
            end
        else
            data.angularSpeed = data.angularSpeed * 0.95
        end

        if data.radius >= limit then
            data.pf.radius = 0
            data.state = STATE.IDLE
            data.timer = 0
            data.opacity = 0
            if data.angularSpeed ~= 0 then
                data.angularSpeed = 0
                data.angle = 0
                data.scale = 1.1
                SFX.play("sfx_ringburner_lock.ogg")
            end
            data.col.outer.radius = 0
            data.col.inner.radius = 0
        end
    end

    if data.scale > 1 then
        data.scale = data.scale * 0.99
    else
        data.scale = data.scale * 1.01
    end
    if data.scale >= 0.95 and data.scale <= 1.05 then
        data.scale = 1
    end

    data.angle = data.angle + data.angularSpeed
end

function rb.onDrawNPC(v)
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        return
    end

    local cfg = NPC.config[v.id]

    local data = v.data

    if not data.scale then return end

    local p = -45
    if cfg.foreground then
        p = -15
    end

    local gfxw, gfxh = cfg.gfxwidth * 0.5 * data.scale, cfg.gfxheight * 0.5 * data.scale

    local vt = {
        vector(-gfxw, -gfxh),
        vector(gfxw, -gfxh),
        vector(gfxw, gfxh),
        vector(-gfxw, gfxh),
    }

    local tx = {
        0, 0,
        1, 0,
        1, 1,
        0, 1,
    }

    local x, y = v.x + 0.5 * v.width, v.y + 0.5 * v.height

    for k,a in ipairs(vt) do
        vt[k] = a:rotate(data.angle or 0)
    end

    local c = 1
    if v.friendly then
        c = 0.65
    end

    Graphics.glDraw{
        vertexCoords = {
            x + vt[1].x, y + vt[1].y,
            x + vt[2].x, y + vt[2].y,
            x + vt[3].x, y + vt[3].y,
            x + vt[4].x, y + vt[4].y,
        },
        textureCoords = tx,
        primitive = Graphics.GL_TRIANGLE_FAN,
        texture = Graphics.sprites.npc[v.id].img,
        sceneCoords = true,
        priority = p,
        color = {
            c,c,c,1
        }
    }

    Graphics.drawScreen{
        priority = p - 0.01,
        shader = sh,
        uniforms = {
            center = {v.x - camera.x + 0.5 * v.width, v.y - camera.y + 0.5 * v.height},
            radius = data.radius,
            alpha = data.opacity
        }
    }

    npcutils.hideNPC(v)
end

return rb
