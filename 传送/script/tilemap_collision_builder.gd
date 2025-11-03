extends TileMapLayer

@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export var create_individual_bodies: bool = true

func _ready():
	# 生成基于 TileMap 的简易方块碰撞（每格一个矩形）
	if not tile_set:
		return

	# 清理旧的碰撞容器
	if has_node("Collisions"):
		get_node("Collisions").queue_free()

	var collisions_root := Node2D.new()
	collisions_root.name = "Collisions"
	add_child(collisions_root)

	var tile_size: Vector2 = Vector2(tile_set.tile_size)
	for cell: Vector2i in get_used_cells():
		# 跳过无效的格子（source_id 为 -1 表示无效）
		if get_cell_source_id(cell) == -1:
			continue

		var body := StaticBody2D.new()
		body.collision_layer = collision_layer
		body.collision_mask = collision_mask

		var shape := RectangleShape2D.new()
		shape.size = tile_size

		var cs := CollisionShape2D.new()
		cs.shape = shape

		# 将刚体放在格子中心
		body.position = map_to_local(cell) + tile_size * 0.5
		body.add_child(cs)
		collisions_root.add_child(body)
