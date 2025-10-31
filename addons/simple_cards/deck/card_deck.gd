##Resource for holding and managing decks of cards
@icon("uid://u56pws80lkxh")
class_name CardDeck extends Resource

##Name of the deck
@export var deck_name: StringName = ""
##The original card list (template for resetting)
@export var cards: Array[CardResource] = []
@export var back_resources: Array[CardBackResource] = []
@export_enum("NONE", "LIGHT", "DARK", "WHITE", "BLACK") var deck_color: int = 1

var standard_back: CardBackResource = load("res://assests/card_backs/card_back_res/simple.tres")

##Everyone knows what a horse is!
var horse
