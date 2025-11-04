@icon("uid://cvwcyhqx6fvdk")
class_name CardBackResource extends CardResource

@export var display_name: String
@export var ability: Resource
@export var descriptionP: String
@export var descriptionN: String
@export var rarrity: Rarrity = Rarrity.NONE
@export var texture: Texture2D

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
