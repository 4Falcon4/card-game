@tool
extends Node

## Global Game State Manager
## Manages persistent state across runs, upgrades, and level progression

signal chips_changed(new_amount: int)
signal upgrade_purchased(upgrade_id: String)
signal level_unlocked(level: int)

## Editor-only button to delete save data
@export var delete_save_data: bool = false:
	set(value):
		if value and (Engine.is_editor_hint() or OS.has_feature("editor")):
			_editor_delete_save_data()
		delete_save_data = false

## Persistent state
var persistent_chips: int = 1000  ## Chips that persist between runs
var current_run_chips: int = 1000  ## Chips for current casino run
var purchased_upgrades: Array[String] = []  ## List of purchased upgrade IDs
var current_level: int = 1  ## Current level/difficulty
var highest_level_unlocked: int = 1  ## Highest level unlocked
var runs_completed: int = 0  ## Total successful runs
var total_chips_earned: int = 0  ## Lifetime chips earned

## Run statistics
var current_run_rounds: int = 0
var current_run_wins: int = 0
var current_run_losses: int = 0

## Upgrade definitions
var available_upgrades: Dictionary = {
	"starting_chips_100": {
		"name": "Extra Starting Chips I",
		"description": "Start each run with +250 chips",
		"cost": 500,
		"effect": "starting_chips",
		"value": 250,
		"max_level": 5
	},
	"starting_chips_250": {
		"name": "Extra Starting Chips II",
		"description": "Start each run with +750 chips",
		"cost": 1500,
		"effect": "starting_chips",
		"value": 750,
		"max_level": 3,
		"requires": "starting_chips_100"
	},
	"payment_delay": {
		"name": "Smooth Talker",
		"description": "+1 round before payment is due",
		"cost": 800,
		"effect": "payment_rounds",
		"value": 1,
		"max_level": 3
	},
	"payment_reduction": {
		"name": "Good Negotiator",
		"description": "Reduce payment amounts by 20%",
		"cost": 1000,
		"effect": "payment_reduction",
		"value": 0.2,
		"max_level": 2
	},
	"better_odds": {
		"name": "Card Counter",
		"description": "Slightly better card odds",
		"cost": 2000,
		"effect": "better_odds",
		"value": 1,
		"max_level": 1
	},
	"ability_boost": {
		"name": "Ability Master",
		"description": "Card abilities are 25% more effective",
		"cost": 1200,
		"effect": "ability_boost",
		"value": 0.25,
		"max_level": 3
	},
	"double_down_discount": {
		"name": "Bold Gambler",
		"description": "Double down costs 50% less",
		"cost": 900,
		"effect": "double_discount",
		"value": 0.5,
		"max_level": 1
	}
}

func _ready() -> void:
	load_game_state()


func _input(event):
	if Input.is_action_just_pressed("Delete Save Data"):
		_editor_delete_save_data()
	
	
func _editor_delete_save_data() -> void:
	"""Editor-only function to delete save data"""
	if not (Engine.is_editor_hint() or OS.has_feature("editor")):
		print("This function can only be used in the editor.")
		return

	# Delete the save file
	reset_all_progress()
	if FileAccess.file_exists("user://casino_save.dat"):
		DirAccess.remove_absolute("user://casino_save.dat")
		print("Save data deleted successfully!")
	else:
		print("No save data found to delete.")

	# Reset all variables to defaults
	persistent_chips = 1000
	current_run_chips = 1000
	purchased_upgrades = []
	current_level = 1
	highest_level_unlocked = 1
	runs_completed = 0
	total_chips_earned = 0
	current_run_rounds = 0
	current_run_wins = 0
	current_run_losses = 0

	print("Game state reset to defaults.")
	
func start_new_run() -> void:
	"""Start a new casino run"""
	# Calculate starting chips with upgrades
	var starting_chips = 1000
	starting_chips += get_total_upgrade_value("starting_chips")

	current_run_chips = starting_chips
	current_run_rounds = 0
	current_run_wins = 0
	current_run_losses = 0
	chips_changed.emit(current_run_chips)

func end_run(success: bool, final_chips: int) -> void:
	"""End current run and return to shop"""
	if success:
		runs_completed += 1

	# Add chips to persistent pool
	persistent_chips += final_chips
	total_chips_earned += final_chips
	chips_changed.emit(persistent_chips)

	save_game_state()

func update_run_chips(new_amount: int) -> void:
	"""Update chips during a run"""
	current_run_chips = new_amount
	chips_changed.emit(current_run_chips)

func can_purchase_upgrade(upgrade_id: String) -> bool:
	"""Check if player can afford and meets requirements for upgrade"""
	if not available_upgrades.has(upgrade_id):
		return false

	var upgrade = available_upgrades[upgrade_id]

	# Check cost
	if persistent_chips < upgrade.cost:
		return false

	# Check if already purchased max times
	var purchase_count = purchased_upgrades.count(upgrade_id)
	if purchase_count >= upgrade.max_level:
		return false

	# Check requirements
	if upgrade.has("requires"):
		if not purchased_upgrades.has(upgrade.requires):
			return false

	return true

func purchase_upgrade(upgrade_id: String) -> bool:
	"""Purchase an upgrade"""
	if not can_purchase_upgrade(upgrade_id):
		return false

	var upgrade = available_upgrades[upgrade_id]
	persistent_chips -= upgrade.cost
	purchased_upgrades.append(upgrade_id)

	chips_changed.emit(persistent_chips)
	upgrade_purchased.emit(upgrade_id)
	save_game_state()

	return true

func get_upgrade_level(upgrade_id: String) -> int:
	"""Get current level of an upgrade"""
	return purchased_upgrades.count(upgrade_id)

func get_total_upgrade_value(effect_type: String) -> int:
	"""Get total value from all upgrades of a specific effect type"""
	var total = 0
	for upgrade_id in purchased_upgrades:
		if available_upgrades.has(upgrade_id):
			var upgrade = available_upgrades[upgrade_id]
			if upgrade.effect == effect_type:
				total += upgrade.value
	return total

func get_upgrade_multiplier(effect_type: String) -> float:
	"""Get multiplier from upgrades (e.g., for payment_reduction)"""
	var total = 0.0
	for upgrade_id in purchased_upgrades:
		if available_upgrades.has(upgrade_id):
			var upgrade = available_upgrades[upgrade_id]
			if upgrade.effect == effect_type:
				total += upgrade.value
	return total

func unlock_level(level: int) -> void:
	"""Unlock a new level"""
	if level > highest_level_unlocked:
		highest_level_unlocked = level
		level_unlocked.emit(level)
		save_game_state()

func set_current_level(level: int) -> void:
	"""Set the current level to play"""
	if level <= highest_level_unlocked:
		current_level = level

func save_game_state() -> void:
	"""Save persistent game state"""
	var save_data = {
		"persistent_chips": persistent_chips,
		"purchased_upgrades": purchased_upgrades,
		"current_level": current_level,
		"highest_level_unlocked": highest_level_unlocked,
		"runs_completed": runs_completed,
		"total_chips_earned": total_chips_earned
	}

	var save_file = FileAccess.open("user://casino_save.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()

func load_game_state() -> void:
	"""Load persistent game state"""
	if not FileAccess.file_exists("user://casino_save.dat"):
		return

	var save_file = FileAccess.open("user://casino_save.dat", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()

		if save_data is Dictionary:
			persistent_chips = save_data.get("persistent_chips", 1000)
			purchased_upgrades = save_data.get("purchased_upgrades", [])
			current_level = save_data.get("current_level", 1)
			highest_level_unlocked = save_data.get("highest_level_unlocked", 1)
			runs_completed = save_data.get("runs_completed", 0)
			total_chips_earned = save_data.get("total_chips_earned", 0)

func reset_all_progress() -> void:
	"""Reset all progress (for debugging or new game+)"""
	persistent_chips = 1000
	purchased_upgrades = []
	current_level = 1
	highest_level_unlocked = 1
	runs_completed = 0
	total_chips_earned = 0
	save_game_state()
