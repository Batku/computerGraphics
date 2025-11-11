extends CharacterBody3D

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var _mouse_delta := Vector2.ZERO
var _gravity := -30.0

@onready var _camera: Camera3D = $Camera3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Hide mesh for now (too lazy to deal with camera placement and lighting if no character skin thingy
	if _mesh:
		_mesh.visible = false


func _input(event: InputEvent) -> void:
	#testing
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta = event.relative * mouse_sensitivity


func _physics_process(delta: float) -> void:
	# --- CAMERA ROTATION ---
	rotation.y -= _mouse_delta.x * delta
	
	var new_pitch := _camera.rotation.x - _mouse_delta.y * delta
	new_pitch = clamp(new_pitch, tilt_lower_limit, tilt_upper_limit)
	_camera.rotation.x = new_pitch
	_mouse_delta = Vector2.ZERO

	# --- MOVEMENT ---
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Use player's facing direction for movement
	var forward := transform.basis.z
	var right := transform.basis.x
	var move_dir := (forward * input_dir.y + right * input_dir.x).normalized()

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_dir * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_impulse

	move_and_slide()
