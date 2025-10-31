extends CardLayout

@onready var card_color: PanelContainer = %CardColor
@onready var texture_rect: TextureRect = %TextureRect
@onready var top_value_label: Label = %TopValueLabel
@onready var bottom_value_label: Label = %BottomValueLabel

var res

func _update_display() -> void:
	res = card_resource
	texture_rect.texture = res.top_texture
	set_value()

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
