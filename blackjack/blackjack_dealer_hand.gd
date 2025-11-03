@tool
extends CardHand

@export var max_selected: int
var _selected: Array[Card]
var selected: Array[Card]:
	get:
		return _selected.duplicate()

func _handle_clicked_card(card: Card) -> void:
	toggle_select(card)

func toggle_select(card: Card):
	if _selected.has(card):
		_selected.erase(card)
		deselect(card)
	elif _selected.size() < max_selected:
		_selected.append(card)
		select(card)
	

func select(card: Card):
	card.position_offset = Vector2(0, -40)
	_arrange_cards()

func deselect(card: Card):
	card.position_offset = Vector2.ZERO
	_arrange_cards()
	
func sort_by_suit():
	_cards.sort_custom(func(a: Card, b: Card):
		return a.card_data.card_suit < b.card_data.card_suit)
	_arrange_cards()

func sort_selected():
	_selected.sort_custom(func(a: Card, b: Card):
		return get_card_index(a) < get_card_index(b))

func sort_by_value():
	_cards.sort_custom(func(a: Card, b: Card):
		return a.card_data.value > b.card_data.value)
	_arrange_cards()

func _on_card_focused(card: Card) -> void:
	var focus_z = -900
	card.z_index = focus_z
	if not card.is_hidden:
		card.flip()


func _on_card_unfocused(card: Card) -> void:
	_update_z_indices()
	if not card.is_hidden:
			card.flip()

func clear_selected():
	for card in _selected:
		deselect(card)
	_selected.clear()

func add_cards(card_array: Array[Card]) -> int:
	var added_count = 0
	for card in card_array:
		# Check if hand is full
		if max_hand_size >= 0 and _cards.size() >= max_hand_size:
			break
		
		if card.get_parent() != self:
			if card.get_parent() is CardHand:
				card.get_parent().remove_card(card, self)
			elif card.get_parent():
				card.reparent(self)
			else:
				add_child(card)
		
		if not _cards.has(card):
			_cards.append(card)
			_connect_card_signals(card)
			added_count += 1
			card.flip()
	
	_arrange_cards()
	return added_count
