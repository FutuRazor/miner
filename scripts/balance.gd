extends RefCounted

# Economy unlocks after waves 4/9/14; defense one wave earlier at 3/8/13.
const BUILD_LIMITS := [[2, 3, 4, 5], [1, 2, 3, 4], [2, 4, 6, 8], [1, 1, 1, 1]]
const BUILD_PRICES := [[30, 50, 80, 120, 170], [25, 40, 60, 85], [20, 25, 35, 45, 60, 75, 95, 120], [180]]
const BUILD_SECONDS := [8.0, 10.0, 6.0, 15.0]
const PRICES := {
	"mining_level": [20, 30, 45, 65, 90, 120, 160, 210, 270],
	"collector_drones": [80, 200, 400], "barracks_drones": [60, 140, 260],
	"collector_speed": [25, 45, 75, 120, 180], "collector_capacity": [20, 40, 75, 120],
	"cash_drone": [25, 75], "barracks_health": [30, 55, 90, 140, 210],
	"tower_health": [25, 45, 80, 130], "tower_shots": [100, 250],
	"tower_rate": [40, 70, 110, 170, 250], "base_health": [40, 80, 140, 220],
	"workshop_drones": [200, 350], "workshop_repair": [200, 400], "workshop_speed": [60, 80, 140],
}

static func unlock_waves(defense: bool = false) -> Array:
	return [3, 8, 13] if defense else [4, 9, 14]

static func stage(cleared: int, defense: bool = false) -> int:
	var waves := unlock_waves(defense)
	return int(cleared >= waves[0]) + int(cleared >= waves[1]) + int(cleared >= waves[2])

static func is_defense_skill(id: String) -> bool:
	return id == "base_health" or id.begins_with("barracks_") or id.begins_with("tower_")

static func upgrade_limit(id: String, tier: int) -> int:
	match id:
		"workshop_drones", "workshop_repair": return maxi(0, tier - 1)
		"workshop_speed": return tier
		"mining_level": return 9
		"collector_drones", "barracks_drones": return tier
		"cash_drone": return 1 if tier < 2 else 2
		"tower_shots": return [0, 1, 1, 2][tier]
	return mini(tier + 1 if tier < 3 else 5, PRICES[id].size())
