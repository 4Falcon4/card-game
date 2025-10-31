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
