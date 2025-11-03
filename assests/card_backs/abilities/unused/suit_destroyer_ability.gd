## Destroys all cards of a specific suit from the deck (Positive)
## Creates and shuffles 3 new random cards into the deck (Negative)
extends CardAbility
class_name SuitDestroyerAbility

## Removes all cards of the triggering card's suit from the discard pile
func perform_positive(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var triggering_card = context.get("triggering_card")

	if !card_deck_manager or !triggering_card:
		push_error("SuitDestroyerAbility: Missing required context")
		return

	var card_data = triggering_card.card_data
	var target_suit = card_data.card_suit

	# Get all cards from discard pile
	var discard_pile = card_deck_manager.discard_pile
	var cards_to_remove: Array[Card] = []

	for child in discard_pile.get_children():
		if child is Card:
			if child.card_data.card_suit == target_suit:
				cards_to_remove.append(child)

	# Remove matching cards
	for card in cards_to_remove:
		card.queue_free()

	print("SuitDestroyerAbility: Destroyed %d cards of suit %d" % [cards_to_remove.size(), target_suit])


## Creates 3 duplicate cards of random cards in the deck and shuffles them in
func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")

	if !card_deck_manager:
		push_error("SuitDestroyerAbility: Missing card_deck_manager in context")
		return

	var draw_pile = card_deck_manager.draw_pile
	var cards_in_deck: Array[Card] = []

	# Collect all cards currently in draw pile
	for child in draw_pile.get_children():
		if child is Card:
			cards_in_deck.append(child)

	if cards_in_deck.is_empty():
		print("SuitDestroyerAbility: No cards in deck to duplicate")
		return

	# Create 3 duplicate cards
	for i in range(3):
		var random_card = cards_in_deck[randi() % cards_in_deck.size()]
		var new_card = Card.new(random_card.card_data)
		card_deck_manager.add_card_to_draw_pile(new_card)

	# Shuffle the deck
	card_deck_manager.shuffle()

	print("SuitDestroyerAbility: Created and shuffled 3 new cards into the deck")
