extends Control

# UI References
var reel1_label: Label
var reel2_label: Label
var reel3_label: Label
var balance_label: Label
var bet_label: Label
var win_label: Label
var spin_button: Button
var leave_button: Button
var bet_buttons: Array = []

# Game state
var current_bet: int = 25
var is_spinning: bool = false
var is_interactive: bool = false

# Symbol definitions
const SYMBOLS = {
	"cherry": {"char": "🍒", "weight": 25, "payout_3": 3, "payout_2": 1},
	"lemon": {"char": "🍋", "weight": 20, "payout_3": 4, "payout_2": 1},
	"orange": {"char": "🍊", "weight": 15, "payout_3": 5, "payout_2": 0},
	"bell": {"char": "🔔", "weight": 12, "payout_3": 8, "payout_2": 0},
	"star": {"char": "⭐", "weight": 10, "payout_3": 12, "payout_2": 0},
	"bar": {"char": "BAR", "weight": 8, "payout_3": 15, "payout_2": 0},
	"diamond": {"char": "💎", "weight": 5, "payout_3": 25, "payout_2": 0},
	"seven": {"char": "7️", "weight": 4, "payout_3": 50, "payout_2": 0},
	"crown": {"char": "👑", "weight": 1, "payout_3": 100, "payout_2": 0}
}

var reel_strips: Array = []

# Signals
signal spin_completed(symbols: Array, winnings: int)
signal slot_finished
signal leave_requested

func _ready():
	print("🎮 SlotUI initializing...")
	
	set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	
	create_ui()
	generate_reel_strips()
	win_label.visible = false
	
	print("✅ SlotUI ready!")

func create_ui():
	"""Build the entire UI programmatically - CENTERED"""
	
	# Background
	var bg = ColorRect.new()
	bg. color = Color(0.1, 0.1, 0.15, 1)
	bg.set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	add_child(bg)
	
	# CENTER CONTAINER
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "🎰 LUCKY SLOTS 🎰"
	title. horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color. GOLD)
	main_vbox. add_child(title)
	
	main_vbox.add_child(create_spacer(30))
	
	# Balance
	balance_label = Label.new()
	balance_label.text = "Balance: $500"
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label. add_theme_font_size_override("font_size", 48)
	balance_label.add_theme_color_override("font_color", Color.WHITE)
	main_vbox. add_child(balance_label)
	
	main_vbox.add_child(create_spacer(50))
	
	# Reels
	var reel_hbox = HBoxContainer.new()
	reel_hbox. alignment = BoxContainer.ALIGNMENT_CENTER
	reel_hbox.add_theme_constant_override("separation", 50)
	main_vbox. add_child(reel_hbox)
	
	for i in range(3):
		var reel_panel = PanelContainer.new()
		reel_panel.custom_minimum_size = Vector2(250, 250)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.25, 1)
		style.set_border_width_all(5)
		style.border_color = Color. GOLD
		style.set_corner_radius_all(15)
		reel_panel.add_theme_stylebox_override("panel", style)
		
		var reel_label = Label.new()
		reel_label.text = "🎰"
		reel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		reel_label.add_theme_font_size_override("font_size", 120)
		
		reel_panel.add_child(reel_label)
		reel_hbox.add_child(reel_panel)
		
		if i == 0:
			reel1_label = reel_label
		elif i == 1:
			reel2_label = reel_label
		else:
			reel3_label = reel_label
	
	main_vbox.add_child(create_spacer(30))
	
	# Win label
	win_label = Label. new()
	win_label. text = "WIN!"
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label. add_theme_font_size_override("font_size", 56)
	win_label.add_theme_color_override("font_color", Color.GREEN)
	win_label.custom_minimum_size = Vector2(0, 70)
	win_label.visible = false
	main_vbox.add_child(win_label)
	
	# Bet label
	bet_label = Label. new()
	bet_label. text = "Bet: $25"
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label. add_theme_font_size_override("font_size", 42)
	bet_label.add_theme_color_override("font_color", Color.WHITE)
	main_vbox.add_child(bet_label)
	
	main_vbox.add_child(create_spacer(20))
	
	# Bet buttons
	var bet_hbox = HBoxContainer.new()
	bet_hbox.alignment = BoxContainer. ALIGNMENT_CENTER
	bet_hbox.add_theme_constant_override("separation", 25)
	main_vbox. add_child(bet_hbox)
	
	var bet_amounts = [10, 25, 50, 100]
	for amount in bet_amounts:
		var btn = create_button("$" + str(amount), 38)
		btn.custom_minimum_size = Vector2(140, 70)
		btn.pressed.connect(_on_bet_changed.bind(amount))
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		bet_hbox.add_child(btn)
		bet_buttons.append(btn)
	
	main_vbox.add_child(create_spacer(30))
	
	# Spin button
	spin_button = create_button("🎰 SPIN 🎰", 64)
	spin_button.custom_minimum_size = Vector2(500, 120)
	spin_button.pressed.connect(_on_spin_pressed)
	spin_button.mouse_entered.connect(_on_button_hover.bind(spin_button))
	spin_button.mouse_exited.connect(_on_button_unhover.bind(spin_button))
	main_vbox.add_child(spin_button)
	
	main_vbox.add_child(create_spacer(20))
	
	# Leave button
	leave_button = create_button("LEAVE", 38)
	leave_button.custom_minimum_size = Vector2(250, 70)
	leave_button.pressed.connect(_on_leave_pressed)
	leave_button.mouse_entered.connect(_on_button_hover.bind(leave_button))
	leave_button.mouse_exited.connect(_on_button_unhover.bind(leave_button))
	main_vbox.add_child(leave_button)
	
	# Highlight selected bet
	_on_bet_changed(current_bet)

func create_spacer(height: float) -> Control:
	var spacer = Control.new()
	spacer. custom_minimum_size = Vector2(0, height)
	return spacer

func create_button(text: String, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	
	# Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.3, 0.3, 0.4, 1)
	style_normal.set_border_width_all(3)
	style_normal.border_color = Color(0.5, 0.5, 0.6, 1)
	style_normal.set_corner_radius_all(10)
	btn. add_theme_stylebox_override("normal", style_normal)
	
	# Hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.5, 0.5, 0.6, 1)
	style_hover.set_border_width_all(5)
	style_hover.border_color = Color. GOLD
	style_hover. set_corner_radius_all(10)
	btn.add_theme_stylebox_override("hover", style_hover)
	
	# Pressed
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.2, 0.2, 0.3, 1)
	style_pressed.set_border_width_all(3)
	style_pressed.border_color = Color.GOLD
	style_pressed.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	# Disabled
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.2, 0.2, 0.2, 1)
	style_disabled.set_border_width_all(3)
	style_disabled.border_color = Color(0.3, 0.3, 0.3, 1)
	style_disabled.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	
	return btn

func _on_button_hover(button: Button):
	if button.disabled:
		return
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2. ONE, 0.1)

func generate_reel_strips():
	reel_strips. clear()
	for reel_index in range(3):
		var strip: Array = []
		for position in range(40):
			strip.append(get_weighted_random_symbol())
		reel_strips.append(strip)

func get_weighted_random_symbol() -> String:
	var total_weight: float = 0.0
	for symbol_data in SYMBOLS.values():
		total_weight += symbol_data. weight
	
	var random_value = randf() * total_weight
	var cumulative: float = 0.0
	
	for symbol_key in SYMBOLS.keys():
		cumulative += SYMBOLS[symbol_key].weight
		if random_value <= cumulative:
			return symbol_key
	
	return "cherry"

func initialize_game():
	print("🎰 initialize_game()")
	visible = true
	update_balance_display()
	update_bet_display()
	win_label.visible = false
	is_spinning = false
	spin_button.disabled = false
	display_reel_symbols("🎰", "🎰", "🎰")

func set_interactive(interactive: bool):
	print("⚙️ set_interactive(", interactive, ")")
	is_interactive = interactive
	spin_button.disabled = not interactive or is_spinning
	leave_button.disabled = not interactive or is_spinning
	
	for btn in bet_buttons:
		btn.disabled = not interactive or is_spinning

func _on_spin_pressed():
	print("\n🎰🎰🎰 SPIN PRESSED! 🎰🎰🎰")
	
	if not is_interactive:
		print("   ❌ Not interactive")
		return
		
	if is_spinning:
		print("   ❌ Already spinning")
		return
	
	if not can_afford_bet():
		print("   ❌ Can't afford")
		show_insufficient_funds()
		return
	
	print("   ✅ Starting spin!")
	deduct_bet()
	update_balance_display()
	start_spin()

func can_afford_bet() -> bool:
	return GameManager.player_money >= current_bet

func deduct_bet():
	GameManager.player_money -= current_bet

func add_winnings(amount: int):
	GameManager.player_money += amount

func start_spin():
	is_spinning = true
	spin_button. disabled = true
	win_label.visible = false
	
	var stop_positions: Array = [randi() % 40, randi() % 40, randi() % 40]
	animate_spin(stop_positions)

func animate_spin(stop_positions: Array):
	var spin_chars = ["🎰", "💫", "✨", "⭐"]
	var spin_time = 0.0
	var spin_duration = 2.0
	
	while spin_time < spin_duration:
		var random_char = spin_chars[randi() % spin_chars.size()]
		display_reel_symbols(random_char, random_char, random_char)
		await get_tree().create_timer(0.1).timeout
		spin_time += 0.1
	
	var final_symbols: Array = []
	
	var symbol1 = reel_strips[0][stop_positions[0]]
	reel1_label.text = SYMBOLS[symbol1].char
	final_symbols.append(symbol1)
	play_reel_stop_effect(reel1_label)
	await get_tree().create_timer(0.4).timeout
	
	var symbol2 = reel_strips[1][stop_positions[1]]
	reel2_label.text = SYMBOLS[symbol2].char
	final_symbols.append(symbol2)
	play_reel_stop_effect(reel2_label)
	await get_tree().create_timer(0.4).timeout
	
	var symbol3 = reel_strips[2][stop_positions[2]]
	reel3_label.text = SYMBOLS[symbol3].char
	final_symbols.append(symbol3)
	play_reel_stop_effect(reel3_label)
	await get_tree().create_timer(0.3).timeout
	
	evaluate_spin(final_symbols)

func display_reel_symbols(sym1: String, sym2: String, sym3: String):
	reel1_label.text = sym1
	reel2_label.text = sym2
	reel3_label.text = sym3

func play_reel_stop_effect(reel_label: Label):
	var tween = create_tween()
	tween.tween_property(reel_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(reel_label, "scale", Vector2. ONE, 0.1)

func evaluate_spin(symbols: Array):
	var base_winnings: int = 0
	var win_message: String = ""
	var is_jackpot: bool = false
	
	if symbols[0] == symbols[1] and symbols[1] == symbols[2]:
		var symbol_data = SYMBOLS[symbols[0]]
		base_winnings = current_bet * symbol_data.payout_3
		win_message = "WIN: $%d (%s %s %s)!" % [base_winnings, symbol_data.char, symbol_data.char, symbol_data.char]
		if symbols[0] == "crown":
			is_jackpot = true
	elif symbols[0] == symbols[1] and SYMBOLS[symbols[0]].payout_2 > 0:
		var symbol_data = SYMBOLS[symbols[0]]
		base_winnings = current_bet * symbol_data. payout_2
		win_message = "WIN: $%d (%s %s)" % [base_winnings, symbol_data.char, symbol_data.char]
	
	var final_winnings = base_winnings
	
	if final_winnings > 0:
		add_winnings(final_winnings)
		show_win(win_message, is_jackpot)
	else:
		show_loss()
	
	update_balance_display()
	spin_completed. emit(symbols, final_winnings)
	
	is_spinning = false
	spin_button.disabled = false
	slot_finished.emit()

func show_win(message: String, is_jackpot: bool = false):
	win_label. text = message
	win_label.modulate = Color. GOLD if is_jackpot else Color. GREEN
	win_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(win_label, "scale", Vector2(1.3, 1.3), 0.2)
	tween. tween_property(win_label, "scale", Vector2.ONE, 0.2)
	
	if is_jackpot:
		flash_screen()

func show_loss():
	win_label.text = "No win..."
	win_label.modulate = Color. GRAY
	win_label.visible = true

func show_insufficient_funds():
	win_label.text = "INSUFFICIENT FUNDS!"
	win_label.modulate = Color.RED
	win_label.visible = true
	
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween()
	tween.tween_property(win_label, "modulate:a", 0.0, 0.5)

func flash_screen():
	var flash = ColorRect.new()
	flash. color = Color(1, 1, 0, 0.3)
	flash.set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func update_balance_display():
	balance_label.text = "Balance: $%d" % GameManager.player_money

func update_bet_display():
	bet_label.text = "Bet: $%d" % current_bet

func _on_bet_changed(new_bet: int):
	current_bet = new_bet
	update_bet_display()
	
	for btn in bet_buttons:
		if btn.text == "$" + str(new_bet):
			btn.modulate = Color.YELLOW
		else:
			btn. modulate = Color.WHITE

func _on_leave_pressed():
	if is_spinning:
		return
	print("🚪 Leave pressed!")
	leave_requested.emit()

func get_button_at_position(pos: Vector2) -> Button:
	"""Find which button is at the given viewport position"""
	var all_buttons = [spin_button, leave_button] + bet_buttons
	
	for btn in all_buttons:
		if not btn or btn.disabled:
			continue
		
		var btn_rect = btn.get_global_rect()
		
		if btn_rect.has_point(pos):
			print("   🎯 Found button: ", btn. text)
			return btn
	
	return null
