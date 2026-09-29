class_name QuestStage
extends RefCounted

## The slice's single linear story, as stages. Spatial freedom, linear narrative.

enum {
	START,
	MEDICINE_RECEIVED,
	REACHED_LAU,
	LAU_PHOTO,
	CATWALK_BLOCKED,
	MET_CHAN,
	SEARCHING_FOR_SON,
	FOUND_SON,
	HELPED_NG,
	FABRIC_MOVED,
	MEDICINE_DELIVERED,
	RETURNED_HOME,
	COMPLETE,
}

const NAMES := [
	"START", "MEDICINE_RECEIVED", "REACHED_LAU", "LAU_PHOTO", "CATWALK_BLOCKED", "MET_CHAN",
	"SEARCHING_FOR_SON", "FOUND_SON", "HELPED_NG", "FABRIC_MOVED", "MEDICINE_DELIVERED",
	"RETURNED_HOME", "COMPLETE",
]

## Objectives remind; they never solve. No distances, no markers.
const OBJECTIVES := {
	START: ["", ""],
	MEDICINE_RECEIVED: ["Bring Grandfather's medicine to Mrs. Wong.", "Grandfather said to follow the blue pipe."],
	REACHED_LAU: ["Mr. Lau wants a photograph.", "Press C to raise the camera."],
	LAU_PHOTO: ["Find a way upstairs.", "“When you reach Lau's place, go up.”"],
	CATWALK_BLOCKED: ["Someone's washing is blocking the catwalk.", "It's still dripping. Whoever hung it lives close by."],
	MET_CHAN: ["Find Wai.", "“He's probably gone up to the roof again.”"],
	SEARCHING_FOR_SON: ["Find Wai.", "“He's probably gone up to the roof again.”"],
	FOUND_SON: ["One of Mr. Ng's pigeons won't come down.", "“She won't come down unless she can see the way.”"],
	HELPED_NG: ["Take Mr. Ng's photograph.", "“Get the birds in it.”"],
	FABRIC_MOVED: ["Bring Grandfather's medicine to Mrs. Wong.", "Wai went to fetch the washing."],
	MEDICINE_DELIVERED: ["Return home.", ""],
	RETURNED_HOME: ["", ""],
	COMPLETE: ["", ""],
}


static func name_of(stage: int) -> String:
	return NAMES[clampi(stage, 0, NAMES.size() - 1)]


## Flags implied by a stage, so debug jumps always leave a consistent world.
static func flags_for(stage: int) -> Dictionary:
	return {
		"received_camera": stage >= MEDICINE_RECEIVED,
		"photographed_lau": stage >= LAU_PHOTO,
		"met_chan": stage >= MET_CHAN,
		"found_chan_son": stage >= FOUND_SON,
		"helped_ng": stage >= HELPED_NG,
		"delivered_medicine": stage >= MEDICINE_DELIVERED,
		"returned_home": stage >= RETURNED_HOME,
		"roof_door_open": stage >= FABRIC_MOVED,
		"setup_ng_home_line": stage >= FABRIC_MOVED,
		"setup_wong_bet": stage >= MEDICINE_DELIVERED,
	}


## Scrapbook contents a stage implies (debug stage jumps).
static func scrapbook_for(stage: int) -> Array[String]:
	var list: Array[String] = []
	if stage >= LAU_PHOTO:
		list.append("lau")
	if stage >= FABRIC_MOVED:
		list.append("ng")
	return list


## Debug teleport points (1-6 while the overlay is open).
const TELEPORTS := {
	1: ["Apartment", Vector3(-8.5, 0, 2)],
	2: ["Dentist", Vector3(3, 0, -10.5)],
	3: ["Mrs. Chan", Vector3(-1, 5, -12)],
	4: ["Airshaft", Vector3(-5, 5, -17.4)],
	5: ["Rooftop", Vector3(-5, 13, -14.5)],
	6: ["Mrs. Wong", Vector3(25.5, 5, -12)],
}
