-- Renders a review sheet: one row per character, chosen tags' frames side by side.
-- Set CAST = { names = {...}, tags = { {"idle_front",1}, ... }, scale = 4, out = "..." }

local C = CAST
local dir = "D:/GameDev/kowloon/assets/sprites/aseprite/"
local scale = C.scale or 4
local cols = #C.tags
local cw, ch = 32 * scale + 6, 48 * scale + 6
local sheet = Image(cw * cols, ch * #C.names, ColorMode.RGB)
sheet:clear(app.pixelColor.rgba(86, 90, 96, 255))
for row, name in ipairs(C.names) do
  local spr = app.open(dir .. name .. ".aseprite")
  for col, want in ipairs(C.tags) do
    local tagname, k = want[1], want[2] or 1
    local fnum
    for _, t in ipairs(spr.tags) do
      if t.name == tagname then fnum = math.min(t.fromFrame.frameNumber + k - 1, t.toFrame.frameNumber) end
    end
    if not fnum and want[3] then
      for _, t in ipairs(spr.tags) do
        if t.name == want[3] then fnum = t.fromFrame.frameNumber + (want[4] or 1) - 1 end
      end
    end
    if fnum then
      local img = Image(spr.width, spr.height, ColorMode.RGB)
      img:drawSprite(spr, fnum)
      for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
          local px = img:getPixel(x, y)
          if app.pixelColor.rgbaA(px) > 0 then
            for yy = 0, scale - 1 do
              for xx = 0, scale - 1 do
                sheet:drawPixel((col - 1) * cw + x * scale + xx, (row - 1) * ch + y * scale + yy, px)
              end
            end
          end
        end
      end
    end
  end
  spr:close()
end
sheet:saveAs(C.out)
print("cast sheet " .. #C.names .. " x " .. cols)
