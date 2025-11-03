## Candle Card Back Ability
## Positive: Pick from 2 random card effects (random bonus chips)
## Negative: Activate random negative effect (random chip loss)
extends CardAbility

@export var max_bonus: int = 10
@export var max_penalty: int = 10

## Apply a random positive effect
func perform_positive(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")

	if !blackjack_game:
		push_error("CandleAbility: Missing blackjack_game in context")
		return

	# Random effect between 0 and max_bonus
	var random_effect = randi() % (max_bonus + 1)
	blackjack_game.PlayerChips += random_effect
	print("CandleAbility: Random positive effect: +%d chips! Total: %d" % [random_effect, blackjack_game.PlayerChips])


## Apply a random negative effect
func perform_negative(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")

	if !blackjack_game:
		push_error("CandleAbility: Missing blackjack_game in context")
		return

	# Random effect between 0 and max_penalty
	var random_effect = randi() % (max_penalty + 1)
	var chips_before = blackjack_game.PlayerChips
	blackjack_game.PlayerChips = max(0, blackjack_game.PlayerChips - random_effect)
	var actual_loss = chips_before - blackjack_game.PlayerChips

	print("CandleAbility: Random negative effect: -%d chips! Total: %d" % [actual_loss, blackjack_game.PlayerChips])
