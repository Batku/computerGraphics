extends CanvasLayer

var money_label: Label
var change_label: Label
var demand_container: PanelContainer
var demand_label: Label
var last_money: int = 0

func _ready():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Simple crosshair
	var crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 48)
	crosshair.add_theme_color_override("font_color", Color. WHITE)
	crosshair.position = viewport_size / 2.0 - Vector2(12, 24)
	add_child(crosshair)
	
	# Money display - top right
	money_label = Label. new()
	money_label.text = "$" + str(GameManager.player_money)
	money_label.add_theme_font_size_override("font_size", 36)
	money_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.3))
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label. position = Vector2(viewport_size.x - 160, 20)
	money_label.size = Vector2(140, 50)
	add_child(money_label)
	
	# Change indicator
	change_label = Label. new()
	change_label.add_theme_font_size_override("font_size", 28)
	change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	change_label. position = Vector2(viewport_size.x - 160, 65)
	change_label.size = Vector2(140, 40)
	change_label.visible = false
	add_child(change_label)
	
	# Demand display - center top
	create_demand_display(viewport_size)
	
	last_money = GameManager.player_money

func create_demand_display(viewport_size: Vector2):
	demand_container = PanelContainer.new()
	demand_container.position = Vector2(viewport_size.x / 2.0 - 120, 15)
	demand_container.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.02, 0.02, 0.95)
	style.set_border_width_all(3)
	style.border_color = Color(0.7, 0.15, 0.15)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(12)
	demand_container.add_theme_stylebox_override("panel", style)
	add_child(demand_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	demand_container.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "HE WANTS"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.25, 0.25))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	demand_label = Label.new()
	demand_label.text = "$0"
	demand_label.add_theme_font_size_override("font_size", 38)
	demand_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	demand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(demand_label)

func _process(_delta):
	var current_money = GameManager. player_money
	
	if current_money != last_money: 
		var diff = current_money - last_money
		show_change(diff)
		last_money = current_money
	
	money_label.text = "$" + str(current_money)
	
	# Show/update demand when being chased
	if GameManager. is_being_chased: 
		demand_container.visible = true
		demand_label.text = "$" + str(GameManager.current_demand)
		
		# Green if can afford, red if not
		if current_money >= GameManager.current_demand:
			demand_label. add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			demand_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		demand_container.visible = false

func show_change(amount: int):
	var viewport_size = get_viewport().get_visible_rect().size
	var start_x = viewport_size.x - 160
	
	if amount > 0:
		change_label.text = "+$" + str(amount)
		change_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		change_label. text = "-$" + str(abs(amount))
		change_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	change_label.position = Vector2(start_x, 65)
	change_label.modulate.a = 1.0
	change_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(change_label, "position:y", 95.0, 1.2).set_ease(Tween. EASE_OUT)
	tween.parallel().tween_property(change_label, "modulate:a", 0.0, 1.2).set_delay(0.3)
	tween.tween_callback(func(): change_label.visible = false)
