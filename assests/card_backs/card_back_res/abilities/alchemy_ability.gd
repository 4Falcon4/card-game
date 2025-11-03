## Alchemy Card Back Ability
## Positive: Gain money equal to hand value divided by 2
## Negative: Lose money equal to number of cards in hand
extends CardAbility
class_name AlchemyAbility

## Gain chips based on current hand value
func perform_positive(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")

	if !blackjack_game:
		push_error("AlchemyAbility: Missing blackjack_game in context")
		return

	var hand_value = blackjack_game.GetPlayerHandValue()
	var gain = hand_value / 2
	blackjack_game.PlayerChips += gain
	print("AlchemyAbility: Gained %d chips from hand value %d! Total: %d" % [gain, hand_value, blackjack_game.PlayerChips])


## Lose chips based on number of cards in hand
func perform_negative(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")
	var player_hand = context.get("player_hand")

	if !blackjack_game or !player_hand:
		push_error("AlchemyAbility: Missing required context")
		return

	var cards_count = player_hand.cards.size()
	var chips_before = blackjack_game.PlayerChips
	blackjack_game.PlayerChips = max(0, blackjack_game.PlayerChips - cards_count)
	var actual_loss = chips_before - blackjack_game.PlayerChips

	print("AlchemyAbility: Lost %d chips from %d cards! Total: %d" % [actual_loss, cards_count, blackjack_game.PlayerChips])
