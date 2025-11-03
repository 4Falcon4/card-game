## Gain bonus chips (Positive)
## Lose chips (Negative)
extends CardAbility
class_name ChipGambleAbility

@export var chips_gained: int = 100
@export var chips_lost: int = 50

## Adds chips to the player's total
func perform_positive(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")

	if !blackjack_game:
		push_error("ChipGambleAbility: Missing blackjack_game in context")
		return

	blackjack_game.PlayerChips += chips_gained
	print("ChipGambleAbility: Gained %d chips! Total: %d" % [chips_gained, blackjack_game.PlayerChips])


## Removes chips from the player's total (cannot go below 0)
func perform_negative(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")

	if !blackjack_game:
		push_error("ChipGambleAbility: Missing blackjack_game in context")
		return

	var chips_before = blackjack_game.PlayerChips
	blackjack_game.PlayerChips = max(0, blackjack_game.PlayerChips - chips_lost)
	var actual_loss = chips_before - blackjack_game.PlayerChips

	print("ChipGambleAbility: Lost %d chips! Total: %d" % [actual_loss, blackjack_game.PlayerChips])
