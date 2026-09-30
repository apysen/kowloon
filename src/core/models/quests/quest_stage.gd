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
## [objective, hint] as keys into data/i18n/strings.csv.
const OBJECTIVES := {
	START: ["", ""],
	MEDICINE_RECEIVED: ["obj.medicine.main", "obj.medicine.hint"],
	REACHED_LAU: ["obj.reached_lau.main", "obj.reached_lau.hint"],
	LAU_PHOTO: ["obj.lau_photo.main", "obj.lau_photo.hint"],
	CATWALK_BLOCKED: ["obj.catwalk.main", "obj.catwalk.hint"],
	MET_CHAN: ["obj.find_wai.main", "obj.find_wai.hint"],
	SEARCHING_FOR_SON: ["obj.find_wai.main", "obj.find_wai.hint"],
	FOUND_SON: ["obj.pigeon.main", "obj.pigeon.hint"],
	HELPED_NG: ["obj.ng_photo.main", "obj.ng_photo.hint"],
	FABRIC_MOVED: ["obj.medicine.main", "obj.fabric_moved.hint"],
	MEDICINE_DELIVERED: ["obj.return_home.main", ""],
	RETURNED_HOME: ["", ""],
	COMPLETE: ["", ""],
}


static func name_of(stage: int) -> String:
	return NAMES[clampi(stage, 0, NAMES.size() - 1)]


## Flags implied by a stage, so debug jumps always leave a consistent world.
static func flags_for(stage: int) -> Dictionary:
	return {
		"setup_boxes": true,
		"setup_blue_pipe": stage >= MEDICINE_RECEIVED,
		"setup_mei_photographs": stage >= LAU_PHOTO,
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
