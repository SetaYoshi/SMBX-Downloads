local animDraw = {}

coll = {}

function animDraw.load(table)
  local export = {}
  for i=1, #table do
    export[i] = Graphics.loadImage(Misc.resolveFile(table[i]..".png"))
  end
  return export
end

function animDraw.new(name,image,speed)
  coll[name] = {}
  coll[name].images = image
  coll[name].speed = speed
  coll[name].total = #image
  coll[name].timer = 0
  coll[name].frame = 1
end

function animDraw.get(name)
  return coll[name].images[coll[name].frame]
end

function animDraw.onTick()
  for k, v in pairs(coll) do
    coll[k].timer = coll[k].timer + 1
    if coll[k].timer >= coll[k].speed then
      coll[k].timer = 0
      coll[k].frame = coll[k].frame + 1
      if coll[k].frame > coll[k].total then
        coll[k].frame = 1
      end
    end
  end
end

function animDraw.onInitAPI()
    registerEvent(animDraw, "onTick", "onTick")
end

return animDraw
