"""OQ02, Mrs. Cheung's Fan (Chapter 4): the fan stops; it's the plug."""

N = ""

SCENES = [
    ("c4_fan_stops", [
        (N, "Mrs. Cheung's fan clicks, slows, and stops.", "張婆婆的風扇「嗒」一聲，慢慢停了。"),
        ("cheung", "Again.", "又嚟。"),
        ("cheung", "Mr. Ho mended it in the spring. He'll say it isn't the fan.", "何師傅春天先整過。佢一定話唔關風扇事。"),
    ]),
    ("c4_cheung_fan_wait", [
        ("cheung", "Still stopped. It's hot for September.", "仲係停咗。九月都咁熱。"),
    ]),
    ("c4_ho_fan", [
        ("mei", "Mrs. Cheung's fan has stopped.", "張婆婆把風扇停咗。"),
        ("ho", "The one by her table? I rewound that motor myself.", "佢枱邊嗰把？個摩打我親手重繞過。"),
        ("ho", "The motor's fine. It'll be the cable. They run it through half the building.", "摩打冇問題。應該係條線。佢哋條拖板線穿過半座樓。"),
        ("ho", "Follow the cable.", "跟住條線行。"),
    ]),
    ("c4_cords", [
        (N, "Two cords run side by side from the fan. Here they part: one goes up the veranda wall into the hall, to a radio. The other goes under the storage room's door.",
         "兩條電線從風扇並排拖過來。到這裡分開了：一條沿走廊牆爬上去，進了大堂，接著一部收音機。另一條鑽進了貨倉門底。"),
    ]),
    ("c4_plug", [
        (N, "Behind the shelves, the plug has been knocked out of the socket. Moving boxes, probably.", "層架後面，插頭給碰甩了出來。大概是搬箱時碰到的。"),
        (N, "Mei pushes it back in. Out in the courtyard, the fan starts to turn.", "阿美把它插回去。院子裡的風扇又開始轉了。", "fanOn"),
    ]),
    ("c4_fan_back", [
        ("cheung", "There. Not the fan.", "係咪。唔關風扇事。"),
        ("mei", "It was the plug.", "係插蘇。"),
        ("cheung", "It's always the plug. Nobody ever looks at the plug.", "次次都係插蘇。從來冇人睇插蘇。"),
    ]),
]

STRINGS = [
    ("verb.plug_in", "Plug it in", "插返"),
    ("notice.c4_plug_seen", "From this side: a plug lying on the floor behind the shelves.", "從這邊看：層架後面地上有個插頭。"),
    ("c4.need.fan", "Mrs. Cheung's fan: ask Mr. Ho, in the hall.", "張婆婆的風扇：問走廊的何師傅。"),
    ("c4.need.fan_cord", "Mrs. Cheung's fan: follow its cable from her table. Turn the view where the cords part.",
     "張婆婆的風扇：由她的枱開始跟住電線走。在電線分開的地方轉換視角。"),
    ("c4.need.fan_plug", "Mrs. Cheung's fan: its cable goes into the storage room. Look behind the shelves from the other side.",
     "張婆婆的風扇：電線進了貨倉。從另一邊看層架後面。"),
    ("c4.need.fan_tell", "Mrs. Cheung's fan: it's going again. Tell her.", "張婆婆的風扇：又轉起來了。告訴她。"),
]
