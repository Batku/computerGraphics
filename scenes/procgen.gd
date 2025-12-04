extends Node3D

@export var grid_width: int = 50
@export var grid_height: int = 50
@export var cell_size: float = 3.0
@export var num_rooms: int = 20
@export var min_room_cells: int = 2
@export var max_room_cells: int = 15
@export var floor_height: float = 5.0
@export var min_stairs: int = 2
@export var max_stairs: int = 4
@export var wall_height: float = 5.0
@export var wall_thickness: float = 0.2
@export var extra_corridor_chance: float = 0.1

@export var slot_machine_scene: PackedScene
@export var roulette_table_scene: PackedScene
@export var slot_machines_per_room: int = 3
@export var roulette_tables_per_floor: int = 2
@export var player: Node3D

enum CellType {
	EMPTY,
	ROOM,
	CORRIDOR
}

func create_static_body_with_collision(mesh: Mesh, position: Vector3, rotation: Vector3 = Vector3.ZERO):
	var body = StaticBody3D.new()
	body.position = position
	body.rotation = rotation

	var collider = CollisionShape3D.new()
	var shape = mesh.create_trimesh_shape()
	collider.shape = shape

	body.add_child(collider)
	add_child(body)
	return body


class GridCell:
	var type: CellType = CellType.EMPTY
	var room_id: int = -1
	var cor_id: int = -1
	var has_stairs: bool = false
	var has_prop: bool = false
	
	func _init(t: CellType = CellType.EMPTY, rid: int = -1):
		type = t
		room_id = rid

class Corridor:
	var id: int;
	var room1: Room;
	var room2: Room;
	func _init(cid: int, r1: Room, r2: Room):
		id = cid;
		room1 = r1;
		room2 = r2;
class Room:
	var id: int
	var grid_x: int
	var grid_y: int
	var width: int
	var height: int
	var floor_level: int
	var connections: Array[int] = []
	var has_stairs: bool = false
	var stair_cells: Array = []
	var stair_direction: Vector2i = Vector2i.ZERO
	var is_start: bool = false
	var is_end: bool = false
	
	@warning_ignore("shadowed_global_identifier")
	func _init(room_id: int, gx: int, gy: int, w: int, h: int, floor: int):
		id = room_id
		grid_x = gx
		grid_y = gy
		width = w
		height = h
		floor_level = floor
	
	func get_center_cell() -> Vector2i:
		@warning_ignore("integer_division")
		return Vector2i(grid_x + width / 2, grid_y + height / 2)
	
	func get_world_center(cell_sz: float, floor_h: float) -> Vector3:
		var center = get_center_cell()
		return Vector3(
			center.x * cell_sz + cell_sz / 2.0,
			floor_level * floor_h,
			center.y * cell_sz + cell_sz / 2.0
		)
	
	func is_cell_in_room(cell: Vector2i) -> bool:
		return cell.x >= grid_x and cell.x < grid_x + width and cell.y >= grid_y and cell.y < grid_y + height

var grids: Array[Array] = []
var rooms: Array[Room] = []
var corridors: Array[Corridor] = []
var room_counter: int = 0

func _ready():
	generate_casino()

func generate_casino():
	clear_casino()
	init_grids()
	generate_rooms_on_grid(0)
	#copy_rooms_to_floor_1()
	
	#@warning_ignore("shadowed_global_identifier")
	#for floor in range(2):
	#	connect_rooms_on_floor(floor)
	connect_rooms_on_floor(0)
	#add_stairs()
	mark_start_and_end()
	visualize_casino()
	add_casino_props()
	teleport_player_to_start()
	
	print("Casino generated - Total rooms: ", rooms.size())

func init_grids():
	grids = []
	@warning_ignore("shadowed_global_identifier")
	for floor in range(2):
		var grid = []
		for y in range(grid_height):
			var row = []
			for x in range(grid_width):
				row.append(GridCell.new())
			grid.append(row)
		grids.append(grid)

@warning_ignore("shadowed_global_identifier")
func generate_rooms_on_grid(floor: int):
	var attempts = 0
	var max_attempts = num_rooms * 50
	var rooms_created = 0
	
	while rooms_created < num_rooms and attempts < max_attempts:
		attempts += 1
		
		var room_width = randi_range(min_room_cells, max_room_cells)
		var room_height = randi_range(min_room_cells, max_room_cells)
		var room_x = randi_range(0, grid_width - room_width - 1)
		var room_y = randi_range(0, grid_height - room_height - 1)
		
		if can_place_room(floor, room_x, room_y, room_width, room_height):
			place_room(floor, room_x, room_y, room_width, room_height)
			rooms_created += 1

@warning_ignore("shadowed_global_identifier")
func can_place_room(floor: int, x: int, y: int, w: int, h: int) -> bool:
	for dy in range(-1, h + 1):
		for dx in range(-1, w + 1):
			var check_x = x + dx
			var check_y = y + dy
			
			if check_x < 0 or check_x >= grid_width or check_y < 0 or check_y >= grid_height:
				continue
			
			if grids[floor][check_y][check_x].type != CellType.EMPTY:
				return false
	
	return true

@warning_ignore("shadowed_global_identifier")
func place_room(floor: int, x: int, y: int, w: int, h: int):
	var room = Room.new(room_counter, x, y, w, h, floor)
	rooms.append(room)
	
	for dy in range(h):
		for dx in range(w):
			grids[floor][y + dy][x + dx].type = CellType.ROOM
			grids[floor][y + dy][x + dx].room_id = room_counter
	
	room_counter += 1

func copy_rooms_to_floor_1():
	var floor_0_rooms = rooms.duplicate()
	
	for room in floor_0_rooms:
		if room.floor_level == 0:
			var new_room = Room.new(room_counter, room.grid_x, room.grid_y, room.width, room.height, 1)
			rooms.append(new_room)
			
			for dy in range(room.height):
				for dx in range(room.width):
					grids[1][room.grid_y + dy][room.grid_x + dx].type = CellType.ROOM
					grids[1][room.grid_y + dy][room.grid_x + dx].room_id = room_counter
			
			room_counter += 1

@warning_ignore("shadowed_global_identifier")
func connect_rooms_on_floor(floor: int):
	var floor_rooms = []
	for room in rooms:
		if room.floor_level == floor:
			floor_rooms.append(room)
	
	if floor_rooms.size() < 2:
		return
	
	var connected = [floor_rooms[0]]
	var unconnected = []
	for i in range(1, floor_rooms.size()):
		unconnected.append(floor_rooms[i])
	
	while unconnected.size() > 0:
		var min_distance = INF
		var closest_connected = null
		var closest_unconnected = null
		
		for conn_room in connected:
			for unconn_room in unconnected:
				var dist = conn_room.get_center_cell().distance_to(unconn_room.get_center_cell())
				if dist < min_distance:
					min_distance = dist
					closest_connected = conn_room
					closest_unconnected = unconn_room
		
		if closest_connected and closest_unconnected:
			create_corridor(closest_connected, closest_unconnected, floor)
			connected.append(closest_unconnected)
			unconnected.erase(closest_unconnected)
	
	for i in range(floor_rooms.size()):
		for j in range(i + 1, floor_rooms.size()):
			if not floor_rooms[i].connections.has(floor_rooms[j].id) and randf() < extra_corridor_chance:
				create_corridor(floor_rooms[i], floor_rooms[j], floor)

@warning_ignore("shadowed_global_identifier")
func create_corridor(room1: Room, room2: Room, floor: int):
	room1.connections.append(room2.id)
	room2.connections.append(room1.id)
	var cor = Corridor.new(corridors.size(), room1, room2);
	corridors.append(cor)
	var start = room1.get_center_cell()
	var end = room2.get_center_cell()
	var current = start
	
	var step_x = 1 if end.x > start.x else -1
	while current.x != end.x:
		if grids[floor][current.y][current.x].type == CellType.EMPTY:
			grids[floor][current.y][current.x].type = CellType.CORRIDOR
			grids[floor][current.y][current.x].cor_id = cor.id;
		current.x += step_x
	
	var step_y = 1 if end.y > start.y else -1
	while current.y != end.y:
		if grids[floor][current.y][current.x].type == CellType.EMPTY:
			grids[floor][current.y][current.x].type = CellType.CORRIDOR
			grids[floor][current.y][current.x].cor_id = cor.id;
		current.y += step_y

func add_stairs():
	var floor_0_rooms = []
	for room in rooms:
		if room.floor_level == 0 and room.width >= 5 and room.height >= 5:
			floor_0_rooms.append(room)
	
	if floor_0_rooms.size() == 0:
		push_warning("No rooms large enough for stairs!")
		return
	
	var num_stairs_to_place = min(randi_range(min_stairs, max_stairs), floor_0_rooms.size())
	floor_0_rooms.shuffle()
	
	for i in range(num_stairs_to_place):
		var room0 = floor_0_rooms[i]
		room0.has_stairs = true
		
		var center = room0.get_center_cell()
		var stair_dir = find_nearest_corridor_direction(room0, 0)
		room0.stair_direction = stair_dir
		
		center.x = clampi(center.x, room0.grid_x + 2, room0.grid_x + room0.width - 3)
		center.y = clampi(center.y, room0.grid_y + 2, room0.grid_y + room0.height - 3)
		
		var stair_cells = [
			Vector2i(center.x - 1, center.y - 1),
			Vector2i(center.x, center.y - 1),
			Vector2i(center.x - 1, center.y),
			Vector2i(center.x, center.y)
		]
		
		room0.stair_cells = stair_cells
		
		for cell in stair_cells:
			if cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height:
				grids[0][cell.y][cell.x].has_stairs = true
				grids[0][cell.y][cell.x].has_prop = true
				grids[1][cell.y][cell.x].has_stairs = true
				grids[1][cell.y][cell.x].has_prop = true
		
		for room1 in rooms:
			if room1.floor_level == 1 and room1.grid_x == room0.grid_x and room1.grid_y == room0.grid_y:
				room1.has_stairs = true
				room1.stair_cells = stair_cells.duplicate()
				room1.stair_direction = stair_dir
				break

@warning_ignore("shadowed_global_identifier")
func find_nearest_corridor_direction(room: Room, floor: int) -> Vector2i:
	var center = room.get_center_cell()
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	var min_dist = INF
	var best_dir = Vector2i(0, 1)
	
	for dir in directions:
		var search_pos = center
		var dist = 0
		
		for d in range(20):
			search_pos += dir
			dist += 1
			
			if search_pos.x < 0 or search_pos.x >= grid_width or search_pos.y < 0 or search_pos.y >= grid_height:
				break
			
			if grids[floor][search_pos.y][search_pos.x].type == CellType.CORRIDOR:
				if dist < min_dist:
					min_dist = dist
					best_dir = dir
				break
	
	return best_dir

func mark_start_and_end():
	var floor_0_rooms = []
#	var floor_1_rooms = []
	
	for room in rooms:
		if room.floor_level == 0:
			floor_0_rooms.append(room)
#		else:
#			floor_1_rooms.append(room)
	
	if floor_0_rooms.size() > 0:
		floor_0_rooms.shuffle()
		floor_0_rooms[0].is_start = true
		while floor_0_rooms[0].is_start == true:
			floor_0_rooms.shuffle()
		floor_0_rooms[0].is_end = true
#	if floor_1_rooms.size() > 0:
#		floor_1_rooms.shuffle()
#		floor_1_rooms[0].is_end = true

func teleport_player_to_start():
	if not player:
		push_warning("Player node not assigned!")
		return
	
	for room in rooms:
		if room.is_start:
			var pos = room.get_world_center(cell_size, floor_height)
			pos.y += 2.0
			player.global_position = pos
			return

func visualize_casino():
	@warning_ignore("shadowed_global_identifier")
	for floor in range(2):
		visualize_grid(floor)
		create_ceilings(floor)

@warning_ignore("shadowed_global_identifier")
func visualize_grid(floor: int):
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = grids[floor][y][x]
			
			if cell.type == CellType.EMPTY:
				continue
			
			if cell.has_stairs and floor == 1:
				continue
			
			var floor_mesh = BoxMesh.new()
			floor_mesh.size = Vector3(cell_size, 0.2, cell_size)
			
			var floor_instance = MeshInstance3D.new()
			floor_instance.mesh = floor_mesh
			floor_instance.position = Vector3(
				x * cell_size + cell_size / 2.0,
				floor * floor_height,
				y * cell_size + cell_size / 2.0
			)
			
			var material = StandardMaterial3D.new()
			
			if cell.type == CellType.ROOM:
				var room = get_room_by_id(cell.room_id)
				if room:
					if room.is_start:
						material.albedo_color = Color.GREEN
					elif room.is_end:
						material.albedo_color = Color.RED
					elif room.has_stairs:
						material.albedo_color = Color.ORANGE
					else:
						material.albedo_color = Color.GRAY
				else:
					material.albedo_color = Color.GRAY
			elif cell.type == CellType.CORRIDOR:
				material.albedo_color = Color(0.5, 0.5, 0.5)
			
			floor_instance.material_override = material
			add_child(floor_instance)
			create_static_body_with_collision(floor_mesh, floor_instance.position)
			create_cell_walls(floor, x, y)
	
	for room in rooms:
		if room.has_stairs and room.floor_level == 0:
			create_stairs_visual(room)

@warning_ignore("shadowed_global_identifier")
func create_ceilings(floor: int):
	var ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = Color(0.4, 0.4, 0.4)
	var ceiling_y = (floor + 1) * floor_height - 0.1
	
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = grids[floor][y][x]
			
			if cell.type == CellType.ROOM or cell.type == CellType.CORRIDOR:
				if cell.has_stairs and floor == 0:
					continue
				
				var ceiling_mesh = BoxMesh.new()
				ceiling_mesh.size = Vector3(cell_size, 0.2, cell_size)
				
				var ceiling_instance = MeshInstance3D.new()
				ceiling_instance.mesh = ceiling_mesh
				ceiling_instance.position = Vector3(
					x * cell_size + cell_size / 2.0,
					ceiling_y,
					y * cell_size + cell_size / 2.0
				)
				ceiling_instance.material_override = ceiling_material
				add_child(ceiling_instance)
				create_static_body_with_collision(ceiling_mesh, ceiling_instance.position)
@warning_ignore("shadowed_global_identifier")
func handle_corridor_neighbor(
	floor: int,
	x: int,
	y: int,
	nx: int,
	ny: int,
	wall_pos: Vector3,
	wall_size: Vector3,
	wall_material: StandardMaterial3D,
	unlock_material: StandardMaterial3D
) -> void:
	var cell = grids[floor][y][x]
	var cor = corridors[cell.cor_id]
	var corRooms: Array[int] = []
	corRooms.append(cor.room1.id)
	corRooms.append(cor.room2.id)

	if nx < 0 or ny < 0 or nx >= grid_width or ny >= grid_height:
		create_wall(wall_pos, wall_size, wall_material)
		return

	var ncell = grids[floor][ny][nx]

	#corridor
	if ncell != null and ncell.type == CellType.CORRIDOR:
		return

	#ROOM / EMPTY / null
	if ncell == null:
		create_wall(wall_pos, wall_size, wall_material)
		return

	if ncell.type == CellType.ROOM:
		create_unlockable_wall(wall_pos, wall_size, unlock_material)
		return

	if ncell.type == CellType.EMPTY:
		create_wall(wall_pos, wall_size, wall_material)
		return

	create_wall(wall_pos, wall_size, wall_material)
@warning_ignore("shadowed_global_identifier")
func create_cell_walls(floor: int, x: int, y: int):
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.3, 0.3, 0.3)
	var unlock_material = StandardMaterial3D.new()
	unlock_material.albedo_color = Color(0.776, 0.11, 0.212, 0.733)
	unlock_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	unlock_material.flags_transparent = true
	unlock_material.flags_use_alpha_scissor = false
	var is_coridor = grids[floor][y][x].type == CellType.CORRIDOR;
	
	var y_pos = floor * floor_height + wall_height / 2.0
	var world_x = x * cell_size + cell_size / 2.0
	var world_z = y * cell_size + cell_size / 2.0
	if is_coridor:
		# NORTH
		handle_corridor_neighbor(
			floor,
			x,
			y,
			x,
			y - 1,
			Vector3(world_x, y_pos, y * cell_size),
			Vector3(cell_size, wall_height, wall_thickness),
			wall_material,
			unlock_material
		)

		# SOUTH
		handle_corridor_neighbor(
			floor,
			x,
			y,
			x,
			y + 1,
			Vector3(world_x, y_pos, (y + 1) * cell_size),
			Vector3(cell_size, wall_height, wall_thickness),
			wall_material,
			unlock_material
		)

		# WEST
		handle_corridor_neighbor(
			floor,
			x,
			y,
			x - 1,
			y,
			Vector3(x * cell_size, y_pos, world_z),
			Vector3(wall_thickness, wall_height, cell_size),
			wall_material,
			unlock_material
		)

		# EAST
		handle_corridor_neighbor(
			floor,
			x,
			y,
			x + 1,
			y,
			Vector3((x + 1) * cell_size, y_pos, world_z),
			Vector3(wall_thickness, wall_height, cell_size),
			wall_material,
			unlock_material
		)
	else:
		if y == 0 or grids[floor][y - 1][x].type == CellType.EMPTY:
			create_wall(Vector3(world_x, y_pos, y * cell_size), Vector3(cell_size, wall_height, wall_thickness), wall_material)
		
		if y == grid_height - 1 or grids[floor][y + 1][x].type == CellType.EMPTY:
			create_wall(Vector3(world_x, y_pos, (y + 1) * cell_size), Vector3(cell_size, wall_height, wall_thickness), wall_material)
		
		if x == 0 or grids[floor][y][x - 1].type == CellType.EMPTY:
			create_wall(Vector3(x * cell_size, y_pos, world_z), Vector3(wall_thickness, wall_height, cell_size), wall_material)
		
		if x == grid_width - 1 or grids[floor][y][x + 1].type == CellType.EMPTY:
			create_wall(Vector3((x + 1) * cell_size, y_pos, world_z), Vector3(wall_thickness, wall_height, cell_size), wall_material)

func create_wall(pos: Vector3, size: Vector3, material: StandardMaterial3D):
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_mesh
	wall_instance.position = pos
	wall_instance.material_override = material
	add_child(wall_instance)
	# prolly works
	create_static_body_with_collision(wall_mesh, pos)

func create_unlockable_wall(pos: Vector3, size: Vector3, material: StandardMaterial3D):
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_mesh
	wall_instance.position = pos
	wall_instance.material_override = material
	add_child(wall_instance)
	# collisions disabled for now
	#create_static_body_with_collision(wall_mesh, pos)

func create_stairs_visual(room: Room):
	var stair_material = StandardMaterial3D.new()
	stair_material.albedo_color = Color.SADDLE_BROWN
	
	var stair_center_world = Vector3.ZERO
	if room.stair_cells.size() > 0:
		for cell in room.stair_cells:
			stair_center_world += Vector3(
				cell.x * cell_size + cell_size / 2.0,
				0,
				cell.y * cell_size + cell_size / 2.0
			)
		stair_center_world /= room.stair_cells.size()
	else:
		stair_center_world = room.get_world_center(cell_size, floor_height)
	
	var num_steps = 10
	var step_height = floor_height / num_steps
	var total_stair_depth = cell_size * 2.0
	var step_depth = total_stair_depth / num_steps
	var stair_width = cell_size * 1.5
	
	var rotation_y = 0.0
	if room.stair_direction == Vector2i(0, -1):
		rotation_y = 0.0
	elif room.stair_direction == Vector2i(0, 1):
		rotation_y = PI
	elif room.stair_direction == Vector2i(-1, 0):
		rotation_y = PI / 2.0
	elif room.stair_direction == Vector2i(1, 0):
		rotation_y = -PI / 2.0
	
	for i in range(num_steps):
		var step = BoxMesh.new()
		step.size = Vector3(stair_width, step_height, step_depth)
		
		var step_instance = MeshInstance3D.new()
		step_instance.mesh = step
		
		var step_y = i * step_height
		var offset = Vector3(
			0,
			step_y,
			-(total_stair_depth / 2.0) + (i * step_depth) + step_depth / 2.0
		)
		
		offset = offset.rotated(Vector3.UP, rotation_y)
		
		step_instance.position = stair_center_world + offset
		step_instance.rotation.y = rotation_y
		step_instance.material_override = stair_material
		add_child(step_instance)
		create_static_body_with_collision(step, step_instance.position)

func add_casino_props():
	add_slot_machines()
	add_roulette_tables()

func add_slot_machines():
	if not slot_machine_scene:
		return
	
	for room in rooms:
		if room.has_stairs or room.is_start or room.is_end:
			continue
		
		var machines_placed = 0
		var attempts = 0
		
		while machines_placed < slot_machines_per_room and attempts < 50:
			attempts += 1
			
			var edge = randi() % 4
			var x = 0
			var y = 0
			var rotation_y = 0.0
			
			match edge:
				0:
					x = randi_range(room.grid_x + 1, room.grid_x + room.width - 2)
					y = room.grid_y
					rotation_y = PI
				1:
					x = randi_range(room.grid_x + 1, room.grid_x + room.width - 2)
					y = room.grid_y + room.height - 1
					rotation_y = 0.0
				2:
					x = room.grid_x
					y = randi_range(room.grid_y + 1, room.grid_y + room.height - 2)
					rotation_y = PI / 2.0
				3:
					x = room.grid_x + room.width - 1
					y = randi_range(room.grid_y + 1, room.grid_y + room.height - 2)
					rotation_y = -PI / 2.0
			
			if grids[room.floor_level][y][x].has_prop:
				continue
			
			var slot_machine = slot_machine_scene.instantiate()
			add_child(slot_machine)
			
			slot_machine.global_position = Vector3(
				x * cell_size + cell_size / 2.0,
				room.floor_level * floor_height,
				y * cell_size + cell_size / 2.0
			)
			slot_machine.rotation.y = rotation_y
			
			grids[room.floor_level][y][x].has_prop = true
			machines_placed += 1

func add_roulette_tables():
	pass

func get_room_by_id(room_id: int) -> Room:
	for room in rooms:
		if room.id == room_id:
			return room
	return null

func clear_casino():
	for child in get_children():
		if child == player:
			continue
		child.queue_free()
	
	grids.clear()
	rooms.clear()
	room_counter = 0
