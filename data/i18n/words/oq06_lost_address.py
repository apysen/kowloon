"""OQ06, The Lost Address (Chapter 5): Mrs. Leung's sister, Mr. Kwok's bundle."""

N = ""

SCENES = [
    ("c5_leung", [
        ("leung", "You're the one with the camera. From the old man's.", "你就係拎住部相機嗰個。老人家屋企嗰個。"),
        ("mei", "That's me.", "係我。"),
        ("leung", "My sister's moved to Lok Fu. I don't know which block.", "我家姐搬咗去樂富。我唔知係邊座。"),
        ("mei", "Didn't she tell you?", "佢冇同你講咩？"),
        ("leung", "She told Mrs. Wong. Mrs. Wong was going to tell me.", "佢同咗黃婆婆講。黃婆婆話會話我知。"),
        ("mei", "Mrs. Wong's gone.", "黃婆婆走咗喇。"),
        ("leung", "I noticed.", "我知。"),
        ("leung", "Kwok will have it. Everybody left their new address with Kwok.", "郭伯會有。個個都將新地址留低畀郭伯。"),
    ]),
    ("c5_leung_wait", [
        ("leung", "Kwok. The stall. Everybody's address.", "郭伯。士多。個個嘅地址。"),
    ]),
    ("c5_kwok_note", [
        ("mei", "Mrs. Leung needs her sister's address.", "梁太要佢家姐嘅地址。"),
        ("kwok", "It'll be in the bundle. On the floor, behind the counter.", "應該喺嗰紮度。喺櫃枱後面地下。"),
        ("mei", "The shutter's down.", "鐵閘拉咗落嚟。"),
        ("kwok", "Half down. The key's in a box. Which box, I couldn't tell you.", "拉咗一半。鎖匙喺箱入面。邊個箱，我都講唔到。"),
        ("kwok", "You're small. Go round the front and look under.", "你細粒。行去前面，由下面望入去。"),
    ]),
    ("c5_kwok_packing", [
        ("kwok", "Thirty-one years of other people's post. Most of it I never read.", "三十一年替人收信。大部分我都冇睇過。"),
    ]),
    ("c5_under_shutter", [
        (N, "Mei gets down on the floor and reaches under the shutter.", "阿美伏在地上，把手伸進鐵閘下面。"),
        (N, "A note has slipped out of the bundle. In Mrs. Wong's hand: LEUNG'S SISTER. LOK FU, BLOCK 5, 1210.",
         "有一張字條從那紮信裡滑了出來。是黃婆婆的字：「梁太家姐：樂富，五座，一二一零。」", "noteTaken"),
    ]),
    ("c5_leung_done", [
        ("mei", "Lok Fu. Block Five. Twelve-ten.", "樂富。五座。一二一零。"),
        ("leung", "Five. I'd have guessed seven.", "五座。我仲以為係七座。"),
        ("leung", "This is Mrs. Wong's writing.", "呢張係黃婆婆嘅字。"),
        ("mei", "She left it with Mr. Kwok.", "佢留低畀郭伯。"),
        ("leung", "Of course she did.", "梗係啦。"),
    ]),
    ("c5_leung_after", [
        ("leung", "Block Five. I'll keep it on my hand until I find a pen.", "五座。我寫喺手度先，等我搵到枝筆。"),
    ]),
]

STRINGS = [
    ("speaker.leung", "Mrs. Leung", "梁太"),
    ("verb.reach", "Reach under", "伸手入去"),
    ("notice.c5_note_seen", "Under the shutter: Mr. Kwok's bundle of addresses, on the floor.", "鐵閘下面：郭伯那紮地址，放在地上。"),
    ("notice.c5_leung_note", "A note in Mrs. Wong's hand, for Mrs. Leung.", "黃婆婆寫給梁太的字條。"),
    ("c5.need.leung", "Mrs. Leung's sister: in the bundle behind Mr. Kwok's half-shut stall. Look from its front.",
     "梁太的家姐：在郭伯半關的士多裡那紮字條中。從正面看。"),
    ("c5.need.leung_give", "The note, to Mrs. Leung.", "字條：交給梁太。"),
]

REPLACE = [
    ("env.c5_stall", "Mr. Kwok's shutter, pulled halfway down in the middle of the day.", "郭伯的鐵閘，大白天拉下了一半。"),
]
