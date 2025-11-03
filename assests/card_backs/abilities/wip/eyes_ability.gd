## Eyes Card Back Ability
## Positive: See next 3 cards, choose which remains and which get discarded
## Negative: Draw a playing card face down
extends CardAbility

## Preview next 3 cards and allow selection
func perform_positive(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")

	if !card_deck_manager:
		push_error("EyesAbility: Missing card_deck_manager in context")
		return

	# TODO: Implement preview and selection UI
	# For now, just log that the ability was triggered
	print("EyesAbility: Preview next 3 cards (UI implementation needed)")


## Draw a card face down (hidden value)
func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")

	if !card_deck_manager or !player_hand:
		push_error("EyesAbility: Missing required context")
		return

	# Draw a card face down
	var drawn_cards = card_deck_manager.deal_cards(1)
	if drawn_cards.size() > 0:
		var card = drawn_cards[0]
		card.is_hidden = true
		player_hand.add_cards(drawn_cards)
		print("EyesAbility: Drew 1 card face down")
