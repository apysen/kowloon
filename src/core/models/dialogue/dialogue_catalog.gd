class_name DialogueCatalog
extends RefCounted

## Every conversation in the slice, line by line.
##
## `speaker` is who says it (their name is the `speaker.<id>` string); empty is
## narration. `text` is the line's key in data/i18n/strings.csv, where the
## English and the Chinese sit side by side. `event` fires when the line
## appears (the camera changing hands, the plane coming over the roofs).

const LINES := {
	"grandfather_intro": [
		{"speaker": "grandfather", "text": "dlg.grandfather_intro.01"},
		{"speaker": "mei", "text": "dlg.grandfather_intro.02"},
		{"speaker": "grandfather", "text": "dlg.grandfather_intro.03"},
		{"speaker": "grandfather", "text": "dlg.grandfather_intro.04"},
		{"speaker": "", "text": "dlg.grandfather_intro.05", "event": "receiveCamera"},
		{"speaker": "mei", "text": "dlg.grandfather_intro.06"},
		{"speaker": "grandfather", "text": "dlg.grandfather_intro.07"},
		{"speaker": "grandfather", "text": "dlg.grandfather_intro.08"},
	],
	"grandfather_idle": [
		{"speaker": "grandfather", "text": "dlg.grandfather_idle.01"},
	],
	"grandfather_late": [
		{"speaker": "grandfather", "text": "dlg.grandfather_late.01"},
		{"speaker": "mei", "text": "dlg.grandfather_late.02"},
		{"speaker": "grandfather", "text": "dlg.grandfather_late.03"},
	],
	"grandfather_return": [
		{"speaker": "mei", "text": "dlg.grandfather_return.01"},
		{"speaker": "grandfather", "text": "dlg.grandfather_return.02"},
		{"speaker": "mei", "text": "dlg.grandfather_return.03"},
		{"speaker": "grandfather", "text": "dlg.grandfather_return.04"},
		{"speaker": "mei", "text": "dlg.grandfather_return.05"},
		{"speaker": "", "text": "dlg.grandfather_return.06"},
		{"speaker": "", "text": "dlg.grandfather_return.07"},
		{"speaker": "grandfather", "text": "dlg.grandfather_return.08"},
		{"speaker": "mei", "text": "dlg.grandfather_return.09"},
		{"speaker": "grandfather", "text": "dlg.grandfather_return.10"},
		{"speaker": "grandfather", "text": "dlg.grandfather_return.11"},
	],
	"mum_kit": [
		{"speaker": "mum", "text": "dlg.mum_kit.01"},
		{"speaker": "mei", "text": "dlg.mum_kit.02"},
		{"speaker": "mum", "text": "dlg.mum_kit.03"},
		{"speaker": "", "text": "dlg.mum_kit.04"},
	],
	"mum_idle": [
		{"speaker": "mum", "text": "dlg.mum_idle.01"},
	],
	"old_photo": [
		{"speaker": "", "text": "dlg.old_photo.01"},
		{"speaker": "mei", "text": "dlg.old_photo.02"},
		{"speaker": "grandfather", "text": "dlg.old_photo.03"},
		{"speaker": "mei", "text": "dlg.old_photo.04"},
	],
	"old_photo_again": [
		{"speaker": "", "text": "dlg.old_photo_again.01"},
	],
	"grandfather_end": [
		{"speaker": "grandfather", "text": "dlg.grandfather_end.01"},
	],
	"boxes_end": [
		{"speaker": "", "text": "dlg.boxes_end.01"},
		{"speaker": "", "text": "dlg.boxes_end.02"},
		{"speaker": "mei", "text": "dlg.boxes_end.03"},
	],
	"lau_intro": [
		{"speaker": "lau", "text": "dlg.lau_intro.01"},
		{"speaker": "mei", "text": "dlg.lau_intro.02"},
		{"speaker": "lau", "text": "dlg.lau_intro.03"},
		{"speaker": "mei", "text": "dlg.lau_intro.04"},
		{"speaker": "lau", "text": "dlg.lau_intro.05"},
		{"speaker": "lau", "text": "dlg.lau_intro.06"},
		{"speaker": "lau", "text": "dlg.lau_intro.07"},
		{"speaker": "lau", "text": "dlg.lau_intro.08"},
		{"speaker": "lau", "text": "dlg.lau_intro.09"},
		{"speaker": "lau", "text": "dlg.lau_intro.10"},
	],
	"lau_waiting": [
		{"speaker": "lau", "text": "dlg.lau_waiting.01"},
	],
	"lau_after_photo": [
		{"speaker": "lau", "text": "dlg.lau_after_photo.01"},
		{"speaker": "lau", "text": "dlg.lau_after_photo.02"},
	],
	"lau_windows": [
		{"speaker": "lau", "text": "dlg.lau_windows.01"},
		{"speaker": "mei", "text": "dlg.lau_windows.02"},
		{"speaker": "lau", "text": "dlg.lau_windows.03"},
	],
	"lau_idle": [
		{"speaker": "lau", "text": "dlg.lau_idle.01"},
	],
	"lau_return": [
		{"speaker": "lau", "text": "dlg.lau_return.01"},
	],
	"fabric_first": [
		{"speaker": "", "text": "dlg.fabric_first.01"},
		{"speaker": "", "text": "dlg.fabric_first.02"},
	],
	"fabric_again": [
		{"speaker": "", "text": "dlg.fabric_again.01"},
	],
	"chan_early": [
		{"speaker": "chan", "text": "dlg.chan_early.01"},
	],
	"chan_quest": [
		{"speaker": "mei", "text": "dlg.chan_quest.01"},
		{"speaker": "chan", "text": "dlg.chan_quest.02"},
		{"speaker": "chan", "text": "dlg.chan_quest.03"},
		{"speaker": "chan", "text": "dlg.chan_quest.04"},
		{"speaker": "mei", "text": "dlg.chan_quest.05"},
		{"speaker": "chan", "text": "dlg.chan_quest.06"},
		{"speaker": "chan", "text": "dlg.chan_quest.07"},
	],
	"chan_waiting": [
		{"speaker": "chan", "text": "dlg.chan_waiting.01"},
	],
	"chan_told": [
		{"speaker": "mei", "text": "dlg.chan_told.01"},
		{"speaker": "chan", "text": "dlg.chan_told.02"},
	],
	"chan_coming": [
		{"speaker": "mei", "text": "dlg.chan_coming.01"},
		{"speaker": "chan", "text": "dlg.chan_coming.02"},
	],
	"chan_after": [
		{"speaker": "chan", "text": "dlg.chan_after.01"},
	],
	"shaft_look": [
		{"speaker": "", "text": "dlg.shaft_look.01"},
		{"speaker": "", "text": "dlg.shaft_look.02"},
	],
	"shaft_look_found": [
		{"speaker": "", "text": "dlg.shaft_look_found.01"},
		{"speaker": "", "text": "dlg.shaft_look_found.02"},
	],
	"shaft_climb": [
		{"speaker": "", "text": "dlg.shaft_climb.01"},
		{"speaker": "", "text": "dlg.shaft_climb.02"},
	],
	"shaft_down_unknown": [
		{"speaker": "", "text": "dlg.shaft_down_unknown.01"},
	],
	"roofdoor_latched": [
		{"speaker": "", "text": "dlg.roofdoor_latched.01"},
	],
	"roofdoor_top_stuck": [
		{"speaker": "", "text": "dlg.roofdoor_top_stuck.01"},
	],
	"son_found": [
		{"speaker": "wai", "text": "dlg.son_found.01"},
		{"speaker": "mei", "text": "dlg.son_found.02"},
		{"speaker": "wai", "text": "dlg.son_found.03"},
		{"speaker": "wai", "text": "dlg.son_found.04"},
		{"speaker": "wai", "text": "dlg.son_found.05"},
	],
	"son_found_nochan": [
		{"speaker": "wai", "text": "dlg.son_found_nochan.01"},
		{"speaker": "mei", "text": "dlg.son_found_nochan.02"},
		{"speaker": "wai", "text": "dlg.son_found_nochan.03"},
		{"speaker": "wai", "text": "dlg.son_found_nochan.04"},
		{"speaker": "wai", "text": "dlg.son_found_nochan.05"},
	],
	"son_shh": [
		{"speaker": "wai", "text": "dlg.son_shh.01"},
	],
	"son_photo": [
		{"speaker": "wai", "text": "dlg.son_photo.01"},
	],
	"son_catwalk": [
		{"speaker": "wai", "text": "dlg.son_catwalk.01"},
	],
	"son_waiting": [
		{"speaker": "wai", "text": "dlg.son_waiting.01"},
	],
	"son_leaves": [
		{"speaker": "wai", "text": "dlg.son_leaves.01"},
		{"speaker": "wai", "text": "dlg.son_leaves.02"},
	],
	"son_after": [
		{"speaker": "wai", "text": "dlg.son_after.01"},
	],
	"ng_stranger": [
		{"speaker": "ng", "text": "dlg.ng_stranger.01"},
	],
	"ng_early": [
		{"speaker": "mei", "text": "dlg.ng_early.01"},
		{"speaker": "ng", "text": "dlg.ng_early.02"},
	],
	"ng_quest": [
		{"speaker": "ng", "text": "dlg.ng_quest.01"},
		{"speaker": "mei", "text": "dlg.ng_quest.02"},
		{"speaker": "ng", "text": "dlg.ng_quest.03"},
		{"speaker": "ng", "text": "dlg.ng_quest.04"},
		{"speaker": "ng", "text": "dlg.ng_quest.05"},
	],
	"ng_waiting": [
		{"speaker": "ng", "text": "dlg.ng_waiting.01"},
	],
	"sheet_plain": [
		{"speaker": "", "text": "dlg.sheet_plain.01"},
	],
	"sheet_unpin": [
		{"speaker": "", "text": "dlg.sheet_unpin.01"},
		{"speaker": "", "text": "dlg.sheet_unpin.02"},
	],
	"ng_helped": [
		{"speaker": "ng", "text": "dlg.ng_helped.01"},
		{"speaker": "ng", "text": "dlg.ng_helped.02"},
		{"speaker": "mei", "text": "dlg.ng_helped.03"},
		{"speaker": "ng", "text": "dlg.ng_helped.04"},
		{"speaker": "", "text": "dlg.ng_helped.05", "event": "planeApproaches"},
		{"speaker": "ng", "text": "dlg.ng_helped.06"},
	],
	"ng_waiting_photo": [
		{"speaker": "ng", "text": "dlg.ng_waiting_photo.01"},
	],
	"ng_after": [
		{"speaker": "ng", "text": "dlg.ng_after.01"},
	],
	"wong_deliver": [
		{"speaker": "wong", "text": "dlg.wong_deliver.01"},
		{"speaker": "mei", "text": "dlg.wong_deliver.02"},
		{"speaker": "wong", "text": "dlg.wong_deliver.03"},
		{"speaker": "mei", "text": "dlg.wong_deliver.04"},
		{"speaker": "wong", "text": "dlg.wong_deliver.05"},
		{"speaker": "wong", "text": "dlg.wong_deliver.06"},
	],
	"wong_after": [
		{"speaker": "wong", "text": "dlg.wong_after.01"},
	],
	"chopper": [
		{"speaker": "yip", "text": "dlg.chopper.01"},
	],
	"mahjong": [
		{"speaker": "tsang", "text": "dlg.mahjong.01"},
	],
	"fanman": [
		{"speaker": "ho", "text": "dlg.fanman.01"},
	],
	"shopkeeper": [
		{"speaker": "kwok", "text": "dlg.shopkeeper.01"},
		{"speaker": "kwok", "text": "dlg.shopkeeper.02"},
	],
	"worker": [
		{"speaker": "worker", "text": "dlg.worker.01"},
	],
	"child": [
		{"speaker": "lok", "text": "dlg.child.01"},
	],
	"stairs_blocked": [
		{"speaker": "mei", "text": "dlg.stairs_blocked.01"},
	],
	"camera_no_subject": [
		{"speaker": "", "text": "dlg.camera_no_subject.01"},
	],
	"c2_cold_open": [
		{"speaker": "", "text": "dlg.c2_cold_open.01", "event": "pumpStart"},
		{"speaker": "", "text": "dlg.c2_cold_open.02", "event": "pumpStop"},
		{"speaker": "grandfather", "text": "dlg.c2_cold_open.03"},
		{"speaker": "mum", "text": "dlg.c2_cold_open.04"},
		{"speaker": "mei", "text": "dlg.c2_cold_open.05"},
		{"speaker": "mum", "text": "dlg.c2_cold_open.06"},
		{"speaker": "grandfather", "text": "dlg.c2_cold_open.07"},
		{"speaker": "mum", "text": "dlg.c2_cold_open.08"},
		{"speaker": "grandfather", "text": "dlg.c2_cold_open.09"},
	],
	"c2_grandfather_idle": [
		{"speaker": "grandfather", "text": "dlg.c2_grandfather_idle.01"},
	],
	"c2_grandfather_after": [
		{"speaker": "grandfather", "text": "dlg.c2_grandfather_after.01"},
	],
	"c2_mum_idle": [
		{"speaker": "mum", "text": "dlg.c2_mum_idle.01"},
	],
	"c2_mum_water": [
		{"speaker": "mum", "text": "dlg.c2_mum_water.01"},
	],
	"c2_ho_find": [
		{"speaker": "mei", "text": "dlg.c2_ho_find.01"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.02"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.03"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.04"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.05"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.06"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.07"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.08"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.09"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.10"},
		{"speaker": "", "text": "dlg.c2_ho_find.11"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.12"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.13"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.14"},
		{"speaker": "mei", "text": "dlg.c2_ho_find.15"},
		{"speaker": "ho", "text": "dlg.c2_ho_find.16"},
	],
	"c2_ho_trace": [
		{"speaker": "ho", "text": "dlg.c2_ho_trace.01"},
	],
	"c2_blue_until": [
		{"speaker": "mei", "text": "dlg.c2_blue_until.01"},
	],
	"c2_branch_seen": [
		{"speaker": "", "text": "dlg.c2_branch_seen.01"},
		{"speaker": "mei", "text": "dlg.c2_branch_seen.02"},
	],
	"c2_well_seen": [
		{"speaker": "", "text": "dlg.c2_well_seen.01"},
		{"speaker": "mei", "text": "dlg.c2_well_seen.02"},
	],
	"c2_hint_knock": [
		{"speaker": "mei", "text": "dlg.c2_hint_knock.01"},
	],
	"c2_hint_ho": [
		{"speaker": "ho", "text": "dlg.c2_hint_ho.01"},
	],
	"c2_hint_ledge": [
		{"speaker": "mei", "text": "dlg.c2_hint_ledge.01"},
	],
	"c2_hint_back": [
		{"speaker": "mei", "text": "dlg.c2_hint_back.01"},
	],
	"c2_chained": [
		{"speaker": "", "text": "dlg.c2_chained.01"},
		{"speaker": "", "text": "dlg.c2_chained.02"},
	],
	"c2_climb_in": [
		{"speaker": "", "text": "dlg.c2_climb_in.01"},
	],
	"c2_valve_neighbour": [
		{"speaker": "", "text": "dlg.c2_valve_neighbour.01", "event": "splash"},
		{"speaker": "neighbour", "text": "dlg.c2_valve_neighbour.02"},
		{"speaker": "ho", "text": "dlg.c2_valve_neighbour.03"},
		{"speaker": "", "text": "dlg.c2_valve_neighbour.04"},
	],
	"c2_valve_neighbour_again": [
		{"speaker": "", "text": "dlg.c2_valve_neighbour_again.01", "event": "splash"},
		{"speaker": "neighbour", "text": "dlg.c2_valve_neighbour_again.02"},
		{"speaker": "", "text": "dlg.c2_valve_neighbour_again.03"},
	],
	"c2_valve_sink": [
		{"speaker": "", "text": "dlg.c2_valve_sink.01", "event": "sinkCough"},
		{"speaker": "mei", "text": "dlg.c2_valve_sink.02"},
		{"speaker": "", "text": "dlg.c2_valve_sink.03"},
	],
	"c2_valve_right": [
		{"speaker": "", "text": "dlg.c2_valve_right.01"},
		{"speaker": "", "text": "dlg.c2_valve_right.02", "event": "waterRush"},
		{"speaker": "mei", "text": "dlg.c2_valve_right.03"},
	],
	"c2_ho_restored": [
		{"speaker": "mei", "text": "dlg.c2_ho_restored.01"},
		{"speaker": "ho", "text": "dlg.c2_ho_restored.02"},
		{"speaker": "mei", "text": "dlg.c2_ho_restored.03"},
		{"speaker": "ho", "text": "dlg.c2_ho_restored.04"},
		{"speaker": "mei", "text": "dlg.c2_ho_restored.05"},
		{"speaker": "ho", "text": "dlg.c2_ho_restored.06"},
		{"speaker": "mei", "text": "dlg.c2_ho_restored.07"},
		{"speaker": "ho", "text": "dlg.c2_ho_restored.08"},
		{"speaker": "", "text": "dlg.c2_ho_restored.09"},
		{"speaker": "ho", "text": "dlg.c2_ho_restored.10"},
	],
	"c2_ho_after": [
		{"speaker": "ho", "text": "dlg.c2_ho_after.01"},
	],
	"c2_ho_photo": [
		{"speaker": "ho", "text": "dlg.c2_ho_photo.01"},
		{"speaker": "mei", "text": "dlg.c2_ho_photo.02"},
		{"speaker": "ho", "text": "dlg.c2_ho_photo.03"},
		{"speaker": "mei", "text": "dlg.c2_ho_photo.04"},
	],
	"c2_mum_after": [
		{"speaker": "mum", "text": "dlg.c2_mum_after.01"},
		{"speaker": "mei", "text": "dlg.c2_mum_after.02"},
		{"speaker": "mum", "text": "dlg.c2_mum_after.03"},
		{"speaker": "mei", "text": "dlg.c2_mum_after.04"},
		{"speaker": "mum", "text": "dlg.c2_mum_after.05"},
	],
	"c2_mum_done": [
		{"speaker": "mum", "text": "dlg.c2_mum_done.01"},
	],
	"c2_ho_pose": [
		{"speaker": "ho", "text": "dlg.c2_ho_pose.01"},
	],
	"c2_mum_tea": [
		{"speaker": "mum", "text": "dlg.c2_mum_tea.01"},
	],
	"c2_tea": [
		{"speaker": "grandfather", "text": "dlg.c2_tea.01"},
		{"speaker": "mei", "text": "dlg.c2_tea.02"},
		{"speaker": "grandfather", "text": "dlg.c2_tea.03"},
		{"speaker": "mei", "text": "dlg.c2_tea.04"},
		{"speaker": "grandfather", "text": "dlg.c2_tea.05"},
		{"speaker": "mei", "text": "dlg.c2_tea.06"},
		{"speaker": "grandfather", "text": "dlg.c2_tea.07"},
		{"speaker": "", "text": "dlg.c2_tea.08"},
	],
	"c2_brochure": [
		{"speaker": "", "text": "dlg.c2_brochure.01"},
		{"speaker": "mei", "text": "dlg.c2_brochure.02"},
		{"speaker": "mum", "text": "dlg.c2_brochure.03"},
		{"speaker": "grandfather", "text": "dlg.c2_brochure.04"},
	],
	"c2_tap_dry": [
		{"speaker": "", "text": "dlg.c2_tap_dry.01"},
	],
	"c2_tap_wet": [
		{"speaker": "", "text": "dlg.c2_tap_wet.01"},
	],
	"c2_chan_dry": [
		{"speaker": "chan", "text": "dlg.c2_chan_dry.01"},
	],
	"c2_chan_wet": [
		{"speaker": "chan", "text": "dlg.c2_chan_wet.01"},
	],
	"c2_wai": [
		{"speaker": "wai", "text": "dlg.c2_wai.01"},
	],
	"c2_ng": [
		{"speaker": "ng", "text": "dlg.c2_ng.01"},
	],
	"c2_lau": [
		{"speaker": "lau", "text": "dlg.c2_lau.01"},
	],
	"c2_wong": [
		{"speaker": "wong", "text": "dlg.c2_wong.01"},
	],
	"c2_kwok": [
		{"speaker": "kwok", "text": "dlg.c2_kwok.01"},
	],
	"c2_chopper": [
		{"speaker": "yip", "text": "dlg.c2_chopper.01"},
	],
	"c2_chopper_wet": [
		{"speaker": "yip", "text": "dlg.c2_chopper_wet.01"},
	],
	"c2_mahjong": [
		{"speaker": "tsang", "text": "dlg.c2_mahjong.01"},
	],
	"c2_worker": [
		{"speaker": "worker", "text": "dlg.c2_worker.01"},
	],
	"c2_child": [
		{"speaker": "lok", "text": "dlg.c2_child.01"},
	],
	"c2_child_wet": [
		{"speaker": "lok", "text": "dlg.c2_child_wet.01"},
	],
	"c3_open": [
		{"speaker": "", "text": "dlg.c3_open.01"},
		{"speaker": "kit", "text": "dlg.c3_open.02"},
		{"speaker": "mei", "text": "dlg.c3_open.03"},
		{"speaker": "kit", "text": "dlg.c3_open.04"},
		{"speaker": "mei", "text": "dlg.c3_open.05"},
		{"speaker": "kit", "text": "dlg.c3_open.06"},
		{"speaker": "mei", "text": "dlg.c3_open.07"},
		{"speaker": "kit", "text": "dlg.c3_open.08"},
		{"speaker": "kit", "text": "dlg.c3_open.09"},
	],
	"c3_kit_come": [
		{"speaker": "kit", "text": "dlg.c3_kit_come.01"},
	],
	"c3_chiu": [
		{"speaker": "chiu", "text": "dlg.c3_chiu.01"},
		{"speaker": "", "text": "dlg.c3_chiu.02"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.03"},
		{"speaker": "kit", "text": "dlg.c3_chiu.04"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.05"},
		{"speaker": "mei", "text": "dlg.c3_chiu.06"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.07"},
		{"speaker": "kit", "text": "dlg.c3_chiu.08"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.09"},
		{"speaker": "", "text": "dlg.c3_chiu.10"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.11"},
		{"speaker": "mei", "text": "dlg.c3_chiu.12"},
		{"speaker": "chiu", "text": "dlg.c3_chiu.13"},
	],
	"c3_chiu_up": [
		{"speaker": "chiu", "text": "dlg.c3_chiu_up.01"},
	],
	"c3_hint_look_back": [
		{"speaker": "mei", "text": "dlg.c3_hint_look_back.01"},
	],
	"c3_pulley_found": [
		{"speaker": "", "text": "dlg.c3_pulley_found.01"},
		{"speaker": "mei", "text": "dlg.c3_pulley_found.02"},
		{"speaker": "mei", "text": "dlg.c3_pulley_found.03"},
		{"speaker": "kit", "text": "dlg.c3_kit_parts.01"},
		{"speaker": "kit", "text": "dlg.c3_kit_parts.02"},
	],
	"c3_kit_parts": [
		{"speaker": "kit", "text": "dlg.c3_kit_parts.01"},
		{"speaker": "kit", "text": "dlg.c3_kit_parts.02"},
	],
	"c3_kit_not_yet": [
		{"speaker": "kit", "text": "dlg.c3_kit_not_yet.01"},
	],
	"c3_kit_idle": [
		{"speaker": "kit", "text": "dlg.c3_kit_idle.01"},
	],
	"c3_hint_setup": [
		{"speaker": "kit", "text": "dlg.c3_hint_setup.01"},
	],
	"c3_ho_early": [
		{"speaker": "ho", "text": "dlg.c3_ho_early.01"},
	],
	"c3_ho_pulley": [
		{"speaker": "", "text": "dlg.c3_ho_pulley.01"},
		{"speaker": "ho", "text": "dlg.c3_ho_pulley.02"},
		{"speaker": "mei", "text": "dlg.c3_ho_pulley.03"},
		{"speaker": "ho", "text": "dlg.c3_ho_pulley.04"},
		{"speaker": "mei", "text": "dlg.c3_ho_pulley.05"},
		{"speaker": "ho", "text": "dlg.c3_ho_pulley.06"},
	],
	"c3_ho_after": [
		{"speaker": "ho", "text": "dlg.c3_ho_after.01"},
	],
	"c3_ng": [
		{"speaker": "ng", "text": "dlg.c3_ng.01"},
	],
	"c3_ng_rope": [
		{"speaker": "mei", "text": "dlg.c3_ng_rope.01"},
		{"speaker": "ng", "text": "dlg.c3_ng_rope.02"},
		{"speaker": "mei", "text": "dlg.c3_ng_rope.03"},
		{"speaker": "ng", "text": "dlg.c3_ng_rope.04"},
		{"speaker": "", "text": "dlg.c3_ng_rope.05"},
		{"speaker": "ng", "text": "dlg.c3_ng_rope.06"},
		{"speaker": "mei", "text": "dlg.c3_ng_rope.07"},
		{"speaker": "ng", "text": "dlg.c3_ng_rope.08"},
	],
	"c3_ng_after": [
		{"speaker": "ng", "text": "dlg.c3_ng_after.01"},
	],
	"c3_chan": [
		{"speaker": "chan", "text": "dlg.c3_chan.01"},
	],
	"c3_wai": [
		{"speaker": "wai", "text": "dlg.c3_wai.01"},
	],
	"c3_plank": [
		{"speaker": "mei", "text": "dlg.c3_plank.01"},
		{"speaker": "wai", "text": "dlg.c3_plank.02"},
		{"speaker": "mei", "text": "dlg.c3_plank.03"},
		{"speaker": "wai", "text": "dlg.c3_plank.04"},
		{"speaker": "chan", "text": "dlg.c3_plank.05"},
		{"speaker": "", "text": "dlg.c3_plank.06"},
		{"speaker": "chan", "text": "dlg.c3_plank.07"},
	],
	"c3_chan_after": [
		{"speaker": "chan", "text": "dlg.c3_chan_after.01"},
	],
	"c3_wai_after": [
		{"speaker": "wai", "text": "dlg.c3_wai_after.01"},
	],
	"c3_gap": [
		{"speaker": "", "text": "dlg.c3_gap.01"},
	],
	"c3_plank_laid": [
		{"speaker": "", "text": "dlg.c3_plank_laid.01"},
	],
	"c3_sign": [
		{"speaker": "", "text": "dlg.c3_sign.01"},
	],
	"c3_sign_folded": [
		{"speaker": "", "text": "dlg.c3_sign_folded.01"},
	],
	"c3_winch": [
		{"speaker": "", "text": "dlg.c3_winch.01"},
	],
	"c3_rope_rigged": [
		{"speaker": "", "text": "dlg.c3_rope_rigged.01"},
	],
	"c3_run": [
		{"speaker": "kit", "text": "dlg.c3_run.01"},
		{"speaker": "mei", "text": "dlg.c3_run.02"},
		{"speaker": "kit", "text": "dlg.c3_run.03"},
	],
	"c3_crate_down": [
		{"speaker": "", "text": "dlg.c3_crate_down.01"},
		{"speaker": "kit", "text": "dlg.c3_crate_down.02"},
		{"speaker": "", "text": "dlg.c3_crate_down.03"},
	],
	"c3_final": [
		{"speaker": "", "text": "dlg.c3_final.01"},
		{"speaker": "mei", "text": "dlg.c3_final.02"},
		{"speaker": "chiu", "text": "dlg.c3_final.03"},
		{"speaker": "mei", "text": "dlg.c3_final.04"},
		{"speaker": "chiu", "text": "dlg.c3_final.05"},
		{"speaker": "kit", "text": "dlg.c3_final.06"},
		{"speaker": "chiu", "text": "dlg.c3_final.07"},
		{"speaker": "kit", "text": "dlg.c3_final.08"},
	],
	"c3_chiu_after": [
		{"speaker": "chiu", "text": "dlg.c3_chiu_after.01"},
	],
	"c3_chiu_photo": [
		{"speaker": "chiu", "text": "dlg.c3_chiu_photo.01"},
		{"speaker": "mei", "text": "dlg.c3_chiu_photo.02"},
	],
	"c3_kit_key": [
		{"speaker": "kit", "text": "dlg.c3_kit_key.01"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.02"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.03"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.04"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.05"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.06"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.07"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.08"},
		{"speaker": "", "text": "dlg.c3_kit_key.09"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.10"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.11"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.12"},
		{"speaker": "", "text": "dlg.c3_kit_key.13"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.14"},
		{"speaker": "kit", "text": "dlg.c3_kit_key.15"},
		{"speaker": "mei", "text": "dlg.c3_kit_key.16"},
	],
	"c3_grandfather": [
		{"speaker": "grandfather", "text": "dlg.c3_grandfather.01"},
		{"speaker": "mei", "text": "dlg.c3_grandfather.02"},
		{"speaker": "grandfather", "text": "dlg.c3_grandfather.03"},
	],
	"c3_mum": [
		{"speaker": "mum", "text": "dlg.c3_mum.01"},
	],
	"c3_hand_a": [
		{"speaker": "hand_a", "text": "dlg.c3_hand_a.01"},
	],
	"c3_hand_b": [
		{"speaker": "hand_b", "text": "dlg.c3_hand_b.01"},
	],
	"c3_porter": [
		{"speaker": "porter", "text": "dlg.c3_porter.01"},
	],
	"c3_lau": [
		{"speaker": "lau", "text": "dlg.c3_lau.01"},
	],
	"c3_wong": [
		{"speaker": "wong", "text": "dlg.c3_wong.01"},
	],
	"c3_kwok": [
		{"speaker": "kwok", "text": "dlg.c3_kwok.01"},
	],
	"c3_chopper": [
		{"speaker": "yip", "text": "dlg.c3_chopper.01"},
	],
	"c3_mahjong": [
		{"speaker": "tsang", "text": "dlg.c3_mahjong.01"},
	],
	"c3_worker": [
		{"speaker": "worker", "text": "dlg.c3_worker.01"},
	],
	"c3_child": [
		{"speaker": "lok", "text": "dlg.c3_child.01"},
	],
	"c4_open": [
		{"speaker": "mum", "text": "dlg.c4_open.01"},
		{"speaker": "mei", "text": "dlg.c4_open.02"},
		{"speaker": "mum", "text": "dlg.c4_open.03"},
		{"speaker": "mei", "text": "dlg.c4_open.04"},
		{"speaker": "mum", "text": "dlg.c4_open.05"},
		{"speaker": "grandfather", "text": "dlg.c4_open.06"},
		{"speaker": "mei", "text": "dlg.c4_open.07"},
		{"speaker": "grandfather", "text": "dlg.c4_open.08"},
	],
	"c4_cheung": [
		{"speaker": "cheung", "text": "dlg.c4_cheung.01"},
		{"speaker": "mei", "text": "dlg.c4_cheung.02"},
		{"speaker": "cheung", "text": "dlg.c4_cheung.03"},
		{"speaker": "mei", "text": "dlg.c4_cheung.04"},
		{"speaker": "cheung", "text": "dlg.c4_cheung.05"},
		{"speaker": "mei", "text": "dlg.c4_cheung.06"},
		{"speaker": "cheung", "text": "dlg.c4_cheung.07"},
		{"speaker": "mei", "text": "dlg.c4_cheung.08"},
		{"speaker": "cheung", "text": "dlg.c4_cheung.09"},
	],
	"c4_cheng": [
		{"speaker": "", "text": "dlg.c4_cheng.01"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.02"},
		{"speaker": "mei", "text": "dlg.c4_cheng.03"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.04"},
		{"speaker": "mei", "text": "dlg.c4_cheng.05"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.06"},
		{"speaker": "mei", "text": "dlg.c4_cheng.07"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.08"},
		{"speaker": "mei", "text": "dlg.c4_cheng.09"},
		{"speaker": "", "text": "dlg.c4_cheng.10"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.11"},
		{"speaker": "mover", "text": "dlg.c4_cheng.12"},
		{"speaker": "cheng", "text": "dlg.c4_cheng.13"},
	],
	"c4_cheng_wait": [
		{"speaker": "cheng", "text": "dlg.c4_cheng_wait.01"},
	],
	"c4_route": [
		{"speaker": "mei", "text": "dlg.c4_route.01"},
		{"speaker": "mei", "text": "dlg.c4_route.02"},
		{"speaker": "mover", "text": "dlg.c4_route.03"},
		{"speaker": "mei", "text": "dlg.c4_route.04"},
		{"speaker": "cheng", "text": "dlg.c4_route.05"},
	],
	"c4_cheng_exit": [
		{"speaker": "cheng", "text": "dlg.c4_cheng_exit.01"},
		{"speaker": "mei", "text": "dlg.c4_cheng_exit.02"},
		{"speaker": "cheng", "text": "dlg.c4_cheng_exit.03"},
		{"speaker": "mei", "text": "dlg.c4_cheng_exit.04"},
	],
	"c4_cheng_after": [
		{"speaker": "cheng", "text": "dlg.c4_cheng_after.01"},
	],
	"c4_cabinet": [
		{"speaker": "", "text": "dlg.c4_cabinet.01"},
	],
	"c4_store_door": [
		{"speaker": "", "text": "dlg.c4_store_door.01"},
	],
	"c4_gap_found": [
		{"speaker": "mei", "text": "dlg.c4_gap_found.01"},
	],
	"c4_stair_found": [
		{"speaker": "mei", "text": "dlg.c4_stair_found.01"},
		{"speaker": "", "text": "dlg.c4_stair_found.02"},
	],
	"c4_panel": [
		{"speaker": "", "text": "dlg.c4_panel.01"},
	],
	"c4_panel_open": [
		{"speaker": "", "text": "dlg.c4_panel_open.01"},
		{"speaker": "mei", "text": "dlg.c4_panel_open.02"},
	],
	"c4_lau": [
		{"speaker": "mei", "text": "dlg.c4_lau.01"},
		{"speaker": "lau", "text": "dlg.c4_lau.02"},
		{"speaker": "mei", "text": "dlg.c4_lau.03"},
		{"speaker": "mei", "text": "dlg.c4_lau.04"},
		{"speaker": "lau", "text": "dlg.c4_lau.05"},
		{"speaker": "mei", "text": "dlg.c4_lau.06"},
		{"speaker": "lau", "text": "dlg.c4_lau.07"},
		{"speaker": "lau", "text": "dlg.c4_lau.08"},
		{"speaker": "lau", "text": "dlg.c4_lau.09"},
	],
	"c4_lau_card": [
		{"speaker": "lau", "text": "dlg.c4_lau_card.01"},
	],
	"c4_lau_after": [
		{"speaker": "lau", "text": "dlg.c4_lau_after.01"},
	],
	"c4_card": [
		{"speaker": "", "text": "dlg.c4_card.01"},
		{"speaker": "mei", "text": "dlg.c4_card.02"},
	],
	"c4_card_again": [
		{"speaker": "", "text": "dlg.c4_card_again.01"},
	],
	"c4_wong": [
		{"speaker": "mei", "text": "dlg.c4_wong.01"},
		{"speaker": "wong", "text": "dlg.c4_wong.02"},
		{"speaker": "mei", "text": "dlg.c4_wong.03"},
		{"speaker": "wong", "text": "dlg.c4_wong.04"},
		{"speaker": "mei", "text": "dlg.c4_wong.05"},
		{"speaker": "wong", "text": "dlg.c4_wong.06"},
		{"speaker": "", "text": "dlg.c4_wong.07"},
		{"speaker": "wong", "text": "dlg.c4_wong.08"},
		{"speaker": "mei", "text": "dlg.c4_wong.09"},
		{"speaker": "wong", "text": "dlg.c4_wong.10"},
		{"speaker": "mei", "text": "dlg.c4_wong.11"},
		{"speaker": "wong", "text": "dlg.c4_wong.12"},
		{"speaker": "mei", "text": "dlg.c4_wong.13"},
		{"speaker": "", "text": "dlg.c4_wong.14"},
		{"speaker": "wong", "text": "dlg.c4_wong.15"},
	],
	"c4_wong_after": [
		{"speaker": "wong", "text": "dlg.c4_wong_after.01"},
	],
	"c4_chan": [
		{"speaker": "mei", "text": "dlg.c4_chan.01"},
		{"speaker": "chan", "text": "dlg.c4_chan.02"},
		{"speaker": "mei", "text": "dlg.c4_chan.03"},
		{"speaker": "chan", "text": "dlg.c4_chan.04"},
		{"speaker": "wai", "text": "dlg.c4_chan.05"},
		{"speaker": "chan", "text": "dlg.c4_chan.06"},
	],
	"c4_chan_after": [
		{"speaker": "chan", "text": "dlg.c4_chan_after.01"},
	],
	"c4_kit": [
		{"speaker": "", "text": "dlg.c4_kit.01"},
		{"speaker": "kit", "text": "dlg.c4_kit.02"},
		{"speaker": "mei", "text": "dlg.c4_kit.03"},
		{"speaker": "kit", "text": "dlg.c4_kit.04"},
		{"speaker": "mei", "text": "dlg.c4_kit.05"},
		{"speaker": "kit", "text": "dlg.c4_kit.06"},
	],
	"c4_kit_lift": [
		{"speaker": "mei", "text": "dlg.c4_kit_lift.01"},
		{"speaker": "kit", "text": "dlg.c4_kit_lift.02"},
		{"speaker": "mei", "text": "dlg.c4_kit_lift.03"},
	],
	"c4_kit_after": [
		{"speaker": "kit", "text": "dlg.c4_kit_after.01"},
	],
	"c4_cheung_wait": [
		{"speaker": "cheung", "text": "dlg.c4_cheung_wait.01"},
	],
	"c4_cheung_cabinet": [
		{"speaker": "cheung", "text": "dlg.c4_cheung_cabinet.01"},
	],
	"c4_return": [
		{"speaker": "", "text": "dlg.c4_return.01"},
		{"speaker": "mei", "text": "dlg.c4_return.02"},
		{"speaker": "cheung", "text": "dlg.c4_return.03"},
		{"speaker": "mei", "text": "dlg.c4_return.04"},
		{"speaker": "cheung", "text": "dlg.c4_return.05"},
		{"speaker": "", "text": "dlg.c4_return.06"},
		{"speaker": "cheung", "text": "dlg.c4_return.07"},
		{"speaker": "mei", "text": "dlg.c4_return.08"},
		{"speaker": "cheung", "text": "dlg.c4_return.09"},
	],
	"c4_cheung_pose": [
		{"speaker": "cheung", "text": "dlg.c4_cheung_pose.01"},
	],
	"c4_cheung_photo": [
		{"speaker": "cheung", "text": "dlg.c4_cheung_photo.01"},
		{"speaker": "mei", "text": "dlg.c4_cheung_photo.02"},
		{"speaker": "cheung", "text": "dlg.c4_cheung_photo.03"},
	],
	"c4_grandfather": [
		{"speaker": "grandfather", "text": "dlg.c4_grandfather.01"},
	],
	"c4_mum": [
		{"speaker": "mum", "text": "dlg.c4_mum.01"},
	],
	"c4_mover_a": [
		{"speaker": "mover", "text": "dlg.c4_mover_a.01"},
	],
	"c4_mover_after": [
		{"speaker": "mover", "text": "dlg.c4_mover_after.01"},
	],
	"c4_mover_b": [
		{"speaker": "mover", "text": "dlg.c4_mover_b.01"},
	],
	"c4_taichi": [
		{"speaker": "taichi", "text": "dlg.c4_taichi.01"},
	],
	"c4_bird": [
		{"speaker": "bird", "text": "dlg.c4_bird.01"},
	],
	"c4_ho": [
		{"speaker": "ho", "text": "dlg.c4_ho.01"},
	],
	"c4_ng": [
		{"speaker": "ng", "text": "dlg.c4_ng.01"},
	],
	"c4_kwok": [
		{"speaker": "kwok", "text": "dlg.c4_kwok.01"},
	],
	"c4_chopper": [
		{"speaker": "yip", "text": "dlg.c4_chopper.01"},
	],
	"c4_mahjong": [
		{"speaker": "tsang", "text": "dlg.c4_mahjong.01"},
	],
	"c4_worker": [
		{"speaker": "worker", "text": "dlg.c4_worker.01"},
	],
	"c4_child": [
		{"speaker": "lok", "text": "dlg.c4_child.01"},
	],
	"c5_open": [
		{"speaker": "", "text": "dlg.c5_open.01"},
		{"speaker": "mum", "text": "dlg.c5_open.02"},
		{"speaker": "mei", "text": "dlg.c5_open.03"},
		{"speaker": "mum", "text": "dlg.c5_open.04"},
		{"speaker": "mei", "text": "dlg.c5_open.05"},
		{"speaker": "mum", "text": "dlg.c5_open.06"},
		{"speaker": "", "text": "dlg.c5_open.07"},
		{"speaker": "mum", "text": "dlg.c5_open.08"},
		{"speaker": "", "text": "dlg.c5_open.09"},
		{"speaker": "mei", "text": "dlg.c5_open.10"},
		{"speaker": "mum", "text": "dlg.c5_open.11"},
	],
	"c5_mum": [
		{"speaker": "mum", "text": "dlg.c5_mum.01"},
		{"speaker": "mum", "text": "dlg.c5_mum.02"},
	],
	"c5_mum_after": [
		{"speaker": "", "text": "dlg.c5_mum_after.01"},
	],
	"c5_grandfather": [
		{"speaker": "grandfather", "text": "dlg.c5_grandfather.01"},
		{"speaker": "grandfather", "text": "dlg.c5_grandfather.02"},
		{"speaker": "grandfather", "text": "dlg.c5_grandfather.03"},
	],
	"c5_grandfather_after": [
		{"speaker": "", "text": "dlg.c5_grandfather_after.01"},
		{"speaker": "grandfather", "text": "dlg.c5_grandfather_after.02"},
	],
	"c5_ho": [
		{"speaker": "mei", "text": "dlg.c5_ho.01"},
		{"speaker": "ho", "text": "dlg.c5_ho.02"},
		{"speaker": "mei", "text": "dlg.c5_ho.03"},
		{"speaker": "ho", "text": "dlg.c5_ho.04"},
		{"speaker": "mei", "text": "dlg.c5_ho.05"},
		{"speaker": "ho", "text": "dlg.c5_ho.06"},
		{"speaker": "", "text": "dlg.c5_ho.07"},
	],
	"c5_ho_after": [
		{"speaker": "ho", "text": "dlg.c5_ho_after.01"},
	],
	"c5_ng": [
		{"speaker": "mei", "text": "dlg.c5_ng.01"},
		{"speaker": "ng", "text": "dlg.c5_ng.02"},
		{"speaker": "mei", "text": "dlg.c5_ng.03"},
		{"speaker": "ng", "text": "dlg.c5_ng.04"},
		{"speaker": "", "text": "dlg.c5_ng.05"},
		{"speaker": "ng", "text": "dlg.c5_ng.06"},
		{"speaker": "mei", "text": "dlg.c5_ng.07"},
		{"speaker": "", "text": "dlg.c5_ng.08"},
		{"speaker": "ng", "text": "dlg.c5_ng.09"},
		{"speaker": "mei", "text": "dlg.c5_ng.10"},
		{"speaker": "ng", "text": "dlg.c5_ng.11"},
	],
	"c5_ng_after": [
		{"speaker": "ng", "text": "dlg.c5_ng_after.01"},
	],
	"c5_mahjong": [
		{"speaker": "tsang", "text": "dlg.c5_mahjong.01"},
		{"speaker": "mei", "text": "dlg.c5_mahjong.02"},
		{"speaker": "tsang", "text": "dlg.c5_mahjong.03"},
		{"speaker": "mei", "text": "dlg.c5_mahjong.04"},
		{"speaker": "", "text": "dlg.c5_mahjong.05"},
		{"speaker": "tsang", "text": "dlg.c5_mahjong.06"},
		{"speaker": "", "text": "dlg.c5_mahjong.07", "event": "tileInTin"},
	],
	"c5_mahjong_after": [
		{"speaker": "tsang", "text": "dlg.c5_mahjong_after.01"},
	],
	"c5_kwok": [
		{"speaker": "kwok", "text": "dlg.c5_kwok.01"},
		{"speaker": "kwok", "text": "dlg.c5_kwok.02"},
	],
	"c5_fong": [
		{"speaker": "", "text": "dlg.c5_fong.01"},
		{"speaker": "", "text": "dlg.c5_fong.02", "event": "stoolDown"},
	],
	"c5_fong_again": [
		{"speaker": "", "text": "dlg.c5_fong_again.01"},
	],
	"c5_wong": [
		{"speaker": "", "text": "dlg.c5_wong.01"},
		{"speaker": "", "text": "dlg.c5_wong.02"},
		{"speaker": "", "text": "dlg.c5_wong.03"},
		{"speaker": "", "text": "dlg.c5_wong.04", "event": "bowlDown"},
	],
	"c5_wong_again": [
		{"speaker": "", "text": "dlg.c5_wong_again.01"},
	],
	"c5_note": [
		{"speaker": "mei", "text": "dlg.c5_note.01"},
		{"speaker": "", "text": "dlg.c5_note.02", "event": "paper"},
		{"speaker": "wong", "text": "dlg.c5_note.03"},
		{"speaker": "wong", "text": "dlg.c5_note.04"},
		{"speaker": "wong", "text": "dlg.c5_note.05"},
		{"speaker": "wong", "text": "dlg.c5_note.06"},
		{"speaker": "wong", "text": "dlg.c5_note.07"},
		{"speaker": "", "text": "dlg.c5_note.08"},
		{"speaker": "grandfather", "text": "dlg.c5_note.09"},
		{"speaker": "mei", "text": "dlg.c5_note.10"},
		{"speaker": "grandfather", "text": "dlg.c5_note.11"},
		{"speaker": "mei", "text": "dlg.c5_note.12"},
		{"speaker": "grandfather", "text": "dlg.c5_note.13"},
		{"speaker": "", "text": "dlg.c5_note.14"},
	],
	"c5_stair": [
		{"speaker": "", "text": "dlg.c5_stair.01"},
	],
	"c5_argument": [
		{"speaker": "", "text": "dlg.c5_argument.01"},
		{"speaker": "mei", "text": "dlg.c5_argument.02"},
		{"speaker": "mum", "text": "dlg.c5_argument.03"},
		{"speaker": "mei", "text": "dlg.c5_argument.04"},
		{"speaker": "mum", "text": "dlg.c5_argument.05"},
		{"speaker": "mei", "text": "dlg.c5_argument.06"},
		{"speaker": "mum", "text": "dlg.c5_argument.07"},
		{"speaker": "mei", "text": "dlg.c5_argument.08"},
		{"speaker": "mum", "text": "dlg.c5_argument.09"},
		{"speaker": "mei", "text": "dlg.c5_argument.10"},
		{"speaker": "mum", "text": "dlg.c5_argument.11"},
		{"speaker": "mei", "text": "dlg.c5_argument.12"},
		{"speaker": "mum", "text": "dlg.c5_argument.13"},
		{"speaker": "mei", "text": "dlg.c5_argument.14"},
		{"speaker": "mum", "text": "dlg.c5_argument.15"},
		{"speaker": "mei", "text": "dlg.c5_argument.16"},
		{"speaker": "mum", "text": "dlg.c5_argument.17"},
		{"speaker": "", "text": "dlg.c5_argument.18"},
		{"speaker": "", "text": "dlg.c5_argument.19", "event": "mumSits"},
		{"speaker": "mum", "text": "dlg.c5_argument.20"},
	],
	"c5_leung": [
		{"speaker": "leung", "text": "dlg.c5_leung.01"},
		{"speaker": "mei", "text": "dlg.c5_leung.02"},
		{"speaker": "leung", "text": "dlg.c5_leung.03"},
		{"speaker": "mei", "text": "dlg.c5_leung.04"},
		{"speaker": "leung", "text": "dlg.c5_leung.05"},
		{"speaker": "mei", "text": "dlg.c5_leung.06"},
		{"speaker": "leung", "text": "dlg.c5_leung.07"},
		{"speaker": "leung", "text": "dlg.c5_leung.08"},
	],
	"c5_leung_wait": [
		{"speaker": "leung", "text": "dlg.c5_leung_wait.01"},
	],
	"c5_kwok_note": [
		{"speaker": "mei", "text": "dlg.c5_kwok_note.01"},
		{"speaker": "kwok", "text": "dlg.c5_kwok_note.02"},
		{"speaker": "mei", "text": "dlg.c5_kwok_note.03"},
		{"speaker": "kwok", "text": "dlg.c5_kwok_note.04"},
		{"speaker": "kwok", "text": "dlg.c5_kwok_note.05"},
	],
	"c5_kwok_packing": [
		{"speaker": "kwok", "text": "dlg.c5_kwok_packing.01"},
	],
	"c5_under_shutter": [
		{"speaker": "", "text": "dlg.c5_under_shutter.01"},
		{"speaker": "", "text": "dlg.c5_under_shutter.02", "event": "noteTaken"},
	],
	"c5_leung_done": [
		{"speaker": "mei", "text": "dlg.c5_leung_done.01"},
		{"speaker": "leung", "text": "dlg.c5_leung_done.02"},
		{"speaker": "leung", "text": "dlg.c5_leung_done.03"},
		{"speaker": "mei", "text": "dlg.c5_leung_done.04"},
		{"speaker": "leung", "text": "dlg.c5_leung_done.05"},
	],
	"c5_leung_after": [
		{"speaker": "leung", "text": "dlg.c5_leung_after.01"},
	],
	"c4_fan_stops": [
		{"speaker": "", "text": "dlg.c4_fan_stops.01"},
		{"speaker": "cheung", "text": "dlg.c4_fan_stops.02"},
		{"speaker": "cheung", "text": "dlg.c4_fan_stops.03"},
	],
	"c4_cheung_fan_wait": [
		{"speaker": "cheung", "text": "dlg.c4_cheung_fan_wait.01"},
	],
	"c4_ho_fan": [
		{"speaker": "mei", "text": "dlg.c4_ho_fan.01"},
		{"speaker": "ho", "text": "dlg.c4_ho_fan.02"},
		{"speaker": "ho", "text": "dlg.c4_ho_fan.03"},
		{"speaker": "ho", "text": "dlg.c4_ho_fan.04"},
	],
	"c4_cords": [
		{"speaker": "", "text": "dlg.c4_cords.01"},
	],
	"c4_plug": [
		{"speaker": "", "text": "dlg.c4_plug.01"},
		{"speaker": "", "text": "dlg.c4_plug.02", "event": "fanOn"},
	],
	"c4_fan_back": [
		{"speaker": "cheung", "text": "dlg.c4_fan_back.01"},
		{"speaker": "mei", "text": "dlg.c4_fan_back.02"},
		{"speaker": "cheung", "text": "dlg.c4_fan_back.03"},
	],
	"c4_fong": [
		{"speaker": "fong", "text": "dlg.c4_fong.01"},
		{"speaker": "mei", "text": "dlg.c4_fong.02"},
		{"speaker": "fong", "text": "dlg.c4_fong.03"},
		{"speaker": "fong", "text": "dlg.c4_fong.04"},
		{"speaker": "fong", "text": "dlg.c4_fong.05"},
		{"speaker": "fong", "text": "dlg.c4_fong.06"},
		{"speaker": "mei", "text": "dlg.c4_fong.07"},
		{"speaker": "fong", "text": "dlg.c4_fong.08"},
	],
	"c4_fong_wait": [
		{"speaker": "fong", "text": "dlg.c4_fong_wait.01"},
	],
	"c4_fong_bolt_first": [
		{"speaker": "", "text": "dlg.c4_fong_bolt_first.01"},
	],
	"c4_fong_bolt_last": [
		{"speaker": "", "text": "dlg.c4_fong_bolt_last.01"},
	],
	"c4_fong_slot": [
		{"speaker": "", "text": "dlg.c4_fong_slot.01"},
	],
	"c4_ladder_seen": [
		{"speaker": "", "text": "dlg.c4_ladder_seen.01"},
	],
	"c4_fong_done": [
		{"speaker": "mei", "text": "dlg.c4_fong_done.01"},
		{"speaker": "fong", "text": "dlg.c4_fong_done.02"},
		{"speaker": "mei", "text": "dlg.c4_fong_done.03"},
		{"speaker": "fong", "text": "dlg.c4_fong_done.04"},
		{"speaker": "fong", "text": "dlg.c4_fong_done.05"},
	],
	"c4_fong_after": [
		{"speaker": "fong", "text": "dlg.c4_fong_after.01"},
	],
	"c2_kwok_page": [
		{"speaker": "kwok", "text": "dlg.c2_kwok_page.01"},
		{"speaker": "mei", "text": "dlg.c2_kwok_page.02"},
		{"speaker": "kwok", "text": "dlg.c2_kwok_page.03"},
		{"speaker": "kwok", "text": "dlg.c2_kwok_page.04"},
	],
	"c2_kwok_page_wait": [
		{"speaker": "kwok", "text": "dlg.c2_kwok_page_wait.01"},
	],
	"c2_page_awning": [
		{"speaker": "", "text": "dlg.c2_page_awning.01"},
	],
	"c2_page_seen": [
		{"speaker": "", "text": "dlg.c2_page_seen.01"},
	],
	"c2_page_got": [
		{"speaker": "", "text": "dlg.c2_page_got.01"},
	],
	"c2_kwok_page_back": [
		{"speaker": "kwok", "text": "dlg.c2_kwok_page_back.01"},
		{"speaker": "mei", "text": "dlg.c2_kwok_page_back.02"},
		{"speaker": "kwok", "text": "dlg.c2_kwok_page_back.03"},
		{"speaker": "mei", "text": "dlg.c2_kwok_page_back.04"},
		{"speaker": "kwok", "text": "dlg.c2_kwok_page_back.05"},
	],
	"c2_kwok_after": [
		{"speaker": "kwok", "text": "dlg.c2_kwok_after.01"},
	],
	"c2_tile_lost": [
		{"speaker": "tsang", "text": "dlg.c2_tile_lost.01"},
		{"speaker": "yip", "text": "dlg.c2_tile_lost.02"},
		{"speaker": "tsang", "text": "dlg.c2_tile_lost.03"},
		{"speaker": "", "text": "dlg.c2_tile_lost.04"},
		{"speaker": "tsang", "text": "dlg.c2_tile_lost.05"},
	],
	"c2_tile_wait": [
		{"speaker": "tsang", "text": "dlg.c2_tile_wait.01"},
	],
	"c2_tile_crack": [
		{"speaker": "", "text": "dlg.c2_tile_crack.01"},
	],
	"c2_tile_seen": [
		{"speaker": "", "text": "dlg.c2_tile_seen.01"},
	],
	"c2_tile_got": [
		{"speaker": "", "text": "dlg.c2_tile_got.01"},
	],
	"c2_tile_back": [
		{"speaker": "mei", "text": "dlg.c2_tile_back.01"},
		{"speaker": "tsang", "text": "dlg.c2_tile_back.02"},
		{"speaker": "mei", "text": "dlg.c2_tile_back.03"},
		{"speaker": "tsang", "text": "dlg.c2_tile_back.04"},
		{"speaker": "yip", "text": "dlg.c2_tile_back.05"},
		{"speaker": "tsang", "text": "dlg.c2_tile_back.06"},
		{"speaker": "", "text": "dlg.c2_tile_back.07"},
	],
	"c2_tile_after": [
		{"speaker": "tsang", "text": "dlg.c2_tile_after.01"},
	],
	"c3_wai_shortcut": [
		{"speaker": "wai", "text": "dlg.c3_wai_shortcut.01"},
		{"speaker": "mei", "text": "dlg.c3_wai_shortcut.02"},
		{"speaker": "wai", "text": "dlg.c3_wai_shortcut.03"},
		{"speaker": "mei", "text": "dlg.c3_wai_shortcut.04"},
		{"speaker": "wai", "text": "dlg.c3_wai_shortcut.05"},
	],
	"c3_wai_waiting": [
		{"speaker": "wai", "text": "dlg.c3_wai_waiting.01"},
	],
	"c3_short_stair": [
		{"speaker": "", "text": "dlg.c3_short_stair.01"},
	],
	"c3_short_ladder": [
		{"speaker": "", "text": "dlg.c3_short_ladder.01"},
	],
	"c3_short_bridge": [
		{"speaker": "", "text": "dlg.c3_short_bridge.01"},
	],
	"c3_wai_race": [
		{"speaker": "wai", "text": "dlg.c3_wai_race.01"},
		{"speaker": "mei", "text": "dlg.c3_wai_race.02"},
		{"speaker": "wai", "text": "dlg.c3_wai_race.03"},
		{"speaker": "mei", "text": "dlg.c3_wai_race.04"},
		{"speaker": "wai", "text": "dlg.c3_wai_race.05"},
	],
	"c3_wai_race_after": [
		{"speaker": "wai", "text": "dlg.c3_wai_race_after.01"},
	],
	"c6_open": [
		{"speaker": "", "text": "dlg.c6_open.01"},
		{"speaker": "mum", "text": "dlg.c6_open.02"},
	],
	"c6_ng_packing": [
		{"speaker": "ng", "text": "dlg.c6_ng_packing.01"},
		{"speaker": "mei", "text": "dlg.c6_ng_packing.02"},
		{"speaker": "ng", "text": "dlg.c6_ng_packing.03"},
		{"speaker": "mei", "text": "dlg.c6_ng_packing.04"},
		{"speaker": "ng", "text": "dlg.c6_ng_packing.05"},
	],
	"c6_ng_photo": [
		{"speaker": "ng", "text": "dlg.c6_ng_photo.01"},
	],
	"c6_pigeon_escapes": [
		{"speaker": "", "text": "dlg.c6_pigeon_escapes.01"},
		{"speaker": "ng", "text": "dlg.c6_pigeon_escapes.02"},
	],
	"c6_wong_card": [
		{"speaker": "mum", "text": "dlg.c6_wong_card.01"},
		{"speaker": "", "text": "dlg.c6_wong_card.02"},
		{"speaker": "mei", "text": "dlg.c6_wong_card.03"},
		{"speaker": "grandfather", "text": "dlg.c6_wong_card.04"},
		{"speaker": "", "text": "dlg.c6_wong_card.05"},
	],
	"c6_lights_fail": [
		{"speaker": "", "text": "dlg.c6_lights_fail.01"},
		{"speaker": "kwok", "text": "dlg.c6_lights_fail.02"},
		{"speaker": "ho", "text": "dlg.c6_lights_fail.03"},
		{"speaker": "grandfather", "text": "dlg.c6_lights_fail.04"},
		{"speaker": "ho", "text": "dlg.c6_lights_fail.05"},
		{"speaker": "grandfather", "text": "dlg.c6_lights_fail.06"},
		{"speaker": "ho", "text": "dlg.c6_lights_fail.07"},
		{"speaker": "", "text": "dlg.c6_lights_fail.08"},
		{"speaker": "ho", "text": "dlg.c6_lights_fail.09"},
		{"speaker": "mei", "text": "dlg.c6_lights_fail.10"},
		{"speaker": "ho", "text": "dlg.c6_lights_fail.11"},
	],
	"c6_hut_lead": [
		{"speaker": "", "text": "dlg.c6_hut_lead.01"},
	],
	"c6_hut_through": [
		{"speaker": "", "text": "dlg.c6_hut_through.01"},
	],
	"c6_leads_tangle": [
		{"speaker": "", "text": "dlg.c6_leads_tangle.01"},
	],
	"c6_leads_seen": [
		{"speaker": "", "text": "dlg.c6_leads_seen.01"},
	],
	"c6_board_wrong": [
		{"speaker": "ho", "text": "dlg.c6_board_wrong.01"},
	],
	"c6_board_mast": [
		{"speaker": "", "text": "dlg.c6_board_mast.01"},
	],
	"c6_tank_loop": [
		{"speaker": "", "text": "dlg.c6_tank_loop.01"},
	],
	"c6_lights_on": [
		{"speaker": "", "text": "dlg.c6_lights_on.01"},
		{"speaker": "grandfather", "text": "dlg.c6_lights_on.02"},
		{"speaker": "kit", "text": "dlg.c6_lights_on.03"},
		{"speaker": "ho", "text": "dlg.c6_lights_on.04"},
	],
	"c6_ng_talk": [
		{"speaker": "mei", "text": "dlg.c6_ng_talk.01"},
		{"speaker": "ng", "text": "dlg.c6_ng_talk.02"},
		{"speaker": "mei", "text": "dlg.c6_ng_talk.03"},
		{"speaker": "ng", "text": "dlg.c6_ng_talk.04"},
		{"speaker": "", "text": "dlg.c6_ng_talk.05"},
		{"speaker": "ng", "text": "dlg.c6_ng_talk.06"},
	],
	"c6_ho_talk": [
		{"speaker": "ho", "text": "dlg.c6_ho_talk.01"},
		{"speaker": "mei", "text": "dlg.c6_ho_talk.02"},
		{"speaker": "ho", "text": "dlg.c6_ho_talk.03"},
		{"speaker": "mei", "text": "dlg.c6_ho_talk.04"},
		{"speaker": "ho", "text": "dlg.c6_ho_talk.05"},
	],
	"c6_mum_grandfather": [
		{"speaker": "mum", "text": "dlg.c6_mum_grandfather.01"},
		{"speaker": "grandfather", "text": "dlg.c6_mum_grandfather.02"},
		{"speaker": "mum", "text": "dlg.c6_mum_grandfather.03"},
		{"speaker": "grandfather", "text": "dlg.c6_mum_grandfather.04"},
		{"speaker": "mum", "text": "dlg.c6_mum_grandfather.05"},
		{"speaker": "grandfather", "text": "dlg.c6_mum_grandfather.06"},
	],
	"c6_mei_mum": [
		{"speaker": "mei", "text": "dlg.c6_mei_mum.01"},
		{"speaker": "mum", "text": "dlg.c6_mei_mum.02"},
		{"speaker": "", "text": "dlg.c6_mei_mum.03"},
		{"speaker": "mei", "text": "dlg.c6_mei_mum.04"},
		{"speaker": "mum", "text": "dlg.c6_mei_mum.05"},
		{"speaker": "", "text": "dlg.c6_mei_mum.06"},
		{"speaker": "mum", "text": "dlg.c6_mei_mum.07"},
	],
	"c6_kit_talk": [
		{"speaker": "kit", "text": "dlg.c6_kit_talk.01"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.02"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.03"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.04"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.05"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.06"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.07"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.08"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.09"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.10"},
		{"speaker": "", "text": "dlg.c6_kit_talk.11"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.12"},
		{"speaker": "mei", "text": "dlg.c6_kit_talk.13"},
		{"speaker": "kit", "text": "dlg.c6_kit_talk.14"},
	],
	"c6_kwok_talk": [
		{"speaker": "kwok", "text": "dlg.c6_kwok_talk.01"},
		{"speaker": "mei", "text": "dlg.c6_kwok_talk.02"},
		{"speaker": "kwok", "text": "dlg.c6_kwok_talk.03"},
		{"speaker": "mei", "text": "dlg.c6_kwok_talk.04"},
		{"speaker": "kwok", "text": "dlg.c6_kwok_talk.05"},
	],
	"c6_ng_after": [
		{"speaker": "ng", "text": "dlg.c6_ng_after.01"},
	],
	"c6_ho_after": [
		{"speaker": "ho", "text": "dlg.c6_ho_after.01"},
	],
	"c6_mum_after": [
		{"speaker": "mum", "text": "dlg.c6_mum_after.01"},
	],
	"c6_kit_after": [
		{"speaker": "kit", "text": "dlg.c6_kit_after.01"},
	],
	"c6_kwok_after": [
		{"speaker": "kwok", "text": "dlg.c6_kwok_after.01"},
	],
	"c6_grandfather_idle": [
		{"speaker": "grandfather", "text": "dlg.c6_grandfather_idle.01"},
	],
	"c6_dark": [
		{"speaker": "grandfather", "text": "dlg.c6_dark.01"},
	],
	"c6_old_photo": [
		{"speaker": "", "text": "dlg.c6_old_photo.01"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.02"},
		{"speaker": "grandfather", "text": "dlg.c6_old_photo.03"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.04"},
		{"speaker": "", "text": "dlg.c6_old_photo.05"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.06"},
		{"speaker": "", "text": "dlg.c6_old_photo.07"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.08"},
		{"speaker": "grandfather", "text": "dlg.c6_old_photo.09"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.10"},
		{"speaker": "grandfather", "text": "dlg.c6_old_photo.11"},
		{"speaker": "mei", "text": "dlg.c6_old_photo.12"},
		{"speaker": "grandfather", "text": "dlg.c6_old_photo.13"},
	],
	"c6_leaving": [
		{"speaker": "ho", "text": "dlg.c6_leaving.01"},
		{"speaker": "kwok", "text": "dlg.c6_leaving.02"},
		{"speaker": "ng", "text": "dlg.c6_leaving.03"},
		{"speaker": "", "text": "dlg.c6_leaving.04"},
		{"speaker": "kit", "text": "dlg.c6_leaving.05"},
	],
	"c6_pigeon_found": [
		{"speaker": "", "text": "dlg.c6_pigeon_found.01"},
	],
	"c6_pigeon_back": [
		{"speaker": "", "text": "dlg.c6_pigeon_back.01"},
	],
	"c6_ng_pigeon_back": [
		{"speaker": "ng", "text": "dlg.c6_ng_pigeon_back.01"},
		{"speaker": "mei", "text": "dlg.c6_ng_pigeon_back.02"},
		{"speaker": "ng", "text": "dlg.c6_ng_pigeon_back.03"},
	],
	"c6_ho_wait": [
		{"speaker": "ho", "text": "dlg.c6_ho_wait.01"},
	],
}


static func lines(id: String) -> Array:
	return LINES.get(id, [])
