"""Hand-pixelled body parts for the character paper doll.

Parts are FILL shapes with hand-placed shading; outlines are not drawn here.
Aseprite's compositor (tools/aseprite/build_characters.lua) outlines each part
one pixel all round, taking a darkened tone of the region it borders
("selout"), so where a front part overlaps a back part the front part's
outline becomes the interior line between them. Keeping outlines out of the
authored shapes is what keeps every silhouette clean: no doubled lines, no
stair-step notches, one rule applied the same way to the whole cast.

Symbols (region + tone, light comes from the upper left):

    .          transparent
    S s k K    skin      highlight, base, shade, deep
    H h j J    hair
    T t u U    top       (shirt, blouse, singlet)
    B b n N    bottom    (trousers, shorts, skirt)
    F f g G    shoes
    A a q Q    accent    (collar, apron, coat, cap, belt)
    e          eye
    w          eye catch-light
    m          mouth
    r          blush     (skin base when the character has none)
    1 2 3 4    prop tones, light to dark, in the prop's own ramp
    5 6        prop accents

A part is (x, y, rows): the frame position of the grid's top-left pixel in a
32 x 48 frame whose shoe soles are outlined on row 46. Arms also carry a
shoulder point, from which sleeve length is measured.
"""

# =============================================================================
# ADULT
# =============================================================================
#
# Vertical layout (fill rows; outlines add one pixel around each part):
#   head   5..15   neck 16..17   torso 18..28   pelvis 30..31
#   legs  32..42   shoes 43..45  soles outlined on 46

HEAD = {
    "front": (11, 5, [
        "..SSssss..",
        ".SSsssssk.",
        "SSsssssssk",
        "Sssssssssk",
        "Sssssssssk",
        "ssseSsessk",
        "ssweSsewsk",
        "sssssksssk",
        "srssmmssrk",
        ".kssssssk.",
        "..kssssk..",
    ]),
    "back": (11, 5, [
        "..SSssss..",
        ".SSsssssk.",
        "SSsssssssk",
        "Sssssssssk",
        "Sssssssssk",
        "Sssssssssk",
        "Sssssssssk",
        "Sssssssssk",
        "sssssssskk",
        ".kssssskk.",
        "..kkkkkk..",
    ]),
    "side": (11, 5, [
        "..SSsss....",
        ".SSssssss..",
        "SSsssssssk.",
        "Sssssssssk.",
        "Sssssssssk.",
        "sssksssses.",
        "ssskksssess",
        "ssskssssrsk",
        "ssssssssmk.",
        ".kssssssk..",
        "..kksssk...",
    ]),
}

NECK = {
    "front": (15, 16, ["kk", "kK"]),
    "back": (15, 16, ["kk", "kk"]),
    "side": (15, 16, ["kk", "kK"]),
}

TORSO = {
    "front": (11, 18, [
        ".TTtkktu..",
        "TTttttttuu",
        "Ttttttttuu",
        "Ttttttttuu",
        "Ttttttttuu",
        ".Tttttttu.",
        ".Tttttttu.",
        ".Tttttttu.",
        ".Ttttttuu.",
        "Tttttttuuu",
        "tuuuuuuuuU",
    ]),
    "back": (11, 18, [
        ".TTttttu..",
        "TTttttttuu",
        "Ttttttttuu",
        "Tttttuttuu",
        "Tttttuttuu",
        ".Ttttuttu.",
        ".Tttttttu.",
        ".Tttttttu.",
        ".Ttttttuu.",
        "Tttttttuuu",
        "tuuuuuuuuU",
    ]),
    "side": (12, 18, [
        ".TTtttu.",
        "TTttttuu",
        "Tttttttu",
        "Tttttttu",
        "Tttttttu",
        ".Tttttu.",
        ".Tttttu.",
        ".Tttttu.",
        ".Ttttuu.",
        "Ttttttuu",
        "tuuuuuuU",
    ]),
}

# ------------------------------------------------------------------ legs

LEGS_FRONT_IDLE = (11, 30, [
    "BBbbbbbbnn",
    "Bbbbbnbbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "bbnn..bbnn",
    "Fffg..Fffg",
    "ffgg..ffgg",
    "gggG..gggG",
])

LEGS_BACK_IDLE = (11, 30, [
    "BBbbbbbbnn",
    "Bbbbbnbbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "Bbbn..Bbbn",
    "bbnn..bbnn",
    "ffgg..ffgg",
    "ffgg..ffgg",
    "gggG..gggG",
])


def front_lift(legs, side: str, lift: int):
    """The same legs with one foot raised `lift` px: the passing phase of a
    step seen from the front. The raised leg shortens (the knee comes toward
    the camera) and its shoe rises; nothing else moves."""
    x, y, rows = legs
    cols = (0, 4) if side == "left" else (6, 10)
    out = [list(r) for r in rows]
    leg = [r[cols[0]:cols[1]] for r in rows]
    top = leg[:4]
    shin = leg[4:10]
    rest = leg[10:]
    shin = shin[:len(shin) - lift]
    new_leg = top + shin + rest + ["...."] * lift
    for i, r in enumerate(out):
        r[cols[0]:cols[1]] = list(new_leg[i])
    return (x, y, ["".join(r) for r in out])


# The side walk: six frames built from three drawn poses. In frames 3-5 the
# same poses play with the legs' roles swapped (the near leg becomes the far
# one), which the compositor does by swapping tones and draw order.
# Each pose is two legs drawn separately so each gets its own outline:
# the leading leg ("a") and the trailing leg ("b"). Thighs and shins are
# 3 px strokes that step one pixel at a time; knees are a 4 px joint so the
# bend reads as a bend, not a notch.
SIDE_WALK = [
    {   # contact: leading leg reaching forward, heel down; trailing leg pushing off
        "a": (15, 30, [
            "Bbbn.....",
            "Bbbn.....",
            ".Bbbn....",
            ".Bbbn....",
            ".Bbbn....",
            "..Bbbn...",
            "..Bbbn...",
            "..Bbbn...",
            "...Bbbn..",
            "...Bbbn..",
            "...bbnn..",
            "...FffggG",
            "...ffffgg",
            "....gggG.",
        ]),
        "b": (10, 30, [
            "....Bbbn",
            "....Bbbn",
            "...Bbbn.",
            "...Bbbn.",
            "...Bbbn.",
            "..Bbbn..",
            "..Bbbn..",
            "..Bbbn..",
            ".Bbbn...",
            ".Bbbn...",
            ".bbnn...",
            "Fffgg...",
            "ffffgG..",
            ".ggggG..",
        ]),
        "bob": 0,
    },
    {   # down: weight settles on the leading leg, the trailing foot peels up behind
        "a": (15, 30, [
            "Bbbn...",
            "Bbbn...",
            "Bbbn...",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".bbnn..",
            ".FfffgG",
            ".ffffgg",
            "..gggG.",
        ]),
        "b": (9, 30, [
            "...Bbbn.",
            "...Bbbn.",
            "...Bbbn.",
            "..Bbbn..",
            "..Bbbn..",
            "..Bbbn..",
            "..Bbbn..",
            ".Bbbbn..",
            ".Bbbn...",
            "Bbbn....",
            "Bbbn....",
            "bbnn....",
            "Fffgg...",
            "ffggG...",
        ]),
        "bob": 1,
    },
    {   # passing: trailing leg swings through, knee forward, foot tucked up
        "a": (14, 30, [
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".Bbbn..",
            ".bbnn..",
            ".FfffgG",
            ".ffffgg",
            "..gggG.",
        ]),
        "b": (13, 30, [
            "Bbbn...",
            "Bbbbn..",
            ".Bbbn..",
            ".Bbbbn.",
            "..Bbbn.",
            "..Bbbbn",
            "..Bbbbn",
            ".Bbbnn.",
            ".Bbbn..",
            ".bbnn..",
            ".Fffgg.",
            ".ffggG.",
        ]),
        "bob": 0,
    },
]

SIDE_IDLE = {
    "a": (14, 30, [
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".Bbbn..",
        ".bbnn..",
        ".FfffgG",
        ".ffffgg",
        "..gggG.",
    ]),
    "b": (12, 30, [
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".Bbbn...",
        ".bbnn...",
        ".Fffgg..",
        ".ffffg..",
        "..gggG..",
    ]),
}

PELVIS = {
    "front": (11, 30, ["BBbbbbbbnn", "Bbbbbnbbbn"]),
    "back": (11, 30, ["BBbbbbbbnn", "Bbbbbnbbbn"]),
    "side": (12, 30, ["BBbbbbnn", "Bbbbbbnn"]),
}

# seated on a stool: thighs forward, shins down
LEGS_SEATED = {
    "front": (11, 35, [
        "BBbbbbbbnn",
        "Bbbbbnbbbn",
        "BBbn..BBbn",
        "Bbbn..Bbbn",
        "Bbbn..Bbbn",
        "Bbbn..Bbbn",
        "bbnn..bbnn",
        "Fffg..Fffg",
        "ffgg..ffgg",
        "gggG..gggG",
    ]),
    "back": (11, 35, [
        "BBbbbbbbnn",
        "Bbbbbnbbbn",
        "bbnn..bbnn",
    ]),
    "side": (12, 35, [
        "BBbbbbbbn...",
        "Bbbbbbbbbn..",
        "bbnnnnBbbn..",
        "......Bbbn..",
        "......Bbbn..",
        "......Bbbn..",
        "......bbnn..",
        "......FfffgG",
        "......ffffgg",
        ".......gggG.",
    ]),
}

# crouched on the heels (the repairman)
LEGS_CROUCH = {
    "front": (10, 37, [
        ".BBbbbbbbnn.",
        "BBbbbbbbbbnn",
        "Bbbn....Bbbn",
        "Bbbn....Bbbn",
        "bbnn....bbnn",
        "Fffg....Fffg",
        "ffgg....ffgg",
        "gggG....gggG",
    ]),
    "back": (10, 37, [
        ".BBbbbbbbnn.",
        "BBbbbbbbbbnn",
        "bbnn....bbnn",
        "ffgg....ffgg",
        "gggG....gggG",
    ]),
    "side": (11, 37, [
        "BBbbbbbbbn..",
        "Bbbbbbbbbbn.",
        ".bbn..Bbbbn.",
        ".......Bbbn.",
        "......bbnnn.",
        "......FfffgG",
        "......ffffgg",
        ".......gggG.",
    ]),
}

# ------------------------------------------------------------------ arms
#
# Arms are drawn as skin; the compositor turns the part nearest the shoulder
# into sleeve (top tones) for as many pixels as the character's sleeves reach.
# "shoulder" is the frame point sleeve length is measured from.

ARMS = {
    # hanging at the sides; front view (viewer's left is the character's right)
    "front_l": {"part": (8, 19, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (8, 19)},
    "front_r": {"part": (22, 19, ["sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (23, 19)},
    "front_l_fwd": {"part": (8, 19, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (8, 19)},
    "front_r_fwd": {"part": (22, 19, ["sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (23, 19)},
    "front_l_back": {"part": (8, 19, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (8, 19)},
    "front_r_back": {"part": (22, 19, ["sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (23, 19)},
    # forearms raised to hold something against the chest
    "front_l_hold": {"part": (8, 19, [
        "SS....",
        "Ss....",
        "Ss....",
        "Ss....",
        "SsSSs.",
        ".Ssssk",
    ]), "shoulder": (8, 19)},
    "front_r_hold": {"part": (18, 19, [
        "....sk",
        "....sk",
        "....sk",
        "....sk",
        ".sssk k".replace(" ", ""),
        "sssskK",
    ]), "shoulder": (23, 19)},
    # one hand up at the mouth (a cigarette, chopsticks, a fan by the cheek)
    "front_r_mouth": {"part": (17, 13, [
        "ss.....",
        "ssk....",
        ".ssk...",
        "..ssk..",
        "...ssk.",
        "....ssk",
        ".....sk",
    ]), "shoulder": (23, 19)},
    # both hands up at the face (the camera to the eye)
    "front_l_camera": {"part": (8, 11, [
        "....Ss",
        "...SSs",
        "..SSs.",
        ".SSs..",
        "SSs...",
        "Ss....",
        "Ss....",
        "Ss....",
        "Ss....",
    ]), "shoulder": (8, 19)},
    "front_r_camera": {"part": (18, 11, [
        "sk....",
        "ssk...",
        ".ssk..",
        "..ssk.",
        "...ssk",
        "....sk",
        "....sk",
        "....sk",
        "....sk",
    ]), "shoulder": (23, 19)},
    # one arm up high (reaching for a line, a peg, a handhold)
    "front_r_up": {"part": (22, 7, ["ss", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk"]), "shoulder": (23, 19)},
    "front_l_up": {"part": (8, 7, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss"]), "shoulder": (8, 19)},
    # pointing up and out at the sky
    "front_r_point": {"part": (22, 9, [
        "...ss",
        "..ssk",
        "..sk.",
        ".ssk.",
        ".sk..",
        "ssk..",
        "sk...",
        "sk...",
        "sk...",
        "sk...",
    ]), "shoulder": (23, 19)},
    # side view, near arm: swing -2 (back) .. +2 (forward)
    "side_back2": {"part": (11, 19, [
        "...ss",
        "...sk",
        "..ssk",
        "..sk.",
        ".ssk.",
        ".sk..",
        "ssk..",
        "sk...",
        "kk...",
    ]), "shoulder": (15, 19)},
    "side_back1": {"part": (13, 19, [
        "..ss",
        "..sk",
        "..sk",
        ".ssk",
        ".sk.",
        ".sk.",
        ".sk.",
        "ssk.",
        "sk..",
        "kk..",
    ]), "shoulder": (15, 19)},
    "side_mid": {"part": (15, 19, ["ss", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "kk"]), "shoulder": (15, 19)},
    "side_fwd1": {"part": (15, 19, [
        "ss..",
        "sk..",
        "sk..",
        "ssk.",
        ".sk.",
        ".sk.",
        ".sk.",
        ".ssk",
        "..sk",
        "..kk",
    ]), "shoulder": (15, 19)},
    "side_fwd2": {"part": (15, 19, [
        "ss....",
        "sk....",
        "sk....",
        "ssk...",
        ".ssk..",
        "..ssk.",
        "...ssk",
        "....sk",
        "....kk",
    ]), "shoulder": (15, 19)},
    # side: forearm out in front at chest height (carrying, holding a paper)
    "side_hold": {"part": (15, 19, [
        "ss.....",
        "sk.....",
        "sk.....",
        "sk.....",
        "sssssss",
        ".kkkkkk",
    ]), "shoulder": (15, 19)},
    # side: the hand up at the mouth
    "side_mouth": {"part": (15, 15, [
        "....ss",
        "...ssk",
        "..ssk.",
        ".ssk..",
        "ssk...",
    ]), "shoulder": (15, 19)},
    # side: raised to the face (camera)
    "side_camera": {"part": (15, 12, [
        "....ss",
        "...ssk",
        "..ssk.",
        ".ssk..",
        "ssk...",
        "sk....",
        "sk....",
        "sk....",
        "sk....",
        "sk....",
    ]), "shoulder": (15, 19)},
    # side: up and forward (reaching, pointing)
    "side_up": {"part": (15, 8, [
        "....ss",
        "....sk",
        "...ssk",
        "...sk.",
        "..ssk.",
        "..sk..",
        ".ssk..",
        ".sk...",
        "ssk...",
        "sk....",
        "sk....",
        "sk....",
    ]), "shoulder": (15, 19)},
    # side: elbow out in front, forearm straight up past the face (the hand
    # held overhead, clear of the head and any cap brim)
    "side_up_high": {"part": (15, 8, [
        "..........ss",
        "..........sk",
        "..........sk",
        "..........sk",
        "..........sk",
        "..........sk",
        "..........sk",
        "..........sk",
        ".........ssk",
        ".....sssssk.",
        "sssssssskk..",
        "skkkkkkk....",
    ]), "shoulder": (15, 19)},
    # side: raised overhead with the hand coming down (chopping)
    "side_chop_up": {"part": (15, 12, [
        "..ssss",
        ".ssk..",
        "ssk...",
        "sk....",
        "sk....",
        "sk....",
        "sk....",
        "sk....",
        "sk....",
    ]), "shoulder": (15, 19)},
    "side_chop_down": {"part": (15, 19, [
        "ss.....",
        "sk.....",
        "sk.....",
        "ssk....",
        ".sssss.",
        "..kkkkk",
    ]), "shoulder": (15, 19)},
}

# ------------------------------------------------------------------ hair
#
# Hair grids are placed relative to the head's fill anchor (dx, dy). They may
# overhang the head by a pixel for volume; the outline goes round the whole.

HAIR = {
    "short": {
        "front": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".HhHhhh..jj.",
            ".hh......jj.",
            ".h........j.",
        ]),
        "back": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".hhhhhhhhhj.",
            ".hhhhhhhhjj.",
            ".jhhhhhhjjj.",
            "..jjjjjjjj..",
        ]),
        "side": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            "HHhhhhhhhhj.",
            "Hhhhhhhhhj..",
            "Hhhhhh......",
            "Hhhh........",
            "hhhh........",
            "jjj.........",
            ".jj.........",
        ]),
    },
    "bob": {
        "front": (-1, -2, [
            "............",
            "....HHhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".HhhHhhhhhj.",
            "Hh........jJ",
            "Hh........jJ",
            "Hh........jJ",
            "Hh........jJ",
            "hh........jJ",
            "hj........jJ",
            "jj........JJ",
        ]),
        "back": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            "HHhhhhhhhhjj",
            "HhhhhhhhhhjJ",
            "HhhhjhhhhhjJ",
            "HhhhjhhhhhjJ",
            "HhhhjhhhhjjJ",
            "hhhhjhhhhjjJ",
            "hhhjjhhhjjjJ",
            "hjjjjjjjjjjJ",
            "jjjjjjjjjjJJ",
        ]),
        "side": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            "HHhhhhhhhhjj",
            "Hhhhhhhhhhjj",
            "Hhhhhhh.....",
            "Hhhhhhh.....",
            "Hhhhhh......",
            "Hhhhhh......",
            "hhhhhh......",
            "hhhhh.......",
            "jjjj........",
        ]),
    },
    "bun": {
        "front": (-1, -5, [
            ".....HHh....",
            "....HHhhj...",
            ".....hjj....",
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".hh......jj.",
            ".h........j.",
        ]),
        "back": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".hhhhhhhhhj.",
            ".hhhhhhhhjj.",
            ".jhhhhhhjjj.",
            "..jjjjjjjj..",
        ]),
        "side": (-4, -3, [
            "...............",
            "......HHhhh....",
            ".....HHhhhhhj..",
            "....HHhhhhhhhj.",
            "...HHhhhhhhhhj.",
            ".HhHhhhhhhhhj..",
            "HHhhjhhhh......",
            "Hhhjhhh........",
            ".jjjhh.........",
            "...jjj.........",
        ]),
        "bun_back": (2, -1, [
            "..HHh..",
            ".HHhhj.",
            ".Hhhjj.",
            "..jjj..",
        ]),
    },
    "perm": {
        "front": (-1, -3, [
            "...HHhHh....",
            "..HhHhhjhj..",
            ".HhhHhhhjhj.",
            "HhHhhhjhhjhj",
            "HhhhHhhhjhjJ",
            "HhhhhhhhhjhJ",
            "HhHh....jhjJ",
            "hh........jJ",
            "hh........jJ",
            "hj........jJ",
            ".j........J.",
        ]),
        "back": (-1, -3, [
            "...HHhHh....",
            "..HhHhhjhj..",
            ".HhhHhhhjhj.",
            "HhHhhhjhhjhj",
            "HhhhHhhhjhjJ",
            "HhhhhhjhhjhJ",
            "hHhhjhhhjhjJ",
            "hhjhhhjhhjjJ",
            "hjhhjhhjjhjJ",
            "jhjjhjjhjjJJ",
            ".jjjjjjjjJJ.",
        ]),
        "side": (-2, -3, [
            "....HHhHh....",
            "...HhHhhjhj..",
            "..HhhHhhhjhj.",
            ".HhHhhhjhhjhj",
            "HhhhHhhhjhhj.",
            "HhHhhhjhhhj..",
            "hHhhjhhj.....",
            "hhjhhjh......",
            "hjhhjhh......",
            "jhjjhj.......",
            ".jjjj........",
        ]),
    },
    "ponytail": {
        "front": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhjhhhhj.",
            ".Hhhhjhhhhj.",
            ".hhh....hjj.",
            ".hh......jj.",
            ".h........j.",
        ]),
        "back": (-1, -2, [
            "............",
            "...HHhhh....",
            "..HHhhhhhj..",
            ".HHhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".Hhhhhhhhhj.",
            ".hhhhhhhhhj.",
            ".hhhhhhhhjj.",
            ".jhhhhhhjjj.",
            "..jjjjjjjj..",
        ]),
        "side": (-3, -2, [
            "..............",
            ".....HHhhh....",
            "....HHhhhhhj..",
            "...HHhhhhhhhj.",
            "..HHhhhhhhhhj.",
            "..Hhhhhhhhhj..",
            ".HHhhhhh......",
            "Hhhhhh........",
            "Hhjhhh........",
            "hhj...........",
            "hj............",
            "hj............",
            "jj............",
        ]),
        "tail_back": (4, 9, [
            "hj",
            "hj",
            "hj",
            "hj",
            "jj",
            "jJ",
        ]),
    },
    "bald": {
        "front": (-1, -2, [
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            ".h........j.",
            ".h........j.",
            ".j........j.",
        ]),
        "back": (-1, -2, [
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            ".hhhhhhhhjj.",
            "............",
        ]),
        "side": (-1, -2, [
            "............",
            "............",
            "............",
            "............",
            "............",
            "............",
            ".hh.........",
            "Hhhh........",
            "hhjj........",
            ".jj.........",
        ]),
    },
    "cap": {
        "front": (-1, -3, [
            "............",
            "...AAaaa....",
            "..AAaaaaaq..",
            ".AAaaaaaaaq.",
            ".Aaaaaaaaaq.",
            ".Aaaaaaaaaq.",
            "qqqqqqqqqqqQ",
            ".h........j.",
            ".h........j.",
        ]),
        "back": (-1, -3, [
            "............",
            "...AAaaa....",
            "..AAaaaaaq..",
            ".AAaaaaaaaq.",
            ".Aaaaaaaaaq.",
            ".Aaaaaaaaaq.",
            ".aqqqqqqqqq.",
            ".hhhhhhhhhj.",
            ".hhhhhhhhjj.",
            "..jjjjjjjj..",
        ]),
        "side": (-1, -3, [
            "..............",
            "...AAaaa......",
            "..AAaaaaaq....",
            ".AAaaaaaaaq...",
            ".Aaaaaaaaaq...",
            ".Aaaaaaaaaaqqq",
            ".aqqqqqqqqqqqQ",
            "Hhhh..........",
            "hhjj..........",
            ".jj...........",
        ]),
    },
}
HAIR["grey"] = HAIR["short"]

# ------------------------------------------------------------------ clothing overlays (accent ramp)

COLLAR = {
    "front": (12, 17, [
        ".Aa....aq.",
        "..Aa..aq..",
    ]),
    "back": (13, 17, ["AaaaaQ"]),
    "side": (14, 17, ["Aaq"]),
}

APRON = {
    # a square bib, the waist tied across, the skirt a little wider below
    "front": (11, 20, [
        "..AAaaaq..",
        "..Aaaaaq..",
        "..Aaaaaq..",
        "..Aaaaaq..",
        "..Aaaaaq..",
        ".Aaaaaaaq.",
        ".Aaaaaaaq.",
        ".Aaaaaaqq.",
        ".Aaaaaaqq.",
        ".Aaaaaqqq.",
        ".aqqqqqqQ.",
    ]),
    "side": (18, 20, [
        "aq",
        "aq",
        "Aq",
        "Aq",
        "Aq",
        "Aq",
        "Aq",
        "Aq",
        "Aq",
        "aQ",
        "qQ",
    ]),
}

# the apron's strings, drawn without an outline so they stay one pixel: the
# neck strap up from the bib's corners, the waist tie across (front) and
# knotted at the back (side)
APRON_STRAPS = {
    "front": (11, 18, [
        "...q..q...",
        "..q....q..",
        "..........",
        "..........",
        "..........",
        "..........",
        "qq......qq",
    ]),
    "side": (11, 18, [
        ".....q..",
        "......q.",
        ".......q",
        "........",
        "........",
        "........",
        "qqqqqqq.",
        "q.......",
    ]),
}

COAT = {
    # an open white coat over the shirt (the dentist)
    "front_l": (11, 18, ["AA.", "AAa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaa", "Aaq", "Aaq", "aqq"]),
    "front_r": (18, 18, [".qq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqq", "aqQ", "aqQ", "qQQ"]),
    "back": (11, 18, [
        ".AAaaaaq..",
        "AAaaaaaaqq",
        "Aaaaaaaaqq",
        "Aaaaaaaaqq",
        "Aaaaaaaaqq",
        "Aaaaaaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaaqq",
        "Aaaaqaaqqq",
        "aqqqqqqqqQ",
    ]),
    "side": (12, 18, [
        ".AAaaq..",
        "AAaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaaqq.",
        "Aaaaqqq.",
        "Aaaaqqq.",
        "aqqqqqQ.",
    ]),
}

BELT = {
    "front": (11, 27, ["QQQQaQQQQQ"]),
    "back": (11, 27, ["QQQQQQQQQQ"]),
    "side": (12, 27, ["QQQQQQQQ"]),
}

SKIRT = {
    "front": (10, 29, [
        ".BBbbbbbnn..",
        ".Bbbbbbbbn..",
        "BBbbbbbbbnn.",
        "Bbbbbbbbbbn.",
        "Bbbbbbbbbnnn",
        "bbnbbnbbnnnN",
    ]),
    "back": (10, 29, [
        ".BBbbbbbnn..",
        ".Bbbbbbbbn..",
        "BBbbbbbbbnn.",
        "Bbbbbbbbbbn.",
        "Bbbbbbbbbnnn",
        "bbnbbnbbnnnN",
    ]),
    "side": (12, 29, [
        ".BBbbbn.",
        ".Bbbbbn.",
        "BBbbbbnn",
        "Bbbbbbbn",
        "Bbbbbbnn",
        "bbnbbnnN",
    ]),
}

# ============================================================================= CHILD
#
#   head  16..26   neck 27   torso 28..35   pelvis 37   legs 38..42   shoes 43..45

CHILD_HEAD_OFFSET = (0, 11)

CHILD_TORSO = {
    "front": (12, 28, [
        ".TTkktu.",
        "TTttttuu",
        "Tttttttu",
        "Tttttttu",
        ".Ttttttu",
        ".Tttttu.",
        "Ttttttuu",
        "tuuuuuuU",
    ]),
    "back": (12, 28, [
        ".TTtttu.",
        "TTttttuu",
        "Tttttttu",
        "Tttuuttu",
        ".Ttttttu",
        ".Tttttu.",
        "Ttttttuu",
        "tuuuuuuU",
    ]),
    "side": (12, 28, [
        ".TTttu.",
        "TTttttu",
        "Tttttuu",
        "Tttttuu",
        ".Ttttu.",
        ".Ttttu.",
        "Tttttuu",
        "tuuuuuU",
    ]),
}
CHILD_NECK = {"front": (15, 27, ["kk"]), "back": (15, 27, ["kk"]), "side": (15, 27, ["kk"])}

CHILD_LEGS_FRONT_IDLE = (12, 37, [
    "BBbbbbnn",
    "Bbbnbbbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "Ffg..Ffg",
    "fgg..fgg",
    "ggG..ggG",
])
# a child sitting low, on a plank across two bricks: thighs forward, shins down
CHILD_LEGS_SEATED = {
    "front": (12, 40, ["BBbbbbnn", "Bbbnbbbn", "Bbn..Bbn", "Bbn..Bbn", "Ffg..Ffg", "ggG..ggG"]),
    "back": (12, 40, ["BBbbbbnn", "Bbbnbbbn", "bbn..bbn"]),
    "side": (12, 40, ["BBbbbbn.", "bbnnBbn.", "....Bbn.", "....Bbn.", "....FfgG", "....ggG."]),
}

CHILD_LEGS_BACK_IDLE = (12, 37, [
    "BBbbbbnn",
    "Bbbnbbbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "Bbn..Bbn",
    "fgg..fgg",
    "fgg..fgg",
    "ggG..ggG",
])


def child_front_lift(legs, side: str, lift: int):
    x, y, rows = legs
    cols = (0, 3) if side == "left" else (5, 8)
    out = [list(r) for r in rows]
    leg = [r[cols[0]:cols[1]] for r in rows]
    new_leg = leg[:2] + leg[2:6][:4 - lift] + leg[6:] + ["..."] * lift
    for i, r in enumerate(out):
        r[cols[0]:cols[1]] = list(new_leg[i])
    return (x, y, ["".join(r) for r in out])


CHILD_SIDE_WALK = [
    {   # contact
        "a": (15, 37, [
            "Bbn....",
            "Bbn....",
            ".Bbn...",
            ".Bbn...",
            "..Bbn..",
            "..bbn..",
            "..FfggG",
            "..ffgg.",
            "...ggG.",
        ]),
        "b": (11, 37, [
            "...Bbn",
            "...Bbn",
            "..Bbn.",
            "..Bbn.",
            ".Bbn..",
            ".bbn..",
            "Ffgg..",
            "ffgG..",
            ".ggG..",
        ]),
        "bob": 0,
    },
    {   # down: the trailing heel peels up
        "a": (14, 37, [
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".bbn..",
            ".FfggG",
            ".ffgg.",
            "..ggG.",
        ]),
        "b": (11, 37, [
            "...Bbn",
            "...Bbn",
            "..Bbn.",
            "..Bbn.",
            ".Bbn..",
            ".bbn..",
            "Ffgg..",
            "ffgG..",
        ]),
        "bob": 1,
    },
    {   # passing: knee forward, foot tucked
        "a": (14, 37, [
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".Bbn..",
            ".bbn..",
            ".FfggG",
            ".ffgg.",
            "..ggG.",
        ]),
        "b": (13, 37, [
            "Bbn...",
            ".Bbn..",
            ".Bbbn.",
            ".Bbn..",
            ".bbn..",
            ".Ffgg.",
            ".ffgG.",
        ]),
        "bob": 0,
    },
]
CHILD_SIDE_IDLE = {
    "a": (14, 37, [
        ".Bbn..",
        ".Bbn..",
        ".Bbn..",
        ".Bbn..",
        ".Bbn..",
        ".bbn..",
        ".FfggG",
        ".ffgg.",
        "..ggG.",
    ]),
    "b": (12, 37, [
        ".Bbn...",
        ".Bbn...",
        ".Bbn...",
        ".Bbn...",
        ".Bbn...",
        ".bbn...",
        ".Ffgg..",
        ".ffgg..",
        "..ggG..",
    ]),
}
CHILD_PELVIS = {"front": (12, 37, ["BBbbbbnn"]), "back": (12, 37, ["BBbbbbnn"]), "side": (12, 37, ["BBbbbnn"])}

CHILD_ARMS = {
    "front_l": {"part": (10, 29, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (10, 29)},
    "front_r": {"part": (20, 29, ["sk", "sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (21, 29)},
    "front_l_fwd": {"part": (10, 29, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (10, 29)},
    "front_r_fwd": {"part": (20, 29, ["sk", "sk", "sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (21, 29)},
    "front_l_back": {"part": (10, 29, ["SS", "Ss", "Ss", "Ss", "Ss", "Sk", "sk"]), "shoulder": (10, 29)},
    "front_r_back": {"part": (20, 29, ["sk", "sk", "sk", "sk", "sk", "kk", "kK"]), "shoulder": (21, 29)},
    "front_l_hold": {"part": (10, 29, ["SS...", "Ss...", "Ss...", "SsSs.", ".Sssk"]), "shoulder": (10, 29)},
    "front_r_hold": {"part": (17, 29, ["...sk", "...sk", "...sk", ".sssk", "ssskK"]), "shoulder": (21, 29)},
    "front_l_up": {"part": (10, 19, ["SS", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss", "Ss"]), "shoulder": (10, 29)},
    "front_r_up": {"part": (20, 19, ["ss", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk", "sk"]), "shoulder": (21, 29)},
    "front_r_point": {"part": (20, 20, [
        "...ss",
        "..ssk",
        "..sk.",
        ".ssk.",
        ".sk..",
        "ssk..",
        "sk...",
        "sk...",
        "sk...",
    ]), "shoulder": (21, 29)},
    "side_back2": {"part": (12, 29, ["..ss", "..sk", ".ssk", ".sk.", "ssk.", "sk..", "kk.."]), "shoulder": (15, 29)},
    "side_back1": {"part": (14, 29, [".ss", ".sk", ".sk", "ssk", "sk.", "sk.", "kk."]), "shoulder": (15, 29)},
    "side_mid": {"part": (15, 29, ["ss", "sk", "sk", "sk", "sk", "sk", "sk", "kk"]), "shoulder": (15, 29)},
    "side_fwd1": {"part": (15, 29, ["ss.", "sk.", "sk.", "ssk", ".sk", ".sk", ".kk"]), "shoulder": (15, 29)},
    "side_fwd2": {"part": (15, 29, ["ss...", "sk...", "ssk..", ".ssk.", "..ssk", "...sk", "...kk"]), "shoulder": (15, 29)},
    "side_hold": {"part": (15, 29, ["ss....", "sk....", "sk....", "ssssss", ".kkkkk"]), "shoulder": (15, 29)},
    "side_up": {"part": (15, 19, [
        "...ss",
        "...sk",
        "..ssk",
        "..sk.",
        ".ssk.",
        ".sk..",
        "ssk..",
        "sk...",
        "sk...",
        "sk...",
        "sk...",
    ]), "shoulder": (15, 29)},
}
