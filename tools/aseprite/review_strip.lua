-- Renders a zoomed review strip of chosen frames from a character file.
-- Set REVIEW = { file = ".../mei.aseprite", tags = { "idle_front", ... },
--                out = ".../strip.png", scale = 8, frame = 1 } before dofile().
-- `frame` picks which frame of each tag (1-based); "all" lays out every frame.

local R = REVIEW
local spr = app.open(R.file)
local scale = R.scale or 8
local picks = {}
for _, want in ipairs(R.tags) do
  for _, t in ipairs(spr.tags) do
    if t.name == want then
      if R.frame == "all" then
        for f = t.fromFrame.frameNumber, t.toFrame.frameNumber do picks[#picks + 1] = f end
      else
        picks[#picks + 1] = math.min(t.fromFrame.frameNumber + (R.frame or 1) - 1, t.toFrame.frameNumber)
      end
    end
  end
end
local cw = spr.width * scale + 8
local strip = Image(math.max(1, cw * #picks - 8), spr.height * scale, ColorMode.RGB)
strip:clear(app.pixelColor.rgba(86, 90, 96, 255))
for i, fnum in ipairs(picks) do
  local img = Image(spr.width, spr.height, ColorMode.RGB)
  img:drawSprite(spr, fnum)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local px = img:getPixel(x, y)
      if app.pixelColor.rgbaA(px) > 0 then
        for yy = 0, scale - 1 do
          for xx = 0, scale - 1 do
            strip:drawPixel((i - 1) * cw + x * scale + xx, y * scale + yy, px)
          end
        end
      end
    end
  end
end
strip:saveAs(R.out)
spr:close()
print("review frames: " .. #picks)
