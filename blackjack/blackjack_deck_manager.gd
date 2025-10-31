extends CardDeckManager


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
