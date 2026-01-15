extends CharacterBody3D

@export var move_speed:  float = 5.0
@export var catch_distance: float = 1.8
@export var detection_range: float = 50.0

var target: Node3D = null
var is_chasing:  bool = false
var demand_amount: int = 0
var animation_player: AnimationPlayer = null

signal player_caught
signal chase_started(demand:  int)

func _ready():
	animation_player = find_animation_player(self)
	
	if animation_player:
		print("✅ Found AnimationPlayer")

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = find_animation_player(child)
		if result:
			return result
	return null

func set_target(player: Node3D):
	target = player
	print("👹 Target set:  ", player.name)

func _physics_process(delta):
	# Check for broke player
	if GameManager.player_money < 10:
		game_over("Better luck next time...")
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	else:
		velocity.y = 0
	
	# Check for player visibility if not chasing yet
	if not is_chasing and target: 
		check_player_visibility()
	
	# Chase logic
	if is_chasing and target: 
		chase_player_direct(delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()

func check_player_visibility():
	if not target:
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > detection_range:
		return
	
	var my_pos = global_position + Vector3.UP * 1.0
	var target_pos = target. global_position + Vector3.UP * 1.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(my_pos, target_pos)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if not result or is_player_node(result. collider):
		start_chase()

func is_player_node(node: Node) -> bool:
	if node == target: 
		return true
	if node. get_parent() == target:
		return true
	if node. is_in_group("player"):
		return true
	return false

func start_chase():
	if is_chasing:
		return
	
	is_chasing = true
	
	demand_amount = int(GameManager. player_money * 2.5)
	if demand_amount < 100:
		demand_amount = 100
	
	GameManager.current_demand = demand_amount
	GameManager.is_being_chased = true
	
	chase_started.emit(demand_amount)
	play_walk_animation()
	
	print("CHASE STARTED! Demands $", demand_amount)

func play_walk_animation():
	if not animation_player:
		return
	
	var anim_names = ["WalkingAnimation", "Walking", "Walk", "walk", "walking"]
	
	for anim_name in anim_names: 
		if animation_player.has_animation(anim_name):
			animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
			animation_player.play(anim_name)
			return

func chase_player_direct(delta):
	var direction = target.global_position - global_position
	direction.y = 0
	
	var distance = direction.length()
	
	# Caught player
	if distance <= catch_distance:
		catch_player()
		return
	
	direction = direction.normalized()
	
	# Face the player
	var look_pos = global_position + direction
	look_pos.y = global_position. y
	look_at(look_pos, Vector3.UP)
	
	# Move toward player
	velocity.x = direction.x * move_speed
	velocity. z = direction.z * move_speed

func catch_player():
	is_chasing = false
	velocity = Vector3.ZERO
	
	if animation_player:
		animation_player.stop()
	
	game_over("He caught you...")

func game_over(reason: String):
	print("GAME OVER: ", reason)
	
	# Disable processing so nothing else happens
	set_physics_process(false)
	
	# Show death message (optional)
	var death_label = Label. new()
	death_label.text = reason
	death_label.add_theme_font_size_override("font_size", 72)
	death_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label. vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.set_anchors_and_offsets_preset(Control. PRESET_FULL_RECT)
	
	var canvas = CanvasLayer.new()
	canvas.add_child(death_label)
	get_tree().root.add_child(canvas)
	
	# Wait then go to menu
	await get_tree().create_timer(2.0).timeout
	
	# Reset game state
	GameManager.player_money = 500
	GameManager.is_being_chased = false
	GameManager.current_demand = 0
	
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func stop_chase():
	is_chasing = false
	velocity = Vector3.ZERO
	GameManager.is_being_chased = false
	
	if animation_player:
		animation_player.stop()
