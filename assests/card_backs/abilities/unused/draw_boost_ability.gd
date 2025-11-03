## Draw extra cards from the deck (Positive)
## Discard cards from your hand (Negative)
extends CardAbility
class_name DrawBoostAbility

@export var cards_to_draw: int = 2
@export var cards_to_discard: int = 1

## Draws additional cards into the player's hand
func perform_positive(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")

	if !card_deck_manager or !player_hand:
		push_error("DrawBoostAbility: Missing required context")
		return

	# Check if we have room in hand
	var remaining_space = player_hand.get_remaining_space()
	if remaining_space == -1:  # No limit
		remaining_space = cards_to_draw
	else:
		remaining_space = min(remaining_space, cards_to_draw)

	if remaining_space <= 0:
		print("DrawBoostAbility: Hand is full, cannot draw")
		return

	# Draw cards
	var drawn_cards = card_deck_manager.draw_cards(remaining_space)

	if drawn_cards.is_empty():
		print("DrawBoostAbility: No cards available to draw")
		return

	player_hand.add_cards(drawn_cards)
	print("DrawBoostAbility: Drew %d cards" % drawn_cards.size())


## Randomly discards cards from the player's hand
func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")

	if !card_deck_manager or !player_hand:
		push_error("DrawBoostAbility: Missing required context")
		return

	var cards = player_hand.cards  # Get copy of cards array
	var cards_to_remove = min(cards_to_discard, cards.size())

	if cards_to_remove <= 0:
		print("DrawBoostAbility: No cards to discard")
		return

	# Shuffle and take first N cards to discard
	cards.shuffle()

	for i in range(cards_to_remove):
		var card = cards[i]
		card_deck_manager.add_card_to_discard_pile(card)

	print("DrawBoostAbility: Discarded %d cards" % cards_to_remove)
