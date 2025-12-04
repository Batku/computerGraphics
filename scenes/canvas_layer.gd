# Add to your player HUD script or create new CanvasLayer
extends CanvasLayer

func _ready():
	# Simple crosshair
	var crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 48)
	crosshair.add_theme_color_override("font_color", Color. WHITE)
	crosshair.position = get_viewport(). get_visible_rect().size / 2.0 - Vector2(12, 24)
	add_child(crosshair)
