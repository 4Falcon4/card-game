class_name BlackjackStyleRes extends CardResource

@export var name: String
@export var top_texture: Texture2D
@export var bottom_texture: Texture2D
@export var current_rarity: rarrity = rarrity.NONE
@export var deck_color: deck_colors = deck_colors.NONE
@export var card_suit: suit = suit.ALL
@export var value: int = 1

enum rarrity {
	NONE,
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
	EXOTIC,
	DIVINE,
	GODLY
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
