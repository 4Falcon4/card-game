extends CardLayout

@onready var card_color: PanelContainer = %CardColor
@onready var texture_rect: TextureRect = %TextureRect

var res: StandardStyleRes

func _update_display() -> void:
	res = card_resource as StandardStyleRes
	set_color()
	texture_rect.texture = res.bottom_texture

func set_color():
		var style := StyleBoxFlat.new()
		var border_w := 4
		match res.deck_color:
			res.deck_colors.NONE:
				style.bg_color = Color.TRANSPARENT
			res.deck_colors.LIGHT:
				style.bg_color = Color.BURLYWOOD
				style.border_color = Color.DARK_SLATE_GRAY
			res.deck_colors.DARK:
				style.bg_color = Color.DARK_SLATE_GRAY
				style.border_color = Color.BURLYWOOD
			res.deck_colors.WHITE:
				style.bg_color = Color.WHITE
				style.border_color = Color.DARK_SLATE_GRAY
			res.deck_colors.BLACK:
				style.bg_color = Color.BLACK
				style.border_color = Color.BURLYWOOD
	
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
