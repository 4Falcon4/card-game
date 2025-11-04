## Tool script to add ability testing to cards
## This provides buttons to test card abilities in the editor/runtime
@tool
class_name CardAbilityTester extends Node


## Test the positive ability - can be called from inspector
func test_positive() -> void:
	var card = get_parent()
	if card and card.has_method("_test_positive_ability"):
		card._test_positive_ability()
	else:
		print("Parent must be a Card node")


## Test the negative ability - can be called from inspector
func test_negative() -> void:
	var card = get_parent()
	if card and card.has_method("_test_negative_ability"):
		card._test_negative_ability()
	else:
		print("Parent must be a Card node")
