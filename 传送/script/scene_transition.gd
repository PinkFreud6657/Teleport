extends Node2D

# 房间切换器：检测角色离开房间边界，移动相机到下一个房间
@export var exit_direction: String = "right"  # "left", "right", "up", "down"
@export var player_spawn_offset: Vector2 = Vector2(50, 0)  # 角色在新房间的生成位置偏移（相对于相机）
@export var margin: float = 0.0  # 离开屏幕多少像素后触发（0表示一接触边缘就触发）
@export var room_width: float = 1152.0  # 房间宽度（用于计算相机移动距离）
@export var room_height: float = 648.0  # 房间高度（用于计算相机移动距离，如果为0则自动计算）
@export var smooth_transition: bool = false  # 是否使用平滑过渡（暂时保持瞬间切换以实现无缝）

# 全局切换状态（所有切换器共享，避免同时触发）
static var is_transitioning: bool = false

var player: Node2D = null
var camera: Camera2D = null

func _ready():
	# 查找玩家和相机
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().get_node_or_null("Player")
	
	camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		camera = get_tree().get_current_scene().get_node_or_null("Camera2D")
	
	# 确保相机激活
	if camera:
		camera.make_current()
		# 如果相机和玩家都存在，将相机移动到玩家位置（确保能看到游戏内容）
		if player:
			# 等待一帧，确保玩家位置已正确设置
			await get_tree().process_frame
			camera.global_position = player.global_position

func _process(_delta: float):
	if is_transitioning or not player or not camera:
		return
	
	var player_pos: Vector2 = player.global_position
	var camera_pos: Vector2 = camera.global_position
	var should_transition := false
	var new_camera_pos: Vector2 = Vector2.ZERO
	var new_player_pos: Vector2 = Vector2.ZERO
	
	# 计算屏幕边界（世界坐标）
	var viewport_size := get_viewport_rect().size
	var screen_left := camera_pos.x - viewport_size.x / (2.0 * camera.zoom.x)
	var screen_right := camera_pos.x + viewport_size.x / (2.0 * camera.zoom.x)
	var screen_top := camera_pos.y - viewport_size.y / (2.0 * camera.zoom.y)
	var screen_bottom := camera_pos.y + viewport_size.y / (2.0 * camera.zoom.y)
	
	# 检测是否接触或离开屏幕边界（无缝切换）
	match exit_direction:
		"right":
			# 向右接触或离开屏幕边缘
			if player_pos.x >= screen_right - margin:
				should_transition = true
				# 相机移动到下一个房间（向右移动一个房间宽度）
				new_camera_pos = Vector2(camera_pos.x + room_width, camera_pos.y)
				# 计算角色在新房间的位置：保持相对屏幕位置不变，实现无缝
				var relative_x := player_pos.x - screen_right  # 角色超出屏幕的距离
				var screen_left_new := new_camera_pos.x - viewport_size.x / (2.0 * camera.zoom.x)
				new_player_pos = Vector2(screen_left_new + relative_x + player_spawn_offset.x, player_pos.y)
		"left":
			# 向左接触或离开屏幕边缘
			if player_pos.x <= screen_left + margin:
				should_transition = true
				# 相机移动到下一个房间（向左移动一个房间宽度）
				new_camera_pos = Vector2(camera_pos.x - room_width, camera_pos.y)
				# 计算角色在新房间的位置：保持相对屏幕位置不变，实现无缝
				var relative_x := player_pos.x - screen_left  # 角色超出屏幕的距离（负值）
				var screen_right_new := new_camera_pos.x + viewport_size.x / (2.0 * camera.zoom.x)
				new_player_pos = Vector2(screen_right_new + relative_x - player_spawn_offset.x, player_pos.y)
		"up":
			# 向上离开屏幕
			if player_pos.y < screen_top - margin:
				should_transition = true
				# 相机移动到下一个房间（向上移动）
				var height := room_height if room_height > 0.0 else (viewport_size.y / camera.zoom.y)
				new_camera_pos = Vector2(camera_pos.x, camera_pos.y - height)
				# 角色出现在新房间下方
				new_player_pos = Vector2(player_pos.x, new_camera_pos.y + viewport_size.y / (2.0 * camera.zoom.y) - player_spawn_offset.y)
		"down":
			# 向下离开屏幕
			if player_pos.y > screen_bottom + margin:
				should_transition = true
				# 相机移动到下一个房间（向下移动）
				var height := room_height if room_height > 0.0 else (viewport_size.y / camera.zoom.y)
				new_camera_pos = Vector2(camera_pos.x, camera_pos.y + height)
				# 角色出现在新房间上方
				new_player_pos = Vector2(player_pos.x, new_camera_pos.y - viewport_size.y / (2.0 * camera.zoom.y) + player_spawn_offset.y)
	
	if should_transition:
		is_transitioning = true
		_transition_to_next_room(new_camera_pos, new_player_pos)

func _transition_to_next_room(new_camera_pos: Vector2, new_player_pos: Vector2):
	# 无缝切换：同时移动相机和角色，保持视觉连续性
	# 先调整角色位置（保持相对位置）
	player.global_position = new_player_pos
	
	# 立即移动相机到新房间位置（无缝衔接）
	camera.global_position = new_camera_pos
	
	# 短暂延迟后允许再次切换（防止连续触发，但时间更短以实现快速切换）
	await get_tree().create_timer(0.1).timeout
	is_transitioning = false
