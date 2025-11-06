extends CardLayout

@onready var card_color: PanelContainer = %CardColor
@onready var texture_rect: TextureRect = %TextureRect
@onready var top_value_label: Label = %TopValueLabel
@onready var bottom_value_label: Label = %BottomValueLabel

var res: StandardStyleRes

func _update_display() -> void:
	res = card_resource as StandardStyleRes
	set_color()
	texture_rect.texture = res.top_texture
	set_value()

func set_color():
	var style := StyleBoxFlat.new()
	var border_w := 4

	# Set background color based on modifiers if they exist
	if res.has("current_modiffier"):
		match res.current_modiffier:
			res.modiffier.NONE:
				style.bg_color = Color.WHITE
			res.modiffier.GOLD:
				card_color.self_modulate = Color.GOLD
			res.modiffier.STEEL:
				card_color.self_modulate = Color.LIGHT_STEEL_BLUE
	else:
		style.bg_color = Color.WHITE

	# Set border color based on rarity
	if res is BlackjackStyleRes:
		var blackjack_res := res as BlackjackStyleRes
		match blackjack_res.rarrity:
			BlackjackStyleRes.Rarrity.NONE:
				style.border_color = Color.BLACK
			BlackjackStyleRes.Rarrity.COMMON:
				style.border_color = Color(0.6, 0.6, 0.6)  # Gray
			BlackjackStyleRes.Rarrity.UNCOMMON:
				style.border_color = Color(0.2, 0.8, 0.2)  # Green
			BlackjackStyleRes.Rarrity.RARE:
				style.border_color = Color(0.2, 0.5, 1.0)  # Blue
			BlackjackStyleRes.Rarrity.EPIC:
				style.border_color = Color(0.7, 0.2, 1.0)  # Purple
			BlackjackStyleRes.Rarrity.LEGENDARY:
				style.border_color = Color(1.0, 0.7, 0.0)  # Gold
			BlackjackStyleRes.Rarrity.MYTHIC:
				style.border_color = Color(1.0, 0.3, 0.7)  # Pink/Magenta
			BlackjackStyleRes.Rarrity.EXOTIC:
				style.border_color = Color(0.0, 0.9, 0.9)  # Cyan
			BlackjackStyleRes.Rarrity.DIVINE:
				style.border_color = Color(1.0, 1.0, 0.3)  # Bright Yellow
			BlackjackStyleRes.Rarrity.GODLY:
				style.border_color = Color(1.0, 1.0, 1.0)  # White
	else:
		style.border_color = Color.BLACK

	style.border_width_top = border_w
	style.border_width_bottom = border_w
	style.border_width_left = border_w
	style.border_width_right = border_w

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	card_color.add_theme_stylebox_override("panel", style)
	card_color.self_modulate = Color(1, 1, 1, 1)

func set_value():
	var text: String = ""
	
	match res.value:
		1:
			text = "A"
		11:
			text = "J"
		12:
			text = "Q"
		13:
			text = "K"
		_:
			text = str(res.value)
	
	top_value_label.text = text
	bottom_value_label.text = text
