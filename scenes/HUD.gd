# In your player HUD script
func create_crosshair():
	var crosshair = CenterContainer.new()
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var dot = Label.new()
	dot.text = "+"
	dot.add_theme_font_size_override("font_size", 32)
	dot.add_theme_color_override("font_color", Color.WHITE)
	
	crosshair.add_child(dot)
	add_child(crosshair)
