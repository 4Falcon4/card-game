extends Node
class_name DeckGenerator

## DeckGenerator - Generates new decks with rarity-based card back assignment
##
## This class handles:
## - Generating fresh decks from a CardDeck resource
## - Randomly assigning card backs based on rarity weights
## - Supporting both player and dealer deck generation

## Rarity weight configuration (lower = rarer)
const RARITY_WEIGHTS: Dictionary[Variant, Variant] = {
	CardBackResource.Rarrity.NONE: 0,
	CardBackResource.Rarrity.COMMON: 100,
	CardBackResource.Rarrity.UNCOMMON: 50,
	CardBackResource.Rarrity.RARE: 25,
	CardBackResource.Rarrity.EPIC: 12,
	CardBackResource.Rarrity.LEGENDARY: 6,
	CardBackResource.Rarrity.MYTHIC: 3,
	CardBackResource.Rarrity.EXOTIC: 1.5,
	CardBackResource.Rarrity.DIVINE: 0.75,
	CardBackResource.Rarrity.GODLY: 0.25
}

## Reference to the base deck resource (contains all card templates)
@export var base_deck: CardDeck

## Reference to the deck manager to populate
@export var target_deck_manager: CardDeckManager

## Whether to assign random card backs during generation
@export var assign_random_backs: bool = true

## Whether to use a standard back for all cards (dealer mode)
@export var use_standard_back: bool = false


## Generates a new deck and initializes the target deck manager
func generate_new_deck() -> void:
	if not base_deck:
		push_error("DeckGenerator: No base_deck assigned!")
		return

	if not target_deck_manager:
		push_error("DeckGenerator: No target_deck_manager assigned!")
		return

	# Clear existing deck
	target_deck_manager.clear_deck()

	# Create a copy of the deck to modify
	var new_deck = base_deck.duplicate(true)

	# Assign card backs if enabled
	if assign_random_backs and not use_standard_back:
		_assign_random_card_backs(new_deck)

	# Initialize the deck manager with the new deck
	if target_deck_manager.get_discard_pile_size() > 0:
		target_deck_manager.add_deck(new_deck)
	else:
		target_deck_manager.initialize_from_deck(new_deck)
	print("DeckGenerator: Generated new deck with %d cards" % new_deck.cards.size())


## Assigns random card backs to all cards based on rarity weights
func _assign_random_card_backs(deck: CardDeck) -> void:
	if deck.back_resources.is_empty():
		push_warning("DeckGenerator: No back_resources available in deck!")
		return

	# Build weighted pool of card backs
	var weighted_backs = _build_weighted_card_back_pool(deck.back_resources)

	if weighted_backs.is_empty():
		push_warning("DeckGenerator: No valid card backs with weights!")
		return

	# Assign a random back to each card
	for i in range(deck.cards.size()):
		var card_resource = deck.cards[i]
		var random_back = _select_random_card_back(weighted_backs)
		if not random_back:
			continue

		if card_resource is BlackjackStyleRes:
			card_resource.set_back_data(random_back)
			# ensure the modified resource stays in the array (mostly redundant for Resource refs)
			deck.cards[i] = card_resource
		else:
			var new_card = BlackjackStyleRes.new(card_resource)
			new_card.set_back_data(random_back)
			deck.cards[i] = new_card


## Builds a weighted pool of card backs for random selection
func _build_weighted_card_back_pool(back_resources: Array[CardBackResource]) -> Array:
	var weighted_pool = []

	for back_res in back_resources:
		var weight = RARITY_WEIGHTS.get(back_res.rarrity, 0)
		if weight > 0:
			# Add multiple copies based on weight (normalized to integers)
			var count = max(1, int(weight))
			for i in count:
				weighted_pool.append(back_res)

	return weighted_pool


## Selects a random card back from the weighted pool
func _select_random_card_back(weighted_pool: Array) -> CardBackResource:
	if weighted_pool.is_empty():
		return null

	var random_index = randi() % weighted_pool.size()
	return weighted_pool[random_index]


## Regenerates the deck if the draw pile is empty
func regenerate_if_empty() -> bool:
	if not target_deck_manager:
		return false

	if target_deck_manager.is_draw_pile_empty():
		print("DeckGenerator: Draw pile empty, regenerating deck...")
		generate_new_deck()
		return true

	return false


## Alternative: Reshuffle discard pile into draw pile instead of generating new deck
func reshuffle_discard_if_empty() -> bool:
	if not target_deck_manager:
		return false

	if target_deck_manager.is_draw_pile_empty():
		print("DeckGenerator: Draw pile empty, reshuffling discard pile...")
		target_deck_manager.reshuffle_discard_and_shuffle()
		return true

	return false
