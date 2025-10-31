extends CardLayout

@onready var card_color: PanelContainer = %CardColor
@onready var texture_rect: TextureRect = %TextureRect

var res

func _update_display() -> void:
	res = card_resource
	set_color()
	texture_rect.texture = res.bottom_texture

func set_color():
	match res.deck_color:
		res.deck_colors.NONE:
			card_color.self_modulate = Color.TRANSPARENT
		res.deck_colors.LIGHT:
			card_color.self_modulate = Color.BURLYWOOD
		res.deck_colors.DARK:
			card_color.self_modulate = Color.DIM_GRAY
		res.deck_colors.WHITE:
			card_color.self_modulate = Color.WHITE
		res.deck_colors.BLACK:
			card_color.self_modulate = Color.BLACK
