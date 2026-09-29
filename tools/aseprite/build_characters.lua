-- Builds every character's .aseprite file from the hand-drawn paper doll.
--
-- Runs inside Aseprite (through the aseprite MCP's run_lua_script, or
-- `aseprite -b --script`). Reads assets/sprites/aseprite/build/doll.json
-- (written by scripts/sprite_catalog.py) and, per character:
--   * palette-swaps each hand-drawn part into the character's ramps
--   * applies sleeves, shorts, patterns, blinks, open mouths and glasses
--   * outlines each part one pixel all round in a darkened tone of what it
--     borders (selout), so overlapping parts get clean interior lines
--   * composes the parts onto named layers, frame by frame
--   * sets frame durations and one tag per animation and view (walk_side)
--   * saves assets/sprites/aseprite/<name>.aseprite
--   * exports assets/sprites/characters/<name>.png + .json (one row per tag)
--
-- Set ONLY = "mei" before dofile() to rebuild a single character.

local ROOT = "D:/GameDev/kowloon/"
local DOLL = ROOT .. "assets/sprites/aseprite/build/doll.json"
local SRC_DIR = ROOT .. "assets/sprites/aseprite/"
local OUT_DIR = ROOT .. "assets/sprites/characters/"

local LAYERS = { "Prop Back", "Far Arm", "Legs", "Body", "Arms", "Head", "Hair", "Prop" }
local OUTLINE_INK = { 32, 22, 20 }

local FAR = {
  B = "b", b = "n", n = "N", N = "N",
  F = "f", f = "g", g = "G", G = "G",
  S = "s", s = "k", k = "K", K = "K",
  T = "t", t = "u", u = "U", U = "U",
  H = "h", h = "j", j = "J", J = "J",
  A = "a", a = "q", q = "Q", Q = "Q",
}
local TO_SKIN = { B = "S", b = "s", n = "k", N = "K" }
local SKIN_TO = {
  top = { S = "T", s = "t", k = "u", K = "U" },
  accent = { S = "A", s = "a", k = "q", K = "Q" },
}
local TOP_TONES = { T = true, t = true, u = true, U = true }

local function hex(h)
  h = h:gsub("#", "")
  return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function read_all(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("a")
  f:close()
  return s
end

-- grid[y][x] = symbol, 1-based
local function to_grid(rows)
  local g = {}
  for y, row in ipairs(rows) do
    g[y] = {}
    for x = 1, #row do
      g[y][x] = row:sub(x, x)
    end
  end
  return g
end

local function darker(r, g, b, amount)
  return r * amount, g * amount, b * amount
end

-- Apply per-placement symbol transforms, then resolve symbols to colours.
-- Returns a colour grid: col[y][x] = {r,g,b} or nil.
local function resolve(pl, palette)
  local rows = pl.rows
  local g = to_grid(rows)
  local h = #g
  local w = h > 0 and #g[1] or 0

  if pl.blink then
    for x = 1, w do
      for y = 1, h - 1 do
        if g[y][x] == "e" and g[y + 1][x] == "e" then
          g[y][x] = "k"
        end
      end
    end
    for y = 1, h do for x = 1, w do if g[y][x] == "w" then g[y][x] = "s" end end end
  end
  if pl.mouth then
    for y = 1, h - 1 do
      for x = 1, w do
        if g[y][x] == "m" and g[y + 1][x] ~= "." then
          g[y + 1][x] = "m"
          goto mouth_done
        end
      end
    end
    ::mouth_done::
  end
  if pl.no_blush then
    for y = 1, h do for x = 1, w do if g[y][x] == "r" then g[y][x] = "s" end end end
  end

  local col = {}
  local extra = {}   -- pixels painted with explicit colours (glasses, patterns)
  for y = 1, h do
    col[y] = {}
    for x = 1, w do
      local s = g[y][x]
      if s ~= "." then
        local fx = pl.x + x - 1
        local fy = pl.y + y - 1
        if pl.shorts_y and TO_SKIN[s] and fy >= pl.shorts_y then s = TO_SKIN[s] end
        if pl.skirt_y and TO_SKIN[s] and fy >= pl.skirt_y then s = TO_SKIN[s] end
        if pl.sleeve and SKIN_TO[pl.sleeve.region][s] then
          local dx, dy = fx - pl.sleeve.x, fy - pl.sleeve.y
          if math.sqrt(dx * dx + dy * dy) < pl.sleeve.len then
            s = SKIN_TO[pl.sleeve.region][s]
          end
        end
        if pl.tone == "far" and FAR[s] then s = FAR[s] end
        local hexcol
        if pl.prop then
          hexcol = pl.colors[s]
        else
          hexcol = palette[s]
        end
        if hexcol then
          local r, gg, b = hex(hexcol)
          -- clothing patterns on the top's lit and base tones
          if pl.pattern and TOP_TONES[s] and s ~= "U" then
            local on = false
            if pl.pattern == "stripe" then on = ((fy % 3) == 1)
            elseif pl.pattern == "check" then on = ((math.floor(fx / 2) + math.floor(fy / 2)) % 2 == 0)
            elseif pl.pattern == "floral" then on = ((fx % 4 == 1 and fy % 4 == 1) or (fx % 4 == 3 and fy % 4 == 3))
            end
            if on then
              local pr, pg, pb = hex(pl.pattern_col)
              local k = (s == "u") and 0.78 or 1.0
              r, gg, b = pr * k, pg * k, pb * k
            end
          end
          col[y][x] = { r, gg, b }
        end
      end
    end
  end

  if pl.glasses then
    local rim = { 38, 42, 48 }
    local glass = { 176, 196, 206 }
    for y = 1, h do
      for x = 1, w do
        if g[y][x] == "e" and (y == 1 or g[y - 1][x] ~= "e") then
          -- a rim across the top of each eye, a lens glint beside it
          for dx = -1, 1 do
            if y - 1 >= 1 and col[y - 1][x + dx] then col[y - 1][x + dx] = rim end
          end
        end
        if g[y][x] == "w" then col[y][x] = glass end
      end
    end
    -- the bridge between the lenses (front view)
    if pl.view == "front" then
      local ey
      for y = 1, h do for x = 1, w do if g[y][x] == "e" and not ey then ey = y end end end
      if ey and ey > 1 then
        for x = 5, 6 do if col[ey - 1][x] then col[ey - 1][x] = rim end end
      end
    end
  end
  return col, w, h
end

-- One pixel of outline around the filled cells, in a darkened tone of the
-- neighbouring fill mixed toward the ink colour.
local function outline_cells(col, w, h)
  local out = {}
  for y = 0, h + 1 do
    for x = 0, w + 1 do
      local filled = col[y] and col[y][x]
      if not filled then
        local best
        for _, d in ipairs({ { 0, -1 }, { -1, 0 }, { 1, 0 }, { 0, 1 } }) do
          local n = col[y + d[2]] and col[y + d[2]][x + d[1]]
          if n then
            local lum = n[1] * 0.3 + n[2] * 0.59 + n[3] * 0.11
            if not best or lum < best.lum then best = { c = n, lum = lum } end
          end
        end
        if best then
          local r, g, b = darker(best.c[1], best.c[2], best.c[3], 0.36)
          r = r * 0.55 + OUTLINE_INK[1] * 0.45
          g = g * 0.55 + OUTLINE_INK[2] * 0.45
          b = b * 0.55 + OUTLINE_INK[3] * 0.45
          out[#out + 1] = { x = x, y = y, c = { r, g, b } }
        end
      end
    end
  end
  return out
end

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then
    img:drawPixel(x, y, app.pixelColor.rgba(math.floor(c[1] + 0.5), math.floor(c[2] + 0.5), math.floor(c[3] + 0.5), 255))
  end
end

local function draw_placement(img, pl, palette)
  local col, w, h = resolve(pl, palette)
  if pl.outline ~= false then
    for _, o in ipairs(outline_cells(col, w, h)) do
      put(img, pl.x + o.x - 1, pl.y + o.y - 1, o.c)
    end
  end
  for y = 1, h do
    for x = 1, w do
      if col[y][x] then put(img, pl.x + x - 1, pl.y + y - 1, col[y][x]) end
    end
  end
end

local function build(name, ch)
  local W, H = ch.size[1], ch.size[2]
  local spr = Sprite(W, H, ColorMode.RGB)
  local layers = {}
  for i, lname in ipairs(LAYERS) do
    local l = (i == 1) and spr.layers[1] or spr:newLayer()
    l.name = lname
    layers[lname] = l
  end
  local total = 0
  for _, tag in ipairs(ch.tags) do total = total + #tag.frames end
  for i = 2, total do spr:newEmptyFrame() end

  local fi = 1
  for _, tag in ipairs(ch.tags) do
    local first = fi
    for _, fr in ipairs(tag.frames) do
      local imgs = {}
      for _, pl in ipairs(fr.placements) do
        local img = imgs[pl.layer]
        if not img then
          img = Image(W, H, ColorMode.RGB)
          imgs[pl.layer] = img
        end
        draw_placement(img, pl, ch.palette)
      end
      for lname, img in pairs(imgs) do
        spr:newCel(layers[lname], spr.frames[fi], img, Point(0, 0))
      end
      spr.frames[fi].duration = fr.duration / 1000.0
      fi = fi + 1
    end
    local t = spr:newTag(first, fi - 1)
    t.name = tag.name
  end

  -- drop layers this character never uses
  for i = #spr.layers, 1, -1 do
    local l = spr.layers[i]
    if #l.cels == 0 and #spr.layers > 1 then spr:deleteLayer(l) end
  end

  spr:saveAs(SRC_DIR .. name .. ".aseprite")
  app.command.ExportSpriteSheet {
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.ROWS,
    splitTags = true,
    textureFilename = OUT_DIR .. name .. ".png",
    dataFilename = OUT_DIR .. name .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat = "{tag}#{tagframe}",
    listTags = true,
    listLayers = false,
    ignoreEmpty = false,
    mergeDuplicates = false,
    trim = false,
  }
  local nframes = #spr.frames
  local ntags = #spr.tags
  spr:close()
  return nframes, ntags
end

local doll = json.decode(read_all(DOLL))
local names = {}
for name, _ in pairs(doll.characters) do names[#names + 1] = name end
table.sort(names)
for _, name in ipairs(names) do
  if not ONLY or ONLY == name then
    local nf, nt = build(name, doll.characters[name])
    print(string.format("%s: %d frames, %d tags", name, nf, nt))
  end
end
