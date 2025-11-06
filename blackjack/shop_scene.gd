extends Control

## Shop Scene
## Displayed when player gets kicked out or wants to upgrade between runs

@onready var game_state: Node = get_node("/root/GameStateManager")
@onready var chips_label: Label = %ChipsLabel
@onready var title_label: Label = %TitleLabel
@onready var flavor_text: Label = %FlavorText
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var return_button: Button = %ReturnButton
@onready var stats_label: Label = %StatsLabel

func _ready() -> void:
	if game_state:
		game_state.chips_changed.connect(_on_chips_changed)
		game_state.upgrade_purchased.connect(_on_upgrade_purchased)

	setup_ui()
	populate_upgrades()
	update_chips_display()
	update_stats_display()

func setup_ui() -> void:
	"""Setup the shop UI"""
	title_label.text = "Back Alley Shop"
	flavor_text.text = "You got roughed up pretty good. Maybe buy something to help next time?"
	return_button.text = "Return to Casino"
	return_button.pressed.connect(_on_return_to_casino)

func populate_upgrades() -> void:
	"""Create upgrade buttons for all available upgrades"""
	if not game_state:
		return

	# Clear existing buttons
	for child in upgrades_container.get_children():
		child.queue_free()

	# Create upgrade buttons
	for upgrade_id in game_state.available_upgrades.keys():
		var upgrade_data = game_state.available_upgrades[upgrade_id]
		create_upgrade_button(upgrade_id, upgrade_data)

func create_upgrade_button(upgrade_id: String, upgrade_data: Dictionary) -> void:
	"""Create a button for an upgrade"""
	# Create container for this upgrade
	var upgrade_panel = PanelContainer.new()
	upgrade_panel.custom_minimum_size = Vector2(0, 80)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	upgrade_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	margin.add_child(hbox)

	# Left side: info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Upgrade name with level
	var current_level = game_state.get_upgrade_level(upgrade_id)
	var max_level = upgrade_data.max_level
	var name_label = Label.new()
	name_label.text = "%s [%d/%d]" % [upgrade_data.name, current_level, max_level]
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)

	# Requirements (if any)
	if upgrade_data.has("requires"):
		var req_upgrade = game_state.available_upgrades[upgrade_data.requires]
		var has_req = game_state.purchased_upgrades.has(upgrade_data.requires)
		var req_label = Label.new()
		req_label.text = "Requires: " + req_upgrade.name
		req_label.add_theme_font_size_override("font_size", 12)
		req_label.modulate = Color.YELLOW if not has_req else Color.GREEN
		info_vbox.add_child(req_label)

	# Right side: purchase button
	var button = Button.new()
	button.text = "Buy\n%d Chips" % upgrade_data.cost
	button.custom_minimum_size = Vector2(100, 0)
	button.pressed.connect(_on_purchase_upgrade.bind(upgrade_id))
	hbox.add_child(button)

	# Update button state
	var can_purchase = game_state.can_purchase_upgrade(upgrade_id)
	button.disabled = not can_purchase

	if current_level >= max_level:
		button.text = "MAX"
		button.disabled = true

	upgrades_container.add_child(upgrade_panel)

func _on_purchase_upgrade(upgrade_id: String) -> void:
	"""Handle upgrade purchase"""
	if game_state and game_state.purchase_upgrade(upgrade_id):
		# Refresh the upgrade list
		populate_upgrades()
		update_chips_display()

func _on_chips_changed(new_amount: int) -> void:
	"""Update display when chips change"""
	update_chips_display()

func _on_upgrade_purchased(upgrade_id: String) -> void:
	"""Handle upgrade purchased"""
	# Refresh to update all button states
	populate_upgrades()

func update_chips_display() -> void:
	"""Update the chips display"""
	if game_state and chips_label:
		chips_label.text = "Chips: %d" % game_state.persistent_chips

func update_stats_display() -> void:
	"""Update stats display"""
	if game_state and stats_label:
		stats_label.text = "Runs Completed: %d | Total Earned: %d chips" % [
			game_state.runs_completed,
			game_state.total_chips_earned
		]

func _on_return_to_casino() -> void:
	"""Return to the casino for another run"""
	if game_state:
		game_state.start_new_run()

	# Load the casino scene
	get_tree().change_scene_to_file("res://blackjack/rougelike_blackjack.tscn")
