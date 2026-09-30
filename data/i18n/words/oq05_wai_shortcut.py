"""OQ05, Wai's Shortcut (Chapter 3): Chiu's roof to the Chans' in thirty seconds."""

N = ""

SCENES = [
    ("c3_wai_shortcut", [
        ("wai", "You go up to Chiu's roof by the ladder, right?", "你上趙記天台係爬梯嘅，係咪？"),
        ("mei", "There's only the ladder.", "淨係得把梯。"),
        ("wai", "There's a way from Chiu's roof to ours. Thirty seconds.", "趙記天台去我哋天台有條路。三十秒。"),
        ("mei", "Show me.", "帶我去睇下。"),
        ("wai", "Find it. I'll be on our roof.", "自己搵。我喺我哋天台等你。"),
    ]),
    ("c3_wai_waiting", [
        ("wai", "That's the long way.", "呢條係遠路。"),
    ]),
    ("c3_short_stair", [
        (N, "From the side: behind Chiu's back parapet, three steel steps down onto the next roof.", "從側面看：趙記天台後面的矮牆後，有三級鐵梯落去隔籬的天台。"),
    ]),
    ("c3_short_ladder", [
        (N, "Looking back from the north, behind the washing: a ladder up to a balcony on the back of Mei's building.", "從北面回頭看，在晾著的衣服後面：一條梯子通上阿美那座大廈後面的一個露台。"),
    ]),
    ("c3_short_bridge", [
        (N, "From the side: two planks laid from the balcony's rail up onto the roof.", "從側面看：兩塊木板從露台欄杆搭上天台。"),
    ]),
    ("c3_wai_race", [
        ("wai", "Told you.", "我都話咗。"),
        ("mei", "That's not a route. That's a list of bad ideas.", "呢啲唔係路。係一串壞主意。"),
        ("wai", "It's faster.", "快啲囉。"),
        ("mei", "Than what?", "快過咩？"),
        ("wai", "Than you.", "快過你。"),
    ]),
    ("c3_wai_race_after", [
        ("wai", "Don't tell Mum about the planks.", "唔好同阿媽講嗰兩塊木板。"),
    ]),
]

STRINGS = [
    ("c3.need.wai", "Wai's shortcut: from Chiu's roof to the Chans' roof, somehow.", "阿偉的捷徑：由趙記天台去陳家天台，不知怎樣走。"),
    ("verb.cross", "Cross", "過去"),
    ("env.c5_wai_bridge", "Where Wai's planks went up to the roof: two nail holes in the balcony rail, and a drop.", "阿偉的木板以前搭上天台的地方：露台欄杆上兩個釘孔，下面一道空。"),
]
