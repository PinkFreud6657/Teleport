extends CharacterBody2D

@export var speed: float = 200.0          # 水平移动速度
@export var jump_force: float = -400.0    # 跳跃初速度（负号向上）
@export var gravity: float = 1000.0       # 重力强度
@export var acceleration: float = 10.0    # 水平加速度平滑度
@export var friction: float = 20.0        # 减速平滑度

# 可变高度跳跃参数
@export var fall_gravity_multiplier: float = 1.8    # 下落时的重力倍率（加快落地）
@export var low_jump_gravity_multiplier: float = 2.2 # 早松跳键时的重力倍率（缩短跳高）

# 传送冷却
@export var teleport_cooldown: float = 1.0
var _teleport_cd_left: float = 0.0

# 传送最大距离限制
@export var teleport_max_distance: float = 100.0


func _physics_process(delta):
	# 冷却计时
	if _teleport_cd_left > 0.0:
		_teleport_cd_left = max(0.0, _teleport_cd_left - delta)
	# 应用重力（支持可变高度跳跃）
	if not is_on_floor():
		var g: float = gravity
		if velocity.y > 0:
			# 下落阶段加大重力，手感更紧凑
			g *= fall_gravity_multiplier
		elif velocity.y < 0 and not (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("move_up")):
			# 上升阶段若已松开跳跃键，则加大重力，缩短滞空
			g *= low_jump_gravity_multiplier
		velocity.y += g * delta
	else:
		velocity.y = max(velocity.y, 0) # 防止下坠速度残留

	# 读取输入（使用项目自定义映射）
	var input_dir = Input.get_axis("move_left", "move_right")

	# 目标水平速度
	var target_speed = input_dir * speed

	# 平滑加速与减速
	if input_dir != 0:
		velocity.x = lerp(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)

	# 跳跃逻辑（使用 W 键 move_up，但不在传送时触发）
	# 注意：需要在 move_and_slide() 之前设置速度
	if Input.is_action_just_pressed("move_up"):
		# 如果同时按了空格，不跳跃（会触发传送）
		if Input.is_action_pressed("ui_accept"):
			pass  # 跳过跳跃，让传送处理
		elif is_on_floor():
			velocity.y = jump_force

	# 移动与碰撞
	move_and_slide()
	
	# 方向传送功能：同时按下方向键和空格键
	_handle_directional_teleport()

func _handle_directional_teleport():
	# 检查是否按下空格键（ui_accept）
	if not Input.is_action_just_pressed("ui_accept"):
		return
	
	# 检查冷却时间
	if _teleport_cd_left > 0.0:
		return
	
	# 检测方向键输入
	var teleport_dir := Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		teleport_dir.x = 1.0
	elif Input.is_action_pressed("move_left"):
		teleport_dir.x = -1.0
	
	if Input.is_action_pressed("move_down"):
		teleport_dir.y = 1.0
	elif Input.is_action_pressed("move_up"):
		teleport_dir.y = -1.0
	
	# 只有当按下方向键时才传送
	if teleport_dir.length() > 0.0:
		# 归一化方向向量
		teleport_dir = teleport_dir.normalized()
		
		# 计算传送目标位置
		var from_pos: Vector2 = global_position
		var target: Vector2 = from_pos + teleport_dir * teleport_max_distance
		
		# 执行传送
		global_position = target
		_teleport_cd_left = teleport_cooldown

func get_teleport_cooldown_left() -> float:
	return _teleport_cd_left

func get_teleport_cooldown_total() -> float:
	return teleport_cooldown
