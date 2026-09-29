class_name ResidentCatalog
extends RefCounted

## Scrapbook entries. The personal note matters more than the facts.

const ENTRIES := {
	"lau": {
		"name": "Mr. Lau",
		"occupation": "Dentist",
		"location": "Third Floor, Lung Chun Road",
		"context": "Unlicensed dentists and doctors practised inside the Walled City for decades, charging a fraction of Hong Kong prices.",
		"note": "His new clinic will have windows.",
	},
	"ng": {
		"name": "Mr. Ng",
		"occupation": "Pigeon Keeper",
		"location": "Rooftop, above the airshaft",
		"context": "The rooftops were the only open space in the city. Residents kept birds, dried laundry and watched planes land at Kai Tak.",
		"note": "Mr. Ng says they know the way home better than people do.",
	},
}

## Speaking voices: the pitch of each speaker's dialogue blip.
const VOICE_PITCH := {
	"Mei": 1.35, "Grandfather": 0.65, "Mr. Lau": 0.92, "Mrs. Chan": 1.13, "Wai": 1.52,
	"Mr. Ng": 0.74, "Mrs. Wong": 1.04, "Mr. Ho": 0.82,
}


static func entry(id: String) -> Dictionary:
	return ENTRIES.get(id, {})
