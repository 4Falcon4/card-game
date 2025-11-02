extends CardDeckManager

## Enable automatic deck regeneration when draw pile is empty
@export var auto_regenerate: bool = true

## Regeneration mode: "new_deck" creates fresh deck, "reshuffle" uses discard pile
@export_enum("new_deck", "reshuffle") var regeneration_mode: String = "new_deck"

## Reference to DeckGenerator for creating new decks
var deck_generator: DeckGenerator


func add_card_to_draw_pile(card: Card) -> void:
	# Kill all tweens before reparenting
	card.kill_all_tweens()
	
	if card.get_parent():
		if card.get_parent() is CardHand:
			card.get_parent().remove_card(card, draw_pile)
		else:
			if card.is_front_face:
				card.flip()
			card.reparent(draw_pile)
	else:
		card.flip()
		draw_pile.add_child(card)

	_handle_card_reparanting(card, draw_pile.global_position if draw_pile is Control else Vector2.ZERO)

func initialize_from_deck(deck: CardDeck) -> void:
	clear_deck()

	for card_resource in deck.cards:
		card_resource = BlackjackStyleRes.new(card_resource)
		card_resource.deck_color = deck.deck_color
		if len(deck.back_resources) <= 0:
			push_error("Back Resource Array Empty")
		card_resource.set_back_data(deck.standard_back)
		var card = Card.new(card_resource)
		add_card_to_draw_pile(card)

	_update_card_visibility()


## Override draw_card to support automatic regeneration
func draw_card() -> Card:
	# Check if draw pile is empty and auto-regeneration is enabled
	if is_draw_pile_empty() and auto_regenerate:
		_handle_empty_deck()

	# Call parent's draw_card method
	return super.draw_card()


## Handles empty deck based on regeneration mode
func _handle_empty_deck() -> void:
	if regeneration_mode == "reshuffle":
		if not is_discard_pile_empty():
			print("BlackjackDeckManager: Draw pile empty, reshuffling discard pile...")
			reshuffle_discard_and_shuffle()
		elif deck_generator:
			print("BlackjackDeckManager: Both piles empty, generating new deck...")
			deck_generator.generate_new_deck()
	elif regeneration_mode == "new_deck":
		if deck_generator:
			print("BlackjackDeckManager: Draw pile empty, generating new deck...")
			deck_generator.generate_new_deck()
		else:
			push_warning("BlackjackDeckManager: No DeckGenerator available for regeneration!")
