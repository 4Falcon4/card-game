## Toe Beans Card Back Ability
## Positive: While in your hand, see incoming card and card effect
## Negative: Becomes next card drawn, shuffle 2 into your deck and destroy itself
extends CardAbility

## Show preview of next card and effect
static func perform_positive(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")

	if !card_deck_manager:
		push_error("ToeBeansAbility: Missing card_deck_manager in context")
		return

	# TODO: Implement preview UI for next card and its effect
	print("ToeBeansAbility: Preview next card and effect (UI implementation needed)")


## Special transformation effect
static func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")

	if !card_deck_manager or !player_hand:
		push_error("ToeBeansAbility: Missing required context")
		return

	# TODO: Implement card transformation and deck shuffling
	# For now, just log the effect
	print("ToeBeansAbility: Card transformation effect (implementation needed)")
