extends Camera2D

# 相机平滑跟随速度（正常移动时）
const FOLLOW_SPEED = 8.0
# 传送时的平滑速度（更快，但不会瞬间跳转）
const TELEPORT_FOLLOW_SPEED = 10.0

var last_parent_position: Vector2
var camera_offset: Vector2

func _ready() -> void:
	# 让相机独立于父节点的变换
	top_level = true
	var parent = get_parent()
	if parent:
		last_parent_position = parent.global_position
		camera_offset = position
		global_position = last_parent_position + camera_offset

func _process(delta: float) -> void:
	var parent = get_parent()
	if not parent:
		return
	
	var current_parent_pos = parent.global_position
	var distance = current_parent_pos.distance_to(last_parent_position)
	
	# 如果距离超过一定值（比如80像素），认为是传送
	var is_teleporting = distance > 80.0
	var follow_speed = TELEPORT_FOLLOW_SPEED if is_teleporting else FOLLOW_SPEED
	
	# 计算目标位置（父节点位置 + 相对偏移）
	var target_world_pos = current_parent_pos + camera_offset
	
	# 使用插值平滑移动相机
	global_position = global_position.lerp(target_world_pos, delta * follow_speed)
	
	# 更新上次位置
	last_parent_position = current_parent_pos
