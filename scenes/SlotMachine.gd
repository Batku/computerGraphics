extends Node3D

@onready var screen_quad = $ScreenQuad
@onready var screen_collider = $ScreenCollider
@onready var interaction_area = $InteractionArea
@onready var screen_viewport = $ScreenViewport
@onready var slot_ui = $ScreenViewport/SlotUI

var player_in_range: bool = false
var is_active: bool = false
var player_camera: Camera3D = null

# UV ADJUSTMENT
var uv_scale_x: float = 1.0
var uv_scale_y: float = 1.0
var uv_offset_x: float = 0.0
var uv_offset_y: float = 0.0

var use_method_2: bool = false
var use_direct_click: bool = true  # Toggle this if needed

signal slot_machine_activated
signal slot_machine_deactivated

func _ready():
	print("\n🎰 SLOT MACHINE INIT")
	
	if not screen_quad or not screen_viewport or not slot_ui:
		push_error("❌ Missing nodes!")
		return
	
	if not screen_collider:
		push_error("❌ ScreenCollider not found!")
		return
	
	screen_viewport.size = Vector2i(1920, 1080)
	screen_viewport.transparent_bg = false
	screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	await get_tree().process_frame
	setup_screen_material()
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	slot_ui.slot_finished.connect(_on_slot_finished)
	slot_ui.leave_requested.connect(_on_leave_requested)
	
	print("✅ Ready")

func setup_screen_material():
	var material = StandardMaterial3D. new()
	var viewport_texture = screen_viewport.get_texture()
	
	material.albedo_texture = viewport_texture
	material. shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material. emission_texture = viewport_texture
	material. emission_energy_multiplier = 1.0
	
	screen_quad.material_override = material

func _process(_delta):
	if not is_active:
		if player_in_range and Input.is_action_just_pressed("interact"):
			activate_machine()
	else:
		var changed = false
		
		if Input.is_action_just_pressed("ui_focus_next"):  # TAB
			use_method_2 = !use_method_2
			print("\n🔄 Switched to UV Method ", 2 if use_method_2 else 1)
		
		if Input.is_action_just_pressed("ui_left"):
			uv_scale_x -= 0.05
			changed = true
		if Input.is_action_just_pressed("ui_right"):
			uv_scale_x += 0.05
			changed = true
		if Input.is_action_just_pressed("ui_up"):
			uv_offset_y += 0.05
			changed = true
		if Input.is_action_just_pressed("ui_down"):
			uv_offset_y -= 0.05
			changed = true
		if Input.is_key_pressed(KEY_I):
			uv_scale_y += 0.05
			changed = true
		if Input.is_key_pressed(KEY_K):
			uv_scale_y -= 0.05
			changed = true
		if Input. is_key_pressed(KEY_J):
			uv_offset_x -= 0.05
			changed = true
		if Input.is_key_pressed(KEY_L):
			uv_offset_x += 0.05
			changed = true
		
		if changed:
			print("\n📐 UV: Scale(%. 2f, %.2f) Offset(%.2f, %. 2f)" % [uv_scale_x, uv_scale_y, uv_offset_x, uv_offset_y])
		
		handle_mouse_on_screen()
		
		if Input.is_action_just_pressed("interact"):
			send_click_to_screen()
		
		if Input.is_action_just_pressed("ui_cancel"):
			deactivate_machine()

func handle_mouse_on_screen():
	if not player_camera:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	
	var from = player_camera.project_ray_origin(center)
	var to = from + player_camera.project_ray_normal(center) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == screen_collider:
		var uv = get_uv_from_hit(result.position)
		var viewport_pos = Vector2(uv.x * 1920.0, uv. y * 1080.0)
		
		var motion_event = InputEventMouseMotion.new()
		motion_event.position = viewport_pos
		motion_event.relative = Vector2. ZERO
		screen_viewport.push_input(motion_event)

func send_click_to_screen():
	if not player_camera:
		return
	
	print("\nCLICK!")
	
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	
	var from = player_camera.project_ray_origin(center)
	var to = from + player_camera. project_ray_normal(center) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state. intersect_ray(query)
	
	if result and result. collider == screen_collider:
		var uv = get_uv_from_hit(result.position)
		var viewport_pos = Vector2(uv. x * 1920.0, uv.y * 1080.0)
		
		print("   UV: (%.3f, %.3f) → Pos: (%.0f, %.0f)" % [uv.x, uv.y, viewport_pos.x, viewport_pos. y])
		
		if use_direct_click:
			# METHOD 1: Direct button click
			var button = slot_ui.get_button_at_position(viewport_pos)
			if button:
				print("Found button: ", button.text)
				button.emit_signal("pressed")
			else:
				print("No button at position")
		else:
			# METHOD 2: Send input events (backup)
			var press_event = InputEventMouseButton.new()
			press_event.button_index = MOUSE_BUTTON_LEFT
			press_event.pressed = true
			press_event. position = viewport_pos
			press_event.button_mask = MOUSE_BUTTON_MASK_LEFT
			
			var release_event = InputEventMouseButton.new()
			release_event.button_index = MOUSE_BUTTON_LEFT
			release_event. pressed = false
			release_event.position = viewport_pos
			release_event.button_mask = 0
			
			screen_viewport.push_input(press_event)
			screen_viewport.push_input(release_event)
			
			print("Input events sent")

func get_uv_from_hit(hit_point: Vector3) -> Vector2:
	if use_method_2:
		var local_pos = screen_quad.to_local(hit_point)
		
		var uv = Vector2(
			(local_pos.x + 1.0) * 0.5,
			1.0 - ((local_pos.y + 1.0) * 0.5)
		)
		
		uv. x = uv.x * uv_scale_x + uv_offset_x
		uv.y = uv. y * uv_scale_y + uv_offset_y
		
		uv.x = clamp(uv.x, 0.0, 1.0)
		uv.y = clamp(uv.y, 0.0, 1.0)
		
		return uv
	else:
		var local_hit = screen_quad.global_transform.affine_inverse() * hit_point
		
		var uv = Vector2(
			(local_hit.x + 0.5) * uv_scale_x + uv_offset_x,
			(0.5 - local_hit. y) * uv_scale_y + uv_offset_y
		)
		
		uv.x = clamp(uv.x, 0.0, 1.0)
		uv.y = clamp(uv.y, 0.0, 1.0)
		
		return uv

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = true
		player_camera = find_camera_recursive(body)
		if player_camera:
			print("✅ Player in range")

func find_camera_recursive(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var result = find_camera_recursive(child)
		if result:
			return result
	return null

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		player_camera = null
		if is_active:
			deactivate_machine()

func activate_machine():
	if is_active or not player_camera:
		return
	
	print("\n🎰 ACTIVATING")
	is_active = true
	
	slot_ui.initialize_game()
	slot_ui.set_interactive(true)
	
	slot_machine_activated.emit()

func deactivate_machine():
	if not is_active:
		return
	
	print("\n🚪 DEACTIVATING")
	is_active = false
	
	slot_ui.set_interactive(false)
	slot_machine_deactivated.emit()

func _on_slot_finished():
	pass

func _on_leave_requested():
	deactivate_machine()
