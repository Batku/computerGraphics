extends CenterContainer

@onready var crosshair_dot = $Dot
@onready var crosshair_prompt = $Prompt

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	show_normal()

func show_normal():
	if crosshair_dot:
		crosshair_dot. visible = true
	if crosshair_prompt:
		crosshair_prompt.visible = false

func show_interact_prompt(text: String = "[E] Interact"):
	if crosshair_prompt:
		crosshair_prompt.text = text
		crosshair_prompt.visible = true
