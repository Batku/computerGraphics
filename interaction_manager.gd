extends Node

var prompt_label: Label3D = null

func _ready():
	prompt_label = Label3D.new()
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 32
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color.BLACK
	prompt_label.visible = false
	get_tree().root.add_child. call_deferred(prompt_label)

func show_prompt(text: String, position: Vector3):
	if prompt_label:
		prompt_label.text = text
		prompt_label.global_position = position + Vector3(0, 1.5, 0)
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
