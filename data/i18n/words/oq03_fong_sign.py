"""OQ03, Auntie Fong's Sign (Chapter 4): her husband's board comes down."""

N = ""

SCENES = [
    ("c4_fong", [
        ("fong", "You're Mrs. Wong's messenger. The one with the camera.", "你係黃婆婆嘅信差。拎相機嗰個。"),
        ("mei", "I'm not anybody's messenger.", "我唔係邊個嘅信差。"),
        ("fong", "Everybody's somebody's messenger this month.", "呢個月個個都係人哋嘅信差。"),
        ("fong", "My old shop's sign is still up, over the slot behind the fish-ball place. Fong's Herbal Tea.", "我舊舖個招牌仲掛喺度，喺魚蛋工場後面條罅上面。方記涼茶。"),
        ("fong", "I'm not leaving it for the demolition men. My husband painted it.", "我唔會留畀啲拆樓佬。係我先生親手寫嘅。"),
        ("fong", "Two bolts at each end. Undo them and it comes down on its cord.", "兩頭各有兩粒螺絲。扭鬆佢，個招牌就會跟條繩吊落嚟。"),
        ("mei", "How do I get up there?", "我點上去？"),
        ("fong", "The way everybody gets anywhere. Look around.", "同其他人一樣。周圍望下。"),
    ]),
    ("c4_fong_wait", [
        ("fong", "Both ends. My husband believed in bolts.", "兩頭都要。我先生好信螺絲。"),
    ]),
    ("c4_fong_bolt_first", [
        (N, "Mei undoes the two bolts at this end. The board sags a little on the other post.", "阿美扭鬆了這一頭的兩粒螺絲。招牌在另一條柱上微微垂下。"),
    ]),
    ("c4_fong_bolt_last", [
        (N, "Mei undoes the last two bolts. The board swings down on its cord and comes to rest in the lane below.",
         "阿美扭鬆最後兩粒螺絲。招牌順著繩子擺下去，停在下面的後巷。"),
    ]),
    ("c4_fong_slot", [
        (N, "From the side: the balcony isn't joined to the roof at all. There's a drop between them, all the way down to the lane, and the plank has gone back to the Chans.",
         "從側面看：露台和天台根本沒有連著。中間是一道縫，一直落到後巷，木板也已經還給陳家了。"),
    ]),
    ("c4_ladder_seen", [
        (N, "Looking back from the north: a steel ladder fixed to the wall, all the way up to the neighbours' balcony.", "從北面回頭看：一條鐵梯釘在牆上，一直通上鄰居的露台。"),
    ]),
    ("c4_fong_done", [
        ("mei", "It's down. It's in the lane.", "拆咗落嚟喇。喺後巷。"),
        ("fong", "Was it heavy?", "重唔重？"),
        ("mei", "It came down on its own.", "佢自己落嚟嘅。"),
        ("fong", "My husband said it would. Nobody believed him.", "我先生話過佢會。冇人信佢。"),
        ("fong", "Leave the posts. Let them wonder what used to hang there.", "啲柱留低。等佢哋估下以前掛過咩。"),
    ]),
    ("c4_fong_after", [
        ("fong", "Forty years, that sign. Now it's leaning in a lane. Like me.", "個招牌掛咗四十年。而家挨喺後巷。同我一樣。"),
    ]),
]

STRINGS = [
    ("speaker.fong", "Auntie Fong", "方嬸"),
    ("c4.need.fong", "Auntie Fong's sign: over the slot behind Chiu's workshop. Two bolts at the roof end, two at the balcony end.",
     "方嬸的招牌：在趙記工場後面那道縫上。天台那頭兩粒螺絲，露台那頭兩粒。"),
    ("c4.need.fong_balcony", "Auntie Fong's sign: the balcony end. The balcony isn't joined to the roof; find another way up from the lane.",
     "方嬸的招牌：露台那一頭。露台和天台不相連；從後巷找路上去。"),
    ("c4.need.fong_tell", "Auntie Fong's sign: it's down. Tell her.", "方嬸的招牌：拆下來了。告訴她。"),
    ("env.c5_fong_posts", "Two steel posts over the slot, with nothing between them.", "縫上兩條鐵柱，中間甚麼都沒有。"),
]
