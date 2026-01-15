extends Control

# UI References
var reel1_label: Label
var reel2_label: Label
var reel3_label: Label
var bet_label: Label
var win_label: Label
var spin_button: Button
var leave_button: Button
var bet_buttons:  Array = []

# Game state
var current_bet: int = 25
var is_spinning: bool = false
var is_interactive: bool = false

# Reel spin state
var reel_spinning: Array = [false, false, false]
var reel_stop_positions: Array = [0, 0, 0]
var reel_labels: Array = []

const COLOR_BG_DARK = Color(0.12, 0.1, 0.14, 1)
const COLOR_BG_PANEL = Color(0.18, 0.15, 0.2, 1)
const COLOR_RUST = Color(0.6, 0.35, 0.25, 1)
const COLOR_DRIED_BLOOD = Color(0.5, 0.2, 0.18, 1)
const COLOR_SICKLY_GREEN = Color(0.4, 0.65, 0.3, 1)
const COLOR_DIRTY_GOLD = Color(0.75, 0.65, 0.35, 1)
const COLOR_GRIME = Color(0.45, 0.4, 0.35, 1)
const COLOR_PALE_TEXT = Color(0.85, 0.82, 0.78, 1)
const COLOR_BRIGHT_TEXT = Color(0.95, 0.92, 0.88, 1)
const COLOR_WARNING = Color(0.8, 0.4, 0.3, 1)


const SYMBOLS = {
	"skull": {"char": "💀", "weight": 30, "payout_3": 4, "payout_2": 2},
	"eye": {"char":  "👁", "weight": 25, "payout_3":  5, "payout_2": 2},
	"moth": {"char": "🦋", "weight": 18, "payout_3": 8, "payout_2": 0},
	"bell": {"char": "🔔", "weight": 12, "payout_3": 12, "payout_2": 0},
	"candle":  {"char": "🕯", "weight": 8, "payout_3": 20, "payout_2": 0},
	"coffin":  {"char": "⚰", "weight": 5, "payout_3": 35, "payout_2": 0},
	"diamond": {"char": "💎", "weight": 3, "payout_3": 60, "payout_2": 0},
	"seven": {"char": "7", "weight":  2, "payout_3": 100, "payout_2": 0},
	"demon": {"char": "👿", "weight": 1, "payout_3": 200, "payout_2":  0}
}

var symbol_keys: Array = []
var reel_strips: Array = []

# Signals
signal spin_completed(symbols: Array, winnings: int)
signal slot_finished
signal leave_requested

func _ready():
	
	set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	
	symbol_keys = SYMBOLS.keys()
	create_ui()
	generate_reel_strips()
	win_label.visible = false
	

func create_ui():
	"""Build the entire UI programmatically - HORROR THEME - LIGHTER"""
	
	# Dark background
	var bg = ColorRect.new()
	bg.color = COLOR_BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# CENTER CONTAINER
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	center_container.add_child(main_vbox)
	
	# Title - ominous but readable
	var title = Label.new()
	title.text = "⛧ FORTUNE'S END ⛧"
	title. horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", COLOR_DIRTY_GOLD)
	main_vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "- all bets are final -"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", COLOR_PALE_TEXT)
	main_vbox.add_child(subtitle)
	
	main_vbox.add_child(create_spacer(20))
	
	# Balance - brighter for readability

	
	main_vbox.add_child(create_spacer(30))
	
	# Reels container with border
	var reel_container = PanelContainer.new()
	var reel_container_style = StyleBoxFlat.new()
	reel_container_style.bg_color = Color(0.08, 0.06, 0.1, 1)
	reel_container_style.set_border_width_all(4)
	reel_container_style.border_color = COLOR_RUST
	reel_container_style.set_corner_radius_all(5)
	reel_container.add_theme_stylebox_override("panel", reel_container_style)
	main_vbox.add_child(reel_container)
	
	var reel_margin = MarginContainer.new()
	reel_margin.add_theme_constant_override("margin_left", 30)
	reel_margin.add_theme_constant_override("margin_right", 30)
	reel_margin.add_theme_constant_override("margin_top", 20)
	reel_margin.add_theme_constant_override("margin_bottom", 20)
	reel_container.add_child(reel_margin)
	
	# Reels
	var reel_hbox = HBoxContainer.new()
	reel_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	reel_hbox.add_theme_constant_override("separation", 30)
	reel_margin.add_child(reel_hbox)
	
	reel_labels. clear()
	for i in range(3):
		var reel_panel = PanelContainer.new()
		reel_panel.custom_minimum_size = Vector2(200, 200)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.04, 0.06, 1)
		style.set_border_width_all(3)
		style.border_color = COLOR_GRIME
		style.set_corner_radius_all(3)
		reel_panel.add_theme_stylebox_override("panel", style)
		
		var reel_label = Label.new()
		reel_label.text = "?"
		reel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		reel_label.add_theme_font_size_override("font_size", 100)
		reel_label.add_theme_color_override("font_color", COLOR_BRIGHT_TEXT)
		
		reel_panel.add_child(reel_label)
		reel_hbox.add_child(reel_panel)
		reel_labels.append(reel_label)
	
	reel1_label = reel_labels[0]
	reel2_label = reel_labels[1]
	reel3_label = reel_labels[2]
	
	main_vbox.add_child(create_spacer(15))
	
	# Win label
	win_label = Label.new()
	win_label.text = ""
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.add_theme_font_size_override("font_size", 46)
	win_label.add_theme_color_override("font_color", COLOR_SICKLY_GREEN)
	win_label.custom_minimum_size = Vector2(0, 55)
	win_label.visible = false
	main_vbox.add_child(win_label)
	
	# Bet label
	bet_label = Label.new()
	bet_label.text = "WAGER: $25"
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", 36)
	bet_label.add_theme_color_override("font_color", COLOR_BRIGHT_TEXT)
	main_vbox.add_child(bet_label)
	
	main_vbox.add_child(create_spacer(10))
	
	# Bet buttons
	var bet_hbox = HBoxContainer.new()
	bet_hbox.alignment = BoxContainer. ALIGNMENT_CENTER
	bet_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(bet_hbox)
	
	var bet_amounts = [10, 25, 50, 100]
	for amount in bet_amounts:
		var btn = create_horror_button("$" + str(amount), 32, Vector2(110, 55))
		btn.pressed.connect(_on_bet_changed.bind(amount))
		bet_hbox.add_child(btn)
		bet_buttons.append(btn)
	
	main_vbox.add_child(create_spacer(20))
	
	# Spin button
	spin_button = create_horror_button("PULL", 56, Vector2(350, 95), true)
	spin_button.pressed.connect(_on_spin_pressed)
	main_vbox.add_child(spin_button)
	spin_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	main_vbox.add_child(create_spacer(15))
	
	# Leave button
	leave_button = create_horror_button("WALK AWAY", 32, Vector2(200, 55))
	leave_button.pressed.connect(_on_leave_pressed)
	leave_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(leave_button)
	
	_on_bet_changed(current_bet)

func create_spacer(height: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func create_horror_button(text: String, font_size: int, min_size: Vector2, is_primary: bool = false) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	btn.custom_minimum_size = min_size
	btn.pivot_offset = Vector2.ZERO
	
	var base_color = COLOR_DRIED_BLOOD if is_primary else COLOR_BG_PANEL
	var border_color = COLOR_RUST if is_primary else COLOR_GRIME
	
	# Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.set_border_width_all(3)
	style_normal.border_color = border_color
	style_normal.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_color_override("font_color", COLOR_BRIGHT_TEXT)
	
	# Hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.2)
	style_hover.set_border_width_all(3)
	style_hover.border_color = COLOR_DIRTY_GOLD
	style_hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_hover_color", COLOR_DIRTY_GOLD)
	
	# Pressed
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.15)
	style_pressed.set_border_width_all(3)
	style_pressed.border_color = COLOR_RUST
	style_pressed.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_color_override("font_pressed_color", COLOR_WARNING)
	
	# Disabled
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.15, 0.12, 0.12, 0.6)
	style_disabled.set_border_width_all(3)
	style_disabled.border_color = Color(0.3, 0.25, 0.25, 0.6)
	style_disabled.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.35, 0.6))
	
	return btn

func generate_reel_strips():
	reel_strips.clear()
	for reel_index in range(3):
		var strip:  Array = []
		for position in range(40):
			strip.append(get_weighted_random_symbol())
		reel_strips.append(strip)

func get_weighted_random_symbol() -> String:
	var total_weight:  float = 0.0
	for symbol_data in SYMBOLS.values():
		total_weight += symbol_data. weight
	
	var random_value = randf() * total_weight
	var cumulative:  float = 0.0
	
	for symbol_key in SYMBOLS.keys():
		cumulative += SYMBOLS[symbol_key]. weight
		if random_value <= cumulative:
			return symbol_key
	
	return "skull"

func initialize_game():
	visible = true
	update_bet_display()
	win_label.visible = false
	is_spinning = false
	spin_button.disabled = false
	display_reel_symbols("? ", "? ", "?")

func set_interactive(interactive: bool):
	is_interactive = interactive
	spin_button.disabled = not interactive or is_spinning
	leave_button.disabled = not interactive or is_spinning
	
	for btn in bet_buttons:
		btn.disabled = not interactive or is_spinning

func _on_spin_pressed():
	
	if not is_interactive:
		return
		
	if is_spinning: 
		return
	
	if not can_afford_bet():
		show_insufficient_funds()
		return
	
	deduct_bet()
	start_spin()

func can_afford_bet() -> bool:
	return GameManager.player_money >= current_bet

func deduct_bet():
	GameManager.player_money -= current_bet

func add_winnings(amount: int):
	GameManager.player_money += amount

func start_spin():
	is_spinning = true
	spin_button.disabled = true
	win_label.visible = false
	
	# Determine when each reel will stop
	reel_stop_positions = [randi() % 40, randi() % 40, randi() % 40]
	
	# Start all reels spinning independently
	reel_spinning = [true, true, true]
	
	# Start coroutines for each reel
	spin_reel(0, 1.5)
	spin_reel(1, 2.2)
	spin_reel(2, 3.0)
	
	# Wait for all reels to finish then evaluate
	await get_tree().create_timer(3.2).timeout
	evaluate_result()

func spin_reel(reel_index: int, duration: float):
	var elapsed: float = 0.0
	var base_speed: float = 0.05  # Fast at start
	var current_speed: float = base_speed
	
	while elapsed < duration:
		if not reel_spinning[reel_index]:
			break
		
		# Pick a random symbol to display while spinning
		var random_symbol = symbol_keys[randi() % symbol_keys.size()]
		reel_labels[reel_index].text = SYMBOLS[random_symbol].char
		
		# Slow down near the end
		var progress = elapsed / duration
		if progress > 0.7:
			current_speed = base_speed + (progress - 0.7) * 0.3 
		
		await get_tree().create_timer(current_speed).timeout
		elapsed += current_speed
	
	# Land
	reel_spinning[reel_index] = false
	var final_symbol = reel_strips[reel_index][reel_stop_positions[reel_index]]
	reel_labels[reel_index].text = SYMBOLS[final_symbol].char
	
	# Flash effect on stop
	play_reel_stop_effect(reel_labels[reel_index])

func play_reel_stop_effect(reel_label: Label):
	reel_label.add_theme_color_override("font_color", COLOR_DIRTY_GOLD)
	await get_tree().create_timer(0.12).timeout
	reel_label.add_theme_color_override("font_color", COLOR_BRIGHT_TEXT)

func evaluate_result():
	var final_symbols:  Array = []
	
	for i in range(3):
		var symbol = reel_strips[i][reel_stop_positions[i]]
		final_symbols.append(symbol)
	
	var base_winnings:  int = 0
	var win_message: String = ""
	var is_jackpot: bool = false
	
	if final_symbols[0] == final_symbols[1] and final_symbols[1] == final_symbols[2]:
		var symbol_data = SYMBOLS[final_symbols[0]]
		base_winnings = current_bet * symbol_data.payout_3
		win_message = "+$%d" % base_winnings
		if final_symbols[0] == "demon":
			is_jackpot = true
			win_message = "CLAIMED:  $%d" % base_winnings
	elif final_symbols[0] == final_symbols[1] and SYMBOLS[final_symbols[0]].payout_2 > 0:
		var symbol_data = SYMBOLS[final_symbols[0]]
		base_winnings = current_bet * symbol_data.payout_2
		win_message = "+$%d" % base_winnings
	
	if base_winnings > 0:
		add_winnings(base_winnings)
		show_win(win_message, is_jackpot)
	else:
		show_loss()
	
	spin_completed. emit(final_symbols, base_winnings)
	
	is_spinning = false
	spin_button.disabled = false
	slot_finished.emit()

func display_reel_symbols(sym1: String, sym2: String, sym3: String):
	reel1_label.text = sym1
	reel2_label.text = sym2
	reel3_label.text = sym3

func show_win(message: String, is_jackpot: bool = false):
	win_label.text = message
	win_label.add_theme_color_override("font_color", COLOR_WARNING if is_jackpot else COLOR_SICKLY_GREEN)
	win_label.visible = true
	
	if is_jackpot:
		flash_screen()

func show_loss():
	win_label.text = "..."
	win_label.add_theme_color_override("font_color", COLOR_GRIME)
	win_label.visible = true

func show_insufficient_funds():
	win_label.text = "EMPTY POCKETS"
	win_label. add_theme_color_override("font_color", COLOR_WARNING)
	win_label.visible = true
	
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween()
	tween.tween_property(win_label, "modulate: a", 0.0, 0.5)

func flash_screen():
	var flash = ColorRect.new()
	flash.color = Color(0.5, 0.15, 0.15, 0.4)
	flash.set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)


func update_bet_display():
	bet_label.text = "WAGER: $%d" % current_bet

func _on_bet_changed(new_bet: int):
	current_bet = new_bet
	update_bet_display()
	
	for btn in bet_buttons:
		if btn.text == "$" + str(new_bet):
			btn.modulate = COLOR_DIRTY_GOLD
		else: 
			btn.modulate = Color. WHITE

func _on_leave_pressed():
	if is_spinning:
		return
	leave_requested.emit()

func get_button_at_position(pos: Vector2) -> Button:
	# Find which button is at the given viewport position
	var all_buttons = [spin_button, leave_button] + bet_buttons
	
	for btn in all_buttons: 
		if not btn or btn.disabled:
			continue
		
		var btn_rect = btn.get_global_rect()
		
		if btn_rect.has_point(pos):
			return btn
	
	return null
