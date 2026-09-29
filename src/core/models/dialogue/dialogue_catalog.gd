class_name DialogueCatalog
extends RefCounted

## Every line in the slice, keyed by conversation.
##
## An empty speaker is narration. `event` fires when the line appears (the
## camera changing hands, the plane coming over the roofs).

const LINES := {
	"grandfather_intro": [
		{"speaker": "Grandfather", "text": "Mei. Take this to Mrs. Wong."},
		{"speaker": "Mei", "text": "Again?"},
		{"speaker": "Grandfather", "text": "She won't come down for it herself. Stubborn woman."},
		{"speaker": "Grandfather", "text": "And take this."},
		{"speaker": "", "text": "He puts his old instant camera in your hands.", "event": "receiveCamera"},
		{"speaker": "Mei", "text": "Your camera? What for?"},
		{"speaker": "Grandfather", "text": "You'll forget what things looked like."},
		{"speaker": "Grandfather", "text": "Follow the blue pipe. When you reach Lau's place, go up."},
	],
	"grandfather_idle": [
		{"speaker": "Grandfather", "text": "Blue pipe. Lau's. Up. Go on."},
	],
	"grandfather_late": [
		{"speaker": "Grandfather", "text": "Did she take it?"},
		{"speaker": "Mei", "text": "Not yet."},
		{"speaker": "Grandfather", "text": "Then why are you standing here?"},
	],
	"grandfather_return": [
		{"speaker": "Mei", "text": "I gave it to her."},
		{"speaker": "Grandfather", "text": "Good."},
		{"speaker": "Mei", "text": "She said to tell you she's not leaving before you do."},
		{"speaker": "Grandfather", "text": "Did she."},
		{"speaker": "Mei", "text": "What does that mean?"},
		{"speaker": "", "text": "He turns the radio up a little."},
		{"speaker": "Grandfather", "text": "Your mother saved you some rice."},
	],
	"grandfather_end": [
		{"speaker": "Grandfather", "text": "Eat. It's getting cold."},
	],
	"boxes_end": [
		{"speaker": "", "text": "Cardboard boxes, taped shut. Your mother's handwriting on the sides."},
		{"speaker": "", "text": "KITCHEN.  WINTER CLOTHES.  RADIO."},
		{"speaker": "Mei", "text": "They were here this morning."},
	],
	"lau_intro": [
		{"speaker": "Mr. Lau", "text": "Mei! Mind the tray, those are clean."},
		{"speaker": "Mei", "text": "You're packing already?"},
		{"speaker": "Mr. Lau", "text": "Your mother hasn't started?"},
		{"speaker": "Mei", "text": "She says she has."},
		{"speaker": "Mr. Lau", "text": "Then she hasn't."},
		{"speaker": "Mr. Lau", "text": "Apparently I'm getting a real office after this. With windows."},
		{"speaker": "Mr. Lau", "text": "Thirty-one years in this room and I've never once seen the weather."},
		{"speaker": "Mr. Lau", "text": "Is that your grandfather's camera?"},
		{"speaker": "Mr. Lau", "text": "Take one of me. With the old chair, before they haul it off."},
		{"speaker": "Mr. Lau", "text": "Go on, before I change my mind."},
	],
	"lau_waiting": [
		{"speaker": "Mr. Lau", "text": "Well? I'm not getting any younger."},
	],
	"lau_after_photo": [
		{"speaker": "Mr. Lau", "text": "Hah. Don't show anyone."},
		{"speaker": "Mr. Lau", "text": "Wong's upstairs from here, isn't she? The stairs are through the back."},
	],
	"lau_idle": [
		{"speaker": "Mr. Lau", "text": "Go on. Mrs. Wong won't wait forever."},
	],
	"lau_return": [
		{"speaker": "Mr. Lau", "text": "Back already? Tell your mother to start packing."},
	],
	"fabric_first": [
		{"speaker": "", "text": "Wet fabric blocks the walkway."},
		{"speaker": "", "text": "It's still dripping. You can't get past without soaking it."},
	],
	"fabric_again": [
		{"speaker": "", "text": "Someone's washing. Still wet."},
	],
	"chan_early": [
		{"speaker": "Mrs. Chan", "text": "Mind the washing on the catwalk, Mei."},
	],
	"chan_quest": [
		{"speaker": "Mei", "text": "Mrs. Chan, can you move the washing? I need to get to Mrs. Wong's."},
		{"speaker": "Mrs. Chan", "text": "And let them mildew?"},
		{"speaker": "Mrs. Chan", "text": "My boy was supposed to carry them upstairs to dry. I haven't seen him all afternoon."},
		{"speaker": "Mrs. Chan", "text": "He's probably gone up to the roof again. With that pigeon man."},
		{"speaker": "Mei", "text": "How do I get up there?"},
		{"speaker": "Mrs. Chan", "text": "Not by the stairs. That roof door's been stuck for years. Only my boy knows the trick to it."},
		{"speaker": "Mrs. Chan", "text": "He goes up the shaft behind my kitchen. Like a monkey. Don't tell me about it."},
	],
	"chan_waiting": [
		{"speaker": "Mrs. Chan", "text": "If you find him, tell him his mother has a wooden spoon."},
	],
	"chan_told": [
		{"speaker": "Mei", "text": "Your son's up on the roof, helping Mr. Ng."},
		{"speaker": "Mrs. Chan", "text": "Of course he is. Tell him his mother has a wooden spoon."},
	],
	"chan_coming": [
		{"speaker": "Mei", "text": "Your son's coming for the washing."},
		{"speaker": "Mrs. Chan", "text": "I'll believe it when I see it."},
	],
	"chan_after": [
		{"speaker": "Mrs. Chan", "text": "He finally came for them. Go on, it's clear."},
	],
	"shaft_look": [
		{"speaker": "", "text": "The airshaft. A rusted ladder climbs the west wall all the way to the roof."},
		{"speaker": "", "text": "Its bottom rungs have rusted clean away. The first one is out of reach."},
	],
	"shaft_look_found": [
		{"speaker": "", "text": "The ladder's bottom rungs are gone."},
		{"speaker": "", "text": "That old crate behind the fridge would get you up to them."},
	],
	"shaft_climb": [
		{"speaker": "", "text": "Onto the crate, up to the first rung."},
		{"speaker": "", "text": "Then straight up, the way Mrs. Chan's boy must go."},
	],
	"shaft_down_unknown": [
		{"speaker": "", "text": "A long drop down the airshaft. You can't see a way down from here."},
	],
	"roofdoor_latched": [
		{"speaker": "", "text": "The roof door is swollen stuck in its frame. It won't budge."},
	],
	"roofdoor_top_stuck": [
		{"speaker": "", "text": "The stairwell door is swollen stuck in its frame. It won't budge."},
	],
	"son_found": [
		{"speaker": "Chan's son", "text": "Mei? What are you doing up here?"},
		{"speaker": "Mei", "text": "Your mother's looking for you. The washing."},
		{"speaker": "Chan's son", "text": "The washing! I was supposed to bring it up hours ago."},
		{"speaker": "Chan's son", "text": "I can't yet. Mr. Ng needs me. One of the birds won't come down."},
		{"speaker": "Chan's son", "text": "If she flies off now she might not find the new place."},
	],
	"son_found_nochan": [
		{"speaker": "Chan's son", "text": "Mei? What are you doing up here?"},
		{"speaker": "Mei", "text": "Is that your family's washing on the catwalk? I can't get past it."},
		{"speaker": "Chan's son", "text": "Ma's washing! I was supposed to bring it up hours ago."},
		{"speaker": "Chan's son", "text": "I can't yet. Mr. Ng needs me. One of the birds won't come down."},
		{"speaker": "Chan's son", "text": "If she flies off now she might not find the new place."},
	],
	"son_shh": [
		{"speaker": "Chan's son", "text": "Shh. You'll scare the birds."},
	],
	"son_photo": [
		{"speaker": "Chan's son", "text": "Go on, take it. He never lets anyone."},
	],
	"son_catwalk": [
		{"speaker": "Chan's son", "text": "Don't touch, they're still wet. I'm taking them up to the roof."},
	],
	"son_waiting": [
		{"speaker": "Chan's son", "text": "She's somewhere up by the water tank. She's scared."},
	],
	"son_leaves": [
		{"speaker": "Chan's son", "text": "Ma's washing! I forgot again. She's going to kill me."},
		{"speaker": "Chan's son", "text": "I'll bring it up here to dry. And I'll get the stair door open for you. There's a trick to it."},
	],
	"son_after": [
		{"speaker": "Chan's son", "text": "Don't tell Ma how long it took."},
	],
	"ng_stranger": [
		{"speaker": "Mr. Ng", "text": "Mind the birds. They don't like strangers."},
	],
	"ng_early": [
		{"speaker": "Mei", "text": "Have you seen Mrs. Chan's son?"},
		{"speaker": "Mr. Ng", "text": "Over by the coop, pretending to work."},
	],
	"ng_quest": [
		{"speaker": "Mr. Ng", "text": "Hm. Lee's girl. Or is it Leung's."},
		{"speaker": "Mei", "text": "Grandfather's."},
		{"speaker": "Mr. Ng", "text": "Ah. Then you're patient."},
		{"speaker": "Mr. Ng", "text": "One of mine's hiding up by the water tank. She won't come down unless she can see the way home."},
		{"speaker": "Mr. Ng", "text": "Find her. Then look at it the way she does."},
	],
	"ng_waiting": [
		{"speaker": "Mr. Ng", "text": "Find her first. Then look at it the way she does."},
	],
	"sheet_plain": [
		{"speaker": "", "text": "A bedsheet, pegged out to dry between the tank and the coop."},
	],
	"sheet_unpin": [
		{"speaker": "", "text": "From where she's perched, this sheet hangs right across her view of the coop."},
		{"speaker": "", "text": "Mei unpins one corner and lets it swing aside."},
	],
	"ng_helped": [
		{"speaker": "Mr. Ng", "text": "There. See? She knew the way. She only needed to see it."},
		{"speaker": "Mr. Ng", "text": "They know the way home better than people do."},
		{"speaker": "Mei", "text": "Can I take one?"},
		{"speaker": "Mr. Ng", "text": "Of me?"},
		{"speaker": "", "text": "A roar builds somewhere over the rooftops.", "event": "planeApproaches"},
		{"speaker": "Mr. Ng", "text": "Get the birds in it."},
	],
	"ng_waiting_photo": [
		{"speaker": "Mr. Ng", "text": "Well? The birds won't hold still forever."},
	],
	"ng_after": [
		{"speaker": "Mr. Ng", "text": "Tell your grandfather the birds miss him."},
	],
	"wong_deliver": [
		{"speaker": "Mrs. Wong", "text": "Your grandfather sent this?"},
		{"speaker": "Mei", "text": "Yeah."},
		{"speaker": "Mrs. Wong", "text": "Tell him I'm not leaving before he does."},
		{"speaker": "Mei", "text": "What does that mean?"},
		{"speaker": "Mrs. Wong", "text": "He'll know."},
		{"speaker": "Mrs. Wong", "text": "Go home, it's getting late."},
	],
	"wong_after": [
		{"speaker": "Mrs. Wong", "text": "Go home, Mei."},
	],
	"chopper": [
		{"speaker": "Auntie Ho", "text": "Watch the pipe. And tell your grandfather the soup is for him."},
	],
	"mahjong": [
		{"speaker": "Mr. Fung", "text": "Your grandfather looking for you? He owes me forty dollars."},
	],
	"fanman": [
		{"speaker": "Repairman", "text": "Fifty years this fan's been going. Might as well fix it one more time."},
	],
	"shopkeeper": [
		{"speaker": "Mr. Kwok", "text": "Says here they're setting a date."},
		{"speaker": "Mr. Kwok", "text": "They've been setting a date since I was your age."},
	],
	"worker": [
		{"speaker": "Worker", "text": "Excuse me. These are heavy."},
	],
	"child": [
		{"speaker": "Little Wai", "text": "Don't run on the stairs. My ma says."},
	],
	"stairs_blocked": [
		{"speaker": "Mei", "text": "Mr. Lau wanted his picture first."},
	],
	"camera_no_subject": [
		{"speaker": "", "text": "Film is precious. Mei lowers the camera."},
	],
}


static func lines(id: String) -> Array:
	return LINES.get(id, [])
