extends Node

# 全局场景管理器：处理场景切换和角色状态保存
var player_scene: PackedScene
var player_instance: Node2D
var player_spawn_position: Vector2 = Vector2(312, 223)

func _ready():
	# 保存玩家场景引用
	player_scene = load("res://player.tscn")
	
	# 查找当前场景中的玩家
	player_instance = get_tree().get_first_node_in_group("player")
	if not player_instance:
		# 尝试通过名称查找
		player_instance = get_tree().get_current_scene().get_node_or_null("Player")
	
	# 连接所有场景切换器的信号
	_connect_transition_areas()

func _connect_transition_areas():
	var scene = get_tree().get_current_scene()
	_connect_transition_areas_recursive(scene)

func _connect_transition_areas_recursive(node: Node):
	if node.has_signal("scene_transition_requested"):
		node.scene_transition_requested.connect(_on_scene_transition_requested)
	
	for child in node.get_children():
		_connect_transition_areas_recursive(child)

func _on_scene_transition_requested(scene_path: String, spawn_position: Vector2):
	# 保存玩家状态
	if player_instance:
		player_spawn_position = spawn_position
	
	# 切换场景
	call_deferred("_change_scene", scene_path)

func _change_scene(scene_path: String):
	# 加载新场景
	var next_scene = load(scene_path) as PackedScene
	if not next_scene:
		push_error("无法加载场景: " + scene_path)
		return
	
	# 切换场景
	get_tree().change_scene_to_packed(next_scene)
	
	# 等待场景加载完成后再放置玩家
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 在新场景中生成玩家
	_spawn_player_in_new_scene()

func _spawn_player_in_new_scene():
	var current_scene = get_tree().get_current_scene()
	
	# 如果场景中已有玩家，移除它
	var existing_player = current_scene.get_node_or_null("Player")
	if existing_player:
		existing_player.queue_free()
		await get_tree().process_frame
	
	# 实例化新玩家
	if player_scene:
		player_instance = player_scene.instantiate()
		if player_instance:
			player_instance.global_position = player_spawn_position
			current_scene.add_child(player_instance)
			
			# 重新连接场景切换器
			_connect_transition_areas()

