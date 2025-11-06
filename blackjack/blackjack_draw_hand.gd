@tool
extends CardHand

@export var max_selected: int

signal selection_changed()

var _selected: Array[Card]
var selected: Array[Card]:
	get:
		return _selected.duplicate()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# Check if any card shortcut action was pressed
	for i in range(min(_cards.size(), 10)):
		var action_name = "card%d" % (i + 1)
		if InputMap.has_action(action_name) and event.is_action_pressed(action_name):
			var card = _cards[i]
			if card:
				toggle_select(card)
				emit_signal("selection_changed")
				get_viewport().set_input_as_handled()
				break

func _handle_clicked_card(card: Card) -> void:
	toggle_select(card)
	emit_signal("selection_changed")

func toggle_select(card: Card):
	if _selected.has(card):
		_selected.erase(card)
		deselect(card)
	elif _selected.size() < max_selected:
		_selected.append(card)
		select(card)
	

func select(card: Card):
	card.position_offset = Vector2(0, 40)
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
	var focus_z = 900
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

func _arrange_cards() -> void:
	super._arrange_cards()
	_update_card_shortcuts()

func _update_card_shortcuts() -> void:
	# Assign keyboard shortcuts to each card based on its index
	for i in _cards.size():
		var card = _cards[i]
		if card and card is Card:
			# Clear any existing shortcut
			card.shortcut = null

			# Create a new shortcut for this card position (1-9, 0 for 10th card)
			if i < 10:  # Limit to 10 cards (keys 1-9, 0)
				var action_name = "card%d" % (i + 1)

				# Create or update the InputMap action dynamically
				if not InputMap.has_action(action_name):
					InputMap.add_action(action_name)
				else:
					# Clear existing events for this action
					InputMap.action_erase_events(action_name)

				# Add the key event to the InputMap
				var key_event = InputEventKey.new()
				if i < 9:
					key_event.keycode = KEY_1 + i  # KEY_1, KEY_2, ... KEY_9
				else:
					key_event.keycode = KEY_0  # KEY_0 for 10th card

				InputMap.action_add_event(action_name, key_event)

				# Create shortcut that uses the action
				var shortcut = Shortcut.new()
				var input_event = InputEventAction.new()
				input_event.action = action_name
				shortcut.events = [input_event]
				card.shortcut = shortcut

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
			if not card.is_hidden:
				card.is_front_face = true

	_arrange_cards()
	return added_count
