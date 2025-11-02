extends CanvasLayer

signal bet_selected(bet_amount: int)
signal bet_cancelled

@onready var bet_slider: HSlider = $Panel/VBoxContainer/BetSlider
@onready var bet_label: Label = $Panel/VBoxContainer/BetAmountLabel
@onready var chips_label: Label = $Panel/VBoxContainer/ChipsLabel
@onready var confirm_button: Button = $Panel/VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $Panel/VBoxContainer/HBoxContainer/CancelButton
@onready var min_bet_button: Button = $Panel/VBoxContainer/QuickBets/MinButton
@onready var quarter_button: Button = $Panel/VBoxContainer/QuickBets/QuarterButton
@onready var half_button: Button = $Panel/VBoxContainer/QuickBets/HalfButton
@onready var max_bet_button: Button = $Panel/VBoxContainer/QuickBets/MaxButton

var current_chips: int = 0
var min_bet: int = 10
var max_bet: int = 1000

func _ready() -> void:
	hide()

	# Connect button signals
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if min_bet_button:
		min_bet_button.pressed.connect(_on_min_bet_pressed)
	if quarter_button:
		quarter_button.pressed.connect(_on_quarter_pressed)
	if half_button:
		half_button.pressed.connect(_on_half_pressed)
	if max_bet_button:
		max_bet_button.pressed.connect(_on_max_bet_pressed)

	# Connect slider signal
	if bet_slider:
		bet_slider.value_changed.connect(_on_bet_slider_changed)

func show_dialog(chips: int, minimum_bet: int, maximum_bet: int) -> void:
	current_chips = chips
	min_bet = minimum_bet
	max_bet = min(maximum_bet, chips)  # Can't bet more than you have

	# Setup slider
	if bet_slider:
		bet_slider.min_value = min_bet
		bet_slider.max_value = max_bet
		bet_slider.step = 10
		bet_slider.value = min_bet

	# Update labels
	_update_labels()
	show()

func _update_labels() -> void:
	if bet_label and bet_slider:
		bet_label.text = "Bet Amount: %d" % int(bet_slider.value)
	if chips_label:
		chips_label.text = "Available Chips: %d" % current_chips

func _on_bet_slider_changed(value: float) -> void:
	_update_labels()

func _on_confirm_pressed() -> void:
	if bet_slider:
		var bet_amount = int(bet_slider.value)
		if bet_amount >= min_bet and bet_amount <= max_bet and bet_amount <= current_chips:
			bet_selected.emit(bet_amount)
			hide()

func _on_cancel_pressed() -> void:
	bet_cancelled.emit()
	hide()

func _on_min_bet_pressed() -> void:
	if bet_slider:
		bet_slider.value = min_bet

func _on_quarter_pressed() -> void:
	if bet_slider:
		var quarter_chips = int(current_chips * 0.25)
		bet_slider.value = clamp(quarter_chips - (quarter_chips % 10), min_bet, max_bet)

func _on_half_pressed() -> void:
	if bet_slider:
		var half_chips = int(current_chips * 0.5)
		bet_slider.value = clamp(half_chips - (half_chips % 10), min_bet, max_bet)

func _on_max_bet_pressed() -> void:
	if bet_slider:
		bet_slider.value = max_bet
