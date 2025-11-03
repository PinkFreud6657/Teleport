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

	# 跳跃逻辑（支持 move_up 与 ui_accept）
	if (Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_accept")) and is_on_floor():
		velocity.y = jump_force

	# 移动与碰撞
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _teleport_cd_left <= 0.0:
			var target: Vector2 = get_global_mouse_position()
			# 距离限制：不超过 teleport_max_distance
			var from_pos: Vector2 = global_position
			var delta: Vector2 = target - from_pos
			var max_d: float = max(0.0, teleport_max_distance)
			if delta.length() > max_d and max_d > 0.0:
				target = from_pos + delta.normalized() * max_d
			global_position = target
			_teleport_cd_left = teleport_cooldown

func get_teleport_cooldown_left() -> float:
	return _teleport_cd_left

func get_teleport_cooldown_total() -> float:
	return teleport_cooldown
