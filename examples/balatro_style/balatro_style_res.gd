class_name BalatroStyleResource extends CardResource

@export var name: String
@export var top_texture: Texture2D
@export var bottom_texture: Texture2D
@export var current_modiffier: modiffier = modiffier.NONE
@export var deck_color: deck_colors = deck_colors.NONE
@export var card_suit: suit = suit.ALL
@export var value: int = 1

enum modiffier {
	NONE,
	GOLD,
	STEEL,
}

enum deck_colors {
	NONE,
	LIGHT,
	DARK,
	WHITE,
	BLACK
}

enum suit{
	CLUBS,
	DIAMOND,
	HEART,
	SPADE,
	ALL,
}
