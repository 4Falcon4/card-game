class_name BlackjackStyleRes extends CardResource

@export var name: String
@export var top_texture: Texture2D
@export var bottom_texture: Texture2D
@export var current_rarity: Rarrity = Rarrity.NONE
@export var deck_color: deck_colors = deck_colors.NONE
@export var card_suit: suit = suit.ALL
@export var value: int = 1
@export var display_name: String
@export var ability: CardAbility
@export var descriptionP: String
@export var descriptionN: String
@export var rarrity: Rarrity = Rarrity.NONE
@export var texture: Texture2D

func _init(standardRes: StandardStyleRes = StandardStyleRes.new()) -> void:
	name = standardRes.name
	top_texture = standardRes.top_texture
	card_suit = standardRes.card_suit as int
	value = standardRes.value
	deck_color = standardRes.deck_color as int

func set_back_data(backRes: CardBackResource) -> void:
	display_name = backRes.display_name
	ability = backRes.ability
	descriptionP = backRes.descriptionP
	descriptionN = backRes.descriptionN
	rarrity = backRes.rarrity as int
	bottom_texture = backRes.texture
	

enum Rarrity {
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
