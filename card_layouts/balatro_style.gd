extends CardLayout

@onready var card_color: PanelContainer = %CardColor
@onready var texture_rect: TextureRect = %TextureRect
@onready var top_value_label: Label = %TopValueLabel
@onready var bottom_value_label: Label = %BottomValueLabel

var res: StandardStyleRes

func _update_display() -> void:
	res = card_resource as StandardStyleRes
	#set_color()
	texture_rect.texture = res.top_texture
	set_value()

func set_color():
	var style := StyleBoxFlat.new()
	var border_w := 4
	match res.current_modiffier:
		res.modiffier.NONE:
			style.bg_color = Color.WHITE
			style.border_color = Color.BLACK
		res.modiffier.GOLD:
			card_color.self_modulate = Color.GOLD
			style.border_color = Color.BLACK
		res.modiffier.STEEL:
			card_color.self_modulate = Color.LIGHT_STEEL_BLUE
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
