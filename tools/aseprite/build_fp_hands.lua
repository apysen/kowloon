-- Builds Mei's first-person hands: Grandfather's instant camera held up in
-- front of her. All of the pixel work happens here, in Aseprite.
--
-- Runs inside Aseprite (the aseprite MCP's run_lua_script with dofile(), or
-- `aseprite -b --script`). The source is the reference art the look was
-- chosen from, assets/sprites/aseprite/build/reference/fp_hands_reference.png:
-- 128 x 128 pixel art upscaled to 1254 px, two hands holding the camera up,
-- sleeves from the bottom corners. This:
--
--   1. samples it back to its own pixels (each taken from the middle of its
--      cell, which keeps its lines and single-pixel details crisp)
--   2. recolours her into the game: her hands in Mei's skin (#e8bc94) with
--      nails in her blush, her sleeves in her orange top (#e0823a). Skin and
--      sleeve are told apart by hue (peach against red-maroon), so her wrists
--      stay skin where they dip below the cuffs. Each tone maps by its value
--      onto the matching ramp, so the reference's light carries over as
--      painted. The camera and strap keep the reference's own colours: the
--      camera is exactly as drawn.
--   3. the strap's small tan ring, close to skin in hue, takes the camera's
--      trim tones rather than skin
--   4. keeps her hands as the reference drew them, closing the black line
--      wherever skin meets the background or her sleeve, evening out stray
--      single pixels of shading and nail on the flat of her skin (lines and
--      creases are left as drawn), and hand-pixels her
--      left little finger curling under the camera's corner (in the reference
--      it runs into the camera's side)
--   5. lays the art out on the first-person overlay (320 x 180, a sixth of
--      1080p, plus 40 rows below the screen) and carries each sleeve on past
--      the art's edges along the direction of her forearm, and the strap on
--      down along its own line, so nothing stops at a cut
--
-- Saves assets/sprites/aseprite/fp_hands.aseprite and exports
-- assets/sprites/fp/fp_hands.png (+ .json). viewfinder.gd slides it up the
-- screen as she lifts the camera, then scales it about the eyepiece as she
-- brings it to her eye.

local ROOT = "D:/GameDev/kowloon/"
local REF = ROOT .. "assets/sprites/aseprite/build/reference/fp_hands_reference.png"
local SRC = ROOT .. "assets/sprites/aseprite/fp_hands.aseprite"
local OUT = ROOT .. "assets/sprites/fp/fp_hands"

local N = 128                         -- the reference's own size in pixels
local W, H = 320, 220                 -- the overlay, with 40 rows below the screen
local ART_X, ART_Y = 96, 52           -- where the art sits on it
local CUFF_TOP = 90                   -- rows above: hands and camera
local BUTTON = { 76, 38, 90, 46 }     -- the reference's shutter button

local pc = app.pixelColor

local function hex(h)
  h = h:gsub("#", "")
  return { tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16) }
end

local function ramp(list)
  local out = {}
  for i, h in ipairs(list) do out[i] = hex(h) end
  return out
end

-- ramps, dark to light
local SLEEVE = ramp { "#3a160c", "#822b12", "#b35224", "#e0823a", "#faa053" }
local SKIN = ramp { "#4a2a22", "#875a4a", "#ba8a6f", "#e8bc94", "#ffd6ac" }
-- Grandfather's camera: line, black body (three tones), grey trim (five tones)
local CAMERA = ramp { "#100a0e", "#1a1519", "#262028", "#383039",
                      "#4f4149", "#6c5a5f", "#8b7777", "#b3a095", "#f2e0cb" }
local NAIL = ramp { "#d98c7c", "#f0aa96" }        -- her blush (#ea9c82), a shade either side
local INK = CAMERA[1]

-- ------------------------------------------------------------------ pixels
--
-- The art is worked on as a grid of colours (nil for clear) and written into
-- the Aseprite image at the end.

local function key(c) return c and (c[1] * 65536 + c[2] * 256 + c[3]) or -1 end

local function set_of(...)
  local s = {}
  for _, list in ipairs({ ... }) do
    for _, c in ipairs(list) do s[key(c)] = true end
  end
  return s
end

local IS_SKIN = set_of(SKIN)
local IS_SLEEVE = set_of(SLEEVE)

local function grid(w, h)
  local g = { w = w, h = h }
  for y = 0, h - 1 do g[y] = {} end
  return g
end

local function at(g, x, y)
  if x < 0 or y < 0 or x >= g.w or y >= g.h then return nil end
  return g[y][x]
end

local function copy(g)
  local c = grid(g.w, g.h)
  for y = 0, g.h - 1 do
    for x = 0, g.w - 1 do c[y][x] = g[y][x] end
  end
  return c
end

local N4 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local N8 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

local function commonest(list)
  local count, best, most = {}, nil, 0
  for _, c in ipairs(list) do
    if c then
      local k = key(c)
      count[k] = (count[k] or 0) + 1
      if count[k] > most then best, most = c, count[k] end
    end
  end
  return best, most
end

local function hsv(c)
  local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local d = mx - mn
  local h = 0
  if d > 0 then
    if mx == r then h = ((g - b) / d) % 6
    elseif mx == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
  end
  return h, (mx > 0 and d / mx or 0), mx
end

local function band(v, edges, list)
  for i, e in ipairs(edges) do
    if v < e then return list[i] end
  end
  return list[#edges + 1]
end

-- ------------------------------------------------------------------ 1. sample

local function sample()
  local ref = Image { fromFile = REF }
  assert(ref, "missing " .. REF)
  local s = ref.width / N
  local g = grid(N, N)
  for j = 0, N - 1 do
    for i = 0, N - 1 do
      local p = ref:getPixel(math.floor((i + 0.5) * s), math.floor((j + 0.5) * s))
      if pc.rgbaA(p) >= 128 then
        g[j][i] = { pc.rgbaR(p), pc.rgbaG(p), pc.rgbaB(p) }
      end
    end
  end
  return g
end

-- ------------------------------------------------------------------ 2. recolour

local function recolour(g)
  local out = grid(N, N)
  for y = 0, N - 1 do
    for x = 0, N - 1 do
      local c = g[y][x]
      if c then
        local h, s, v = hsv(c)
        local warm = (h < 0.09 or h > 0.9) and s >= 0.3
        local peach = warm and h >= 0.03 and h <= 0.09
        local blue = h > 0.5 and h < 0.7 and s > 0.3 and v > 0.3
        local r
        local in_button = x >= BUTTON[1] and x <= BUTTON[3] and y >= BUTTON[2] and y <= BUTTON[4]
        if not warm or in_button then
          r = c                                                         -- the camera and strap, as drawn
        elseif y < CUFF_TOP and h < 0.058 and v > 0.94 then
          r = NAIL[2]                                                   -- her nails: the plate, pinker than skin
        elseif y < CUFF_TOP and h <= 0.035 and v > 0.88 then
          r = NAIL[1]                                                   -- and its rim
        elseif y >= CUFF_TOP and not (peach and v > 0.62) then
          r = band(v, { 0.25, 0.42, 0.55, 0.68 }, SLEEVE)
        elseif v > 0.62 then
          if v > 0.95 and s < 0.42 then r = SKIN[5]
          else r = band(v, { 0.8, 0.94 }, { SKIN[2], SKIN[3], SKIN[4] }) end
        else
          r = band(v, { 0.3, 0.48 }, { SKIN[1], SKIN[2], SKIN[3] })
        end
        out[y][x] = r
      end
    end
  end
  return out
end

-- ------------------------------------------------------------------ 3. the strap's ring
--
-- The tan ring on the strap is close to skin in hue. Any small patch of
-- "skin" (under a dozen pixels) with no skin beside it is the ring, and
-- takes the camera's trim tones instead.

local TRIM = { CAMERA[6], CAMERA[7], CAMERA[8] }

local function strap_ring(g)
  local out = copy(g)
  local seen = {}
  for y = 0, N - 1 do
    for x = 0, N - 1 do
      local id = y * N + x
      if not seen[id] and IS_SKIN[key(g[y][x])] then
        local stack, comp = { { x, y } }, {}
        seen[id] = true
        while #stack > 0 do
          local p = table.remove(stack)
          comp[#comp + 1] = p
          for _, d in ipairs(N8) do
            local xx, yy = p[1] + d[1], p[2] + d[2]
            local nid = yy * N + xx
            if xx >= 0 and yy >= 0 and xx < N and yy < N and not seen[nid] and IS_SKIN[key(g[yy][xx])] then
              seen[nid] = true
              stack[#stack + 1] = { xx, yy }
            end
          end
        end
        if #comp < 12 then
          for _, p in ipairs(comp) do
            local _, _, v = hsv(g[p[2]][p[1]])
            out[p[2]][p[1]] = band(v, { 0.55, 0.8 }, TRIM)
          end
        end
      end
    end
  end
  return out
end

-- ------------------------------------------------------------------ 4. her hands
--
-- Even colouring: pink only where it forms a nail (three or more pixels
-- together), and a lone pixel of base, shade or highlight with none of its
-- own tone beside it takes the tone around it. The dark crease tones and the
-- black line are the drawing's lines, and stay.

local function even_skin(g)
  local out = copy(g)
  local nail = { [key(NAIL[1])] = true, [key(NAIL[2])] = true }
  local flat = { [key(SKIN[3])] = true, [key(SKIN[4])] = true, [key(SKIN[5])] = true }
  -- nails: groups of pink under three pixels are flecks
  local seen = {}
  for y = 0, N - 1 do
    for x = 0, N - 1 do
      local id = y * N + x
      if not seen[id] and nail[key(g[y][x])] then
        local stack, comp = { { x, y } }, {}
        seen[id] = true
        while #stack > 0 do
          local p = table.remove(stack)
          comp[#comp + 1] = p
          for _, d in ipairs(N8) do
            local xx, yy = p[1] + d[1], p[2] + d[2]
            local nid = yy * N + xx
            if xx >= 0 and yy >= 0 and xx < N and yy < N and not seen[nid] and nail[key(g[yy][xx])] then
              seen[nid] = true
              stack[#stack + 1] = { xx, yy }
            end
          end
        end
        if #comp < 3 then
          for _, p in ipairs(comp) do out[p[2]][p[1]] = SKIN[4] end
        end
      end
    end
  end
  -- lone flat tones
  local src = copy(out)
  for y = 1, N - 2 do
    for x = 1, N - 2 do
      local me = src[y][x]
      if flat[key(me)] then
        local lone = true
        for _, d in ipairs(N4) do
          if key(src[y + d[2]][x + d[1]]) == key(me) then lone = false end
        end
        if lone then
          local around = {}
          for _, d in ipairs(N8) do
            local c = src[y + d[2]][x + d[1]]
            if flat[key(c)] then around[#around + 1] = c end
          end
          local best, most = commonest(around)
          if best and most >= 3 then out[y][x] = best end
        end
      end
    end
  end
  return out
end

--
-- As drawn, with the black line closed wherever skin meets the background or
-- her sleeve (where the reference's line was lost in sampling, or where her
-- wrist now meets her cuff). A dark skin pixel on the edge is the reference's
-- own line: it becomes the line, rather than getting a second one outside it.

local function outline_hands(g)
  g = copy(g)
  local dark = { [key(SKIN[1])] = true, [key(SKIN[2])] = true }
  for y = 0, N - 1 do
    for x = 0, N - 1 do
      if dark[key(g[y][x])] then
        for _, d in ipairs(N4) do
          local xx, yy = x + d[1], y + d[2]
          if xx < 0 or yy < 0 or xx >= N or yy >= N or g[yy][xx] == nil then
            g[y][x] = INK
            break
          end
        end
      end
    end
  end
  local out = copy(g)
  for y = 0, N - 1 do
    for x = 0, N - 1 do
      if IS_SKIN[key(g[y][x])] then
        for _, d in ipairs(N4) do
          local xx, yy = x + d[1], y + d[2]
          if xx >= 0 and yy >= 0 and xx < N and yy < N then
            local c = g[yy][xx]
            if c == nil or IS_SLEEVE[key(c)] then out[yy][xx] = INK end
          end
        end
      end
    end
  end
  return out
end

-- Her left little finger, hand-pixelled: the camera's left side (black line,
-- lighter edge, black line) and its bottom-left corner run unbroken, and the
-- finger curls under that corner in a small rounded tip joined to her palm.
-- Columns 41 to 48, rows 76 to 84 of the art.
--   O line  E the camera's side edge  1 3 4 skin  . clear  - leave as drawn

local PINKY = {
  "-OOEO---",
  "-OOEO---",
  "-OOEO---",
  "-OOEO---",
  "3OOOOOO-",
  "33443O..",
  "3343O...",
  "333O....",
  "-3O.....",
}
local PINKY_COL = { O = INK, E = hex("#2e2a33"), ["1"] = SKIN[1], ["3"] = SKIN[3], ["4"] = SKIN[4] }

local function pinky(g)
  for r, row in ipairs(PINKY) do
    for i = 1, #row do
      local ch = row:sub(i, i)
      if ch == "." then
        g[75 + r][40 + i] = nil
      elseif ch ~= "-" then
        g[75 + r][40 + i] = PINKY_COL[ch]
      end
    end
  end
  return g
end

-- The fingers of her right hand curling under the camera: a short stroke of
-- line near the top of the wedge marks where one finger ends and the next
-- begins. Placed by hand in Aseprite; (x, y) in the art.

local FINGER_GAP = { { 77, 81 }, { 78, 81 }, { 79, 82 }, { 80, 82 } }

local function finger_gap(g)
  for _, p in ipairs(FINGER_GAP) do g[p[2]][p[1]] = INK end
  return g
end

-- ------------------------------------------------------------------ 5. lay out

local function lay_out(art)
  local canvas = grid(W, H)
  for y = 0, N - 1 do
    for x = 0, N - 1 do canvas[ART_Y + y][ART_X + x] = art[y][x] end
  end
  for _, side in ipairs({ -1, 1 }) do
    -- the sleeve's outer outline where it is still inside the art: its line
    -- gives the arm's direction
    local ys, xs = {}, {}
    for y = CUFF_TOP, N - 1 do
      local edge
      if side < 0 then
        for x = 0, N // 2 - 1 do if art[y][x] then edge = x break end end
      else
        for x = N - 1, N // 2, -1 do if art[y][x] then edge = x break end end
      end
      if edge and edge > 0 and edge < N - 1 then ys[#ys + 1] = y; xs[#xs + 1] = edge end
    end
    local first = math.max(1, #ys - 9)
    local n, sx, sy, sxy, syy = 0, 0, 0, 0, 0
    for i = first, #ys do
      n = n + 1; sx = sx + xs[i]; sy = sy + ys[i]; sxy = sxy + xs[i] * ys[i]; syy = syy + ys[i] * ys[i]
    end
    local slope = (n * sxy - sx * sy) / (n * syy - sy * sy)
    local icept = (sx - slope * sy) / n
    local len = math.sqrt(slope * slope + 1)
    local dx, dy = slope / len, 1 / len
    local xa, xb = 0, ART_X + N // 2 - 1
    if side > 0 then xa, xb = ART_X + N // 2, W - 1 end
    for cy = ART_Y + CUFF_TOP, H - 1 do
      local edge = icept + slope * (cy - ART_Y) + ART_X
      for cx = xa, xb do
        local in_art = cx >= ART_X and cx < ART_X + N and cy < ART_Y + N
        local beyond = (side < 0 and cx < edge - 0.5) or (side > 0 and cx > edge + 0.5)
        if not in_art and not beyond then
          -- trace back up the arm into the painted sleeve
          local px, py = cx + 0.5, cy + 0.5
          local ax, ay
          for _ = 1, 400 do
            px, py = px - dx * 0.5, py - dy * 0.5
            ax, ay = math.floor(px) - ART_X, math.floor(py) - ART_Y
            if ax >= 0 and ax < N and ay >= 0 and ay < N then break end
          end
          local own = (side < 0 and ax < N // 2) or (side > 0 and ax >= N // 2)
          if ax >= 0 and ax < N and ay >= CUFF_TOP and ay < N and own and art[ay][ax] then
            canvas[cy][cx] = art[ay][ax]
          end
        end
      end
      local ex = math.floor(edge + 0.5)
      if ex >= 0 and ex < W and not (ex >= ART_X and ex < ART_X + N and cy < ART_Y + N) then
        canvas[cy][ex] = INK
      end
    end
  end
  -- the strap hangs on down between her arms: each run of strap in the art's
  -- last row carries on below it, following the line it came down on
  local function strap_runs(y)
    local runs, x = {}, 0
    while x < N do
      local c = art[y][x]
      local function strap(p) return p and not IS_SKIN[key(p)] and not IS_SLEEVE[key(p)] end
      if strap(c) then
        local a = x
        while x < N and strap(art[y][x]) do x = x + 1 end
        runs[#runs + 1] = { a, x - 1 }
      else
        x = x + 1
      end
    end
    return runs
  end
  local last, above = strap_runs(N - 1), strap_runs(N - 9)
  for _, r in ipairs(last) do
    local mid = (r[1] + r[2]) / 2
    local slope = 0
    for _, q in ipairs(above) do
      local qm = (q[1] + q[2]) / 2
      if math.abs(qm - mid) < 6 then slope = (mid - qm) / 8 end
    end
    for k = 1, H - (ART_Y + N) do
      local shift = math.floor(slope * k + 0.5)
      local cy = ART_Y + N - 1 + k
      for x = r[1], r[2] do
        local cx = ART_X + x + shift
        if cx >= 0 and cx < W and cy < H and not canvas[cy][cx] then
          canvas[cy][cx] = art[N - 1][x]
        end
      end
    end
  end
  return canvas
end

-- ------------------------------------------------------------------ build

local art = finger_gap(pinky(outline_hands(even_skin(strap_ring(recolour(sample()))))))
local canvas = lay_out(art)

local spr = Sprite(W, H, ColorMode.RGB)
spr.filename = SRC
local layer = spr.layers[1]
layer.name = "Hands"
local img = Image(W, H, ColorMode.RGB)
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local c = canvas[y][x]
    if c then img:drawPixel(x, y, pc.rgba(c[1], c[2], c[3], 255)) end
  end
end
spr:newCel(layer, 1, img, Point(0, 0))
local tag = spr:newTag(1, 1)
tag.name = "carry"
spr:saveAs(SRC)
app.command.ExportSpriteSheet {
  ui = false, askOverwrite = false, type = SpriteSheetType.HORIZONTAL,
  textureFilename = OUT .. ".png", dataFilename = OUT .. ".json", dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
  listTags = true,
}
print("fp_hands: built in Aseprite -> " .. OUT .. ".png")
