"""Chapter 2's side quests: OQ01, Mr. Kwok's Back Page; OQ04, The Last Mahjong Tile."""

N = ""

SCENES = [
    # OQ01
    ("c2_kwok_page", [
        ("kwok", "Get that.", "攞返嚟。"),
        ("mei", "Yesterday's paper?", "尋日啲報紙？"),
        ("kwok", "Still mine.", "都係我嘅。"),
        ("kwok", "The wind had the back page up the stairs and out over the light well. It's lying on somebody's awning.", "陣風吹咗張底頁上樓梯，飛咗出天井。而家擱咗喺人哋個簷篷度。"),
    ]),
    ("c2_kwok_page_wait", [
        ("kwok", "The back page. It's got the crossword.", "張底頁。有填字遊戲㗎。"),
    ]),
    ("c2_page_awning", [
        (N, "The page is lying on an awning below the catwalk. Nobody could reach it there.", "報紙躺在天橋下面的一個簷篷上。沒有人夠得著。"),
    ]),
    ("c2_page_seen", [
        (N, "From the side: it isn't on the awning. It's on the little balcony under it, off the stairs by Lau's.", "從側面看：它不在簷篷上，而是在簷篷下面的小露台上，就在劉醫生那邊的樓梯旁。"),
    ]),
    ("c2_page_got", [
        (N, "The back page: the racing results, and half the crossword, done in pencil.", "報紙的底頁：賽馬結果，還有做了一半的填字遊戲，是用鉛筆寫的。"),
    ]),
    ("c2_kwok_page_back", [
        ("kwok", "You went all that way for yesterday's paper?", "你行咁遠路，就為咗張尋日嘅報紙？"),
        ("mei", "You asked me to.", "你叫我去㗎。"),
        ("kwok", "I was testing you.", "我試下你咋。"),
        ("mei", "For what?", "試咩？"),
        ("kwok", "Poor judgment.", "睇你判斷力有幾差。"),
    ]),
    ("c2_kwok_after", [
        ("kwok", "Half the crossword was done. Not by me.", "填字做咗一半。唔係我做嘅。"),
    ]),
    # OQ04
    ("c2_tile_lost", [
        ("tsang", "Who's got the white dragon?", "邊個攞咗隻白板？"),
        ("yip", "Nobody's got it. It went down the crack.", "冇人攞。跌咗落條罅度。"),
        ("tsang", "Somebody's sitting on it.", "一定有人坐住佢。"),
        (N, "Everyone looks at everyone.", "大家互相望來望去。"),
        ("tsang", "Mei. You've got young arms.", "阿美，你手仔幼。"),
    ]),
    ("c2_tile_wait", [
        ("tsang", "We can't play with a hundred and forty-three.", "一百四十三隻牌點打呀。"),
    ]),
    ("c2_tile_crack", [
        (N, "Between the floor and the wall, a crack a finger wide. Somewhere down it, a tile. Nobody's arm is that thin.",
         "地板和牆之間有一條一隻手指闊的罅。牌就在下面某處。沒有人的手那麼細。"),
    ]),
    ("c2_tile_seen", [
        (N, "From the side, behind the crates: where the crack comes out at the foot of the wall, a white tile.", "從側面看，在木箱後面：那條罅在牆腳露出來的地方，有一隻白色的牌。"),
    ]),
    ("c2_tile_got", [
        (N, "Mei reaches in behind the crates. The white dragon, grey with dust.", "阿美把手伸到木箱後面。是白板，沾滿了灰。"),
    ]),
    ("c2_tile_back", [
        ("mei", "White dragon.", "白板。"),
        ("tsang", "Where was it?", "喺邊度搵到？"),
        ("mei", "In the lane.", "喺後巷。"),
        ("tsang", "The lane.", "後巷。"),
        ("yip", "I said it went down the crack.", "我都話咗佢跌咗落條罅。"),
        ("tsang", "You said the crack. You didn't say the lane.", "你話條罅。你冇話後巷。"),
        (N, "They count the tiles three times. All there.", "他們把牌數了三次。一隻都沒少。"),
    ]),
    ("c2_tile_after", [
        ("tsang", "All hundred and forty-four. Don't touch anything.", "一百四十四隻齊晒。咩都唔好掂。"),
    ]),
]

STRINGS = [
    ("c2.need.page", "Mr. Kwok's back page: somewhere over the light well.", "郭伯的報紙底頁：在天井上方某處。"),
    ("c2.need.page_seen", "Mr. Kwok's back page: on the little balcony under the awning. There's a door halfway up the stairs by Lau's.",
     "郭伯的報紙底頁：在簷篷下的小露台上。劉醫生那邊的樓梯中間有道門。"),
    ("c2.need.page_back", "Mr. Kwok's back page: take it to him.", "郭伯的報紙底頁：拿去給他。"),
    ("c2.need.tile", "The white dragon: down the crack at the foot of the alcove's wall. Where does the crack come out?",
     "白板：跌進了麻雀角落牆腳的罅裡。那條罅通到哪裡？"),
    ("c2.need.tile_back", "The white dragon: back to the mahjong table.", "白板：還給麻雀枱。"),
]
