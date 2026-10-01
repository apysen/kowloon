"""Chapter 7, The Way Out. 0 days until we leave."""

N = ""

SCENES = [
    ("c7_open", [
        ("mum", "Have you seen Grandpa?", "你見唔見到公公？"),
        ("mei", "No.", "冇。"),
        ("mum", "He was supposed to be downstairs.", "佢應該喺樓下㗎。"),
        ("mei", "I'll find him.", "我去搵佢。"),
        ("mum", "Mei.", "阿美。"),
        (N, "Mei stops.", "阿美停了下來。"),
        ("mum", "Don't take all day.", "唔好搞成日。"),
        ("mei", "We only have one.", "我哋得返一日。"),
    ]),
    ("c7_mum_wait", [("mum", "The truck won't wait for him. Or for you.", "架車唔會等佢。亦都唔會等你。")]),
    ("c7_yamen", [
        ("mei", "Mum's looking for you.", "阿媽搵緊你。"),
        ("grandfather", "I know.", "我知。"),
        ("mei", "The truck's here.", "架車嚟咗。"),
        ("grandfather", "I know.", "我知。"),
        (N, "Mei sits down beside him.", "阿美在他身邊坐下。"),
    ]),
    ("c7_yamen_2", [
        ("mei", "I don't want to go.", "我唔想走。"),
        (N, "Grandfather doesn't answer straight away.", "公公沒有馬上回答。"),
        ("grandfather", "Neither do I.", "我都唔想。"),
    ]),
    ("c7_wrong_way", [
        ("mei", "Not that way.", "唔係嗰邊。"),
        ("grandfather", "I know.", "我知。"),
        ("mei", "You're going the wrong way.", "你行錯咗。"),
        ("grandfather", "I was checking.", "我試下咋。"),
        ("mei", "Checking what?", "試咩？"),
        ("grandfather", "If you knew.", "試下你識唔識。"),
    ]),
    ("c7_kwok", [
        ("grandfather", "After Kwok.", "過咗郭伯就轉。"),
        ("mei", "Where Kwok used to be.", "以前郭伯喺嗰度。"),
    ]),
    ("c7_home", [
        ("mum", "There you are.", "終於返嚟喇。"),
        ("mum", "The truck's on Lung Chun Road, at the yamen end. Take the case.", "架車喺龍津道，衙門嗰頭。攞埋個喼。"),
        (N, "Mei takes the suitcase. Mum takes the box. Nobody looks round the room.", "阿美拿起行李箱。媽媽拿起紙箱。沒有人回頭看這個房間。"),
    ]),
    ("c7_try_angle", [("grandfather", "Try another angle.", "試下第二個角度。")]),
    ("c7_doesnt_fit", [
        ("mei", "It doesn't fit.", "影唔晒。"),
        ("grandfather", "What doesn't?", "咩影唔晒？"),
        ("mei", "All of it.", "全部。"),
        (N, "Grandfather looks.", "公公望了一眼。"),
        ("grandfather", "Of course not.", "梗係影唔晒啦。"),
    ]),
    ("c7_give_me", [
        ("grandfather", "Give me that.", "畀我。"),
        ("mei", "Why?", "做咩？"),
        ("grandfather", "Give it.", "畀我。"),
        (N, "She hands him the camera.", "她把相機遞給他。"),
        ("grandfather", "Stand there.", "企喺度。"),
        ("mei", "Why?", "做咩？"),
        ("grandfather", "You've got everyone else.", "其他人你都影晒啦。"),
    ]),
    ("c7_pipe", [(N, "The blue pipe. The paint has chipped more near the bend.", "藍色水喉。轉彎那裡的油漆又剝落了一些。")]),
    ("c7_radio_gone", [(N, "The mark on the shelf's wall where the radio sat, and the nail it hung its aerial from.", "牆上留著收音機放過的印子，還有掛天線的那口釘。")]),
]

STRINGS = [
    ("c7.card.number", "CHAPTER 7", "第七章"),
    ("c7.card.title", "THE WAY OUT", "出路"),
    ("c7.obj.find", "Find Grandfather.", "找公公。"),
    ("c7.obj.home", "Go home.", "回家。"),
    ("c7.we_left", "WE LEFT.", "我們走了。"),
    ("c7.credits.title", "WALLED CITY", "WALLED CITY"),
    ("c7.credits.thanks", "Thank you for playing.", "謝謝你玩這個遊戲。"),
    ("c7.credits.replay", "Press [R] to return to the title", "按 [R] 回到標題"),
    ("res.mei.name", "Mei", "阿美"),
    ("res.mei.note", "Knew every way home.", "每條回家的路都認得。"),
]
